import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothHandler {

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late QualifiedCharacteristic _rxChar;
  late DiscoveredDevice _connectedDevice;

  final _scanStreamController = StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get scanResults => _scanStreamController.stream;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _rxSubscription;

  final List<DiscoveredDevice> _foundDevices = [];

  /// Starts scanning for Bluetooth devices.
  void startScan({Duration timeout = const Duration(seconds: 5), VoidCallback? onStopScan}) {   

    try {
      log("Scanning");
      _foundDevices.clear();
      _scanSubscription?.cancel();
      _scanSubscription = _ble.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
        if (_foundDevices.firstOrNull?.id == device.id) {
          _foundDevices.add(device);
          _scanStreamController.add(_foundDevices);
        }
      }, 
      cancelOnError: true, 
      onError: (err) {
        log("ERROR: $err");
        stopScan();
      });

      Future.delayed(timeout, () {
        onStopScan?.call();
        stopScan();
      });
    } catch (e) {
      log("BLE scan error: $e");
    }
  }

  bool isBluetoothReady() => _ble.status == BleStatus.ready;

  void stopScan() {
    log("Stoppped scan");
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  /// Connects to a Bluetooth device by its id.
  Future<void> connectToDevice(String deviceId, {void Function(String message)? onMessage}) async {
    _connection?.cancel();
    _connection = _ble.connectToDevice(id: deviceId).listen((update) async {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connectedDevice = _foundDevices.firstWhere((d) => d.id == deviceId);
        await _discoverServicesAndSetup(_connectedDevice.id, onMessage: onMessage);
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        onMessage?.call('Disconnected');
      }
    }, onError: (e) {
      onMessage?.call("Connection error: $e");
    });
  }

  /// Discovers services and characteristics for the connected device.
  Future<void> _discoverServicesAndSetup(String deviceId, {void Function(String message)? onMessage}) async {
    final services = await _ble.getDiscoveredServices(deviceId);

    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.isWritableWithResponse || char.isWritableWithoutResponse) {
          _rxChar = QualifiedCharacteristic(
            serviceId: service.id,
            characteristicId: char.id,
            deviceId: deviceId,
          );
        }

        if (char.isNotifiable) {
          final notifyChar = QualifiedCharacteristic(
            serviceId: service.id,
            characteristicId: char.id,
            deviceId: deviceId,
          );

          _rxSubscription?.cancel();
          _rxSubscription = _ble.subscribeToCharacteristic(notifyChar).listen((data) {
            final received = utf8.decode(data);
            onMessage?.call("Received: $received");
          });
        }
      }
    }

    onMessage?.call("Connected and services discovered.");
  }

  // Send a command to the Arduino
  Future<void> sendCommand(String message) async {
    if (_rxChar.deviceId.isEmpty) return;
    final data = utf8.encode(message);
    await _ble.writeCharacteristicWithResponse(_rxChar, value: data);
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connection?.cancel();
    _rxSubscription?.cancel();
    _scanStreamController.close();
  }
}
