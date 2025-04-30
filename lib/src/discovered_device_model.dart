import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DiscoveredDeviceModel {
  final String id;
  final String name;
  final int rssi;

  DiscoveredDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
  });
}

extension DiscoveredDeviceX on DiscoveredDevice {

  DiscoveredDeviceModel toDiscoveredDeviceModel() => DiscoveredDeviceModel(
    id: id,
    name: name,
    rssi: rssi,
  );
}