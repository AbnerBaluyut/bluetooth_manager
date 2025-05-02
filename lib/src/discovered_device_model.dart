import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'connectable_enum.dart';

class DiscoveredDeviceModel {
  final String id;
  final String name;
  final int rssi;
  final ConnectableEnum connectable;

  DiscoveredDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    required this.connectable
  });
}

extension DiscoveredDeviceX on DiscoveredDevice {

  DiscoveredDeviceModel toDiscoveredDeviceModel() => DiscoveredDeviceModel(
    id: id,
    name: name,
    rssi: rssi,
    connectable: connectable.toConnectable()
  );
}