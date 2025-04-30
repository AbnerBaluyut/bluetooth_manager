import 'dart:io';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<bool> requestBlePermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];

      final statuses = await permissions.request();
      return statuses.values.every((status) => status.isGranted);
    }

    // iOS permissions are granted via Info.plist only
    return true;
  }

  static Future<bool> isBluetoothReady(FlutterReactiveBle ble) async {
    final status = ble.status;
    return status == BleStatus.ready;
  }
}