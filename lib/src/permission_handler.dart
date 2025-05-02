import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {

  static Future<bool> requestPermissions() async {

    if (!Platform.isAndroid) return true;
    
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    List<Permission> permissions;

    if (sdkInt >= 31) {
      permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ];
    } else {
      permissions = [
        Permission.bluetooth,
        Permission.location,
      ];
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // Check for specific denied or permanently denied permissions
    bool bluetoothDenied = statuses[Permission.bluetooth]?.isDenied ?? false;
    bool bluetoothPermanentlyDenied = statuses[Permission.bluetooth]?.isPermanentlyDenied ?? false;
    bool locationDenied = statuses[Permission.location]?.isDenied ?? false;
    bool locationPermanentlyDenied = statuses[Permission.location]?.isPermanentlyDenied ?? false;

    if (bluetoothDenied || bluetoothPermanentlyDenied) {
      throw("bluetooth_permission_denied");
    } else if (locationDenied || locationPermanentlyDenied) {
      throw("location_permission_denied");
    }

    return !(bluetoothDenied || locationDenied);
  }
}