import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

enum ConnectableEnum { unknown, unavailable, available }

extension ConnectableX on Connectable {

  ConnectableEnum toConnectable() {
    switch (this) {
      case Connectable.available:
        return ConnectableEnum.available;
      case Connectable.unavailable:
        return ConnectableEnum.unavailable;
      case Connectable.unknown:
        return ConnectableEnum.unknown;
    }
  }
}