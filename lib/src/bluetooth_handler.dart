import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../bluetooth_manager.dart';

class BluetoothHandler {

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late QualifiedCharacteristic _rxChar;

  final _scanStreamController = StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get scanResults => _scanStreamController.stream;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _rxSubscription;
  Timer? _scanTimer;

  final List<DiscoveredDevice> _foundDevices = [];

  // Quick Scan for a specific device.
  Future<DiscoveredDevice?> quickScanForDevice({
    required bool Function(DiscoveredDevice device) matchDevice,
    Duration timeout = const Duration(seconds: 5),
    void Function(String message)? onError,
  }) async {
    final completer = Completer<DiscoveredDevice?>();
    log("Quick scan started");
    try {
      _scanSubscription?.cancel();
      _scanSubscription = _ble.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
        if (matchDevice(device)) {
          stopScan();
          if (!completer.isCompleted) completer.complete(device);
        }
      }, cancelOnError: true, onError: (err) {
        stopScan();
        if (!completer.isCompleted) completer.complete(null);
        onError?.call("Scan error: $err");
      });

      _scanTimer = Timer(timeout, () {
        stopScan();
        if (!completer.isCompleted) completer.complete(null);
      });

    } catch (e) {
      stopScan();
      if (!completer.isCompleted) completer.complete(null);
      onError?.call("Exception during scan: $e");
    }

    return completer.future;
  }

  /// Starts scanning for Bluetooth devices.
  void startScan({Duration timeout = const Duration(seconds: 5), VoidCallback? onStopScan, void Function(String message)? onError}) {   

    try {
      log("Scanning");
      _foundDevices.clear();
      _scanSubscription?.cancel();
      _scanSubscription = _ble.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
        if (!_foundDevices.any((d) => d.id == device.id)) {
          _foundDevices.add(device);
          _scanStreamController.add(_foundDevices);
        }
      }, 
      cancelOnError: true, 
      onError: (err) {
        log("scanForDevices Err: $err");
        onError?.call(err.toString());
        stopScan();
      });

      _scanTimer = Timer(timeout, () {
        onStopScan?.call();
        stopScan();
      });

    } catch (e) {
      log("BLE scan error: $e");
      onError?.call(e.toString());
      stopScan();
    }
  }

  bool isBluetoothReady() => _ble.status == BleStatus.ready;

  void stopScan() {
    log("Stoppped scan");
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  /// Connects to a Bluetooth device by its id.
  Future<void> connectToDevice(DiscoveredDeviceModel device, {void Function(String message)? onMessage, int timeout = 5}) async {

     final completer = Completer<void>();
     
    _connection?.cancel();
    _connection = _ble.connectToDevice(id: device.id, connectionTimeout: Duration(seconds: timeout)).listen((update) async {
      if (update.connectionState == DeviceConnectionState.connected) {
        await _discoverServicesAndSetup(device.id, onMessage: onMessage);
        onMessage?.call("Connected Device: ${device.name}");
        if (!completer.isCompleted) completer.complete();
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        if (!completer.isCompleted) completer.complete();
        onMessage?.call('Disconnected');
      } else if (update.connectionState == DeviceConnectionState.disconnecting) {
        onMessage?.call('Disconnecting');
      } else if (update.connectionState == DeviceConnectionState.connecting){
        onMessage?.call('Connecting');
      }
    }, 
    cancelOnError: true,
    onError: (e) {
      onMessage?.call("Error: ${e.toString()}");
    });

    await completer.future.timeout(
      Duration(seconds: timeout),
      onTimeout: () {
        _connection?.cancel();
        _connection = null;
        onMessage?.call('Disconnected');
      },
    );
  }

  /// Discovers services and characteristics for the connected device.
  Future<void> _discoverServicesAndSetup(String deviceId, {void Function(String message)? onMessage}) async {
    try {
      
      final services = await _ble.getDiscoveredServices(deviceId);

      bool writableSet = false;
      bool notifiableSet = false;

      for (var service in services) {
        for (var char in service.characteristics) {
           log("Service: ${service.id} | Characteristic: ${char.id} "
          "| Writable: ${char.isWritableWithResponse || char.isWritableWithoutResponse} "
          "| Notifiable: ${char.isNotifiable}");

          // Set writable characteristic (first one found)
          if (!writableSet && (char.isWritableWithResponse || char.isWritableWithoutResponse)) {
            _rxChar = QualifiedCharacteristic(
              serviceId: service.id,
              characteristicId: char.id,
              deviceId: deviceId,
            );
            writableSet = true;
          }

           // Set notifiable characteristic (first one found)
          if (!notifiableSet && char.isNotifiable) {
            final notifyChar = QualifiedCharacteristic(
              serviceId: service.id,
              characteristicId: char.id,
              deviceId: deviceId,
            );

            _rxSubscription?.cancel();
            _rxSubscription = _ble.subscribeToCharacteristic(notifyChar).listen((data) {
              _handleReceivedCommand(data, onMessage);
            });
            notifiableSet = true;
          }

          if (writableSet && notifiableSet) break;
        }

        if (writableSet && notifiableSet) break;
      }

      // if (writableSet && notifiableSet) {
      //   onMessage?.call("Connected and services discovered.");
      // } else {
      //   onMessage?.call("No usable characteristics found.");
      // }

    } catch (e) {
      onMessage?.call("Error: ${e.toString()}");
    }
  }

  /// Handles the received data from the connected Bluetooth device.
  void _handleReceivedCommand(List<int> data, void Function(String message)? onMessage) {
    final receivedMessage = utf8.decode(data);
    log("Received command: $receivedMessage");
    onMessage?.call(receivedMessage);

    // ! You can add custom logic here to process the received command.
    // ! For example, trigger specific actions based on the received message.
    // if (receivedMessage == "turnOn") {
    //   log("Device should turn on now");
    //   ! Handle the command, such as turning on the device
    // } else if (receivedMessage == "turnOff") {
    //   log("Device should turn off now");
    //   ! Handle the command, such as turning off the device
    // }
    // ! Add more conditions as needed
  }

  // Send a command to the Arduino
  Future<void> sendCommand(String message, {bool withResponse = true}) async {
    if (_rxChar.deviceId.isEmpty) return;
    final data = utf8.encode(message);

    if (withResponse) {
      return await _ble.writeCharacteristicWithResponse(_rxChar, value: data);
    } else {
      return await _ble.writeCharacteristicWithoutResponse(_rxChar, value: data);
    }
  }

  void disconnectDevice() {
    _scanTimer?.cancel();
    _scanTimer = null;

    _scanSubscription?.cancel();
    _scanSubscription = null;

    _connection?.cancel();
    _connection = null;

    _rxSubscription?.cancel();
    _rxSubscription = null;
  }

  void dispose() {
    disconnectDevice();
    _scanStreamController.close();
  }
}
