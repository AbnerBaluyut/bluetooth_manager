# bluetooth_manager

A lightweight Flutter package to scan and connect to Bluetooth Low Energy (BLE) devices — such as Arduino — with built-in permission handling for Android (including Android 12+).

---

## ✨ Features

- 🔍 Scan for BLE devices nearby  
- 🔗 Connect to a device by its ID  
- 🔧 Discover GATT services and characteristics  
- 📤 Send custom commands (e.g. `LED_ON`, `LED_OFF`)  
- 📥 Receive notifications from the BLE device
- ✅ Request and handle runtime permissions (Android 12+)

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  bluetooth_manager:
    git:
      url: https://github.com/AbnerBaluyut/bluetooth_manager.git
```

## 🔐 Required Permissions

Android:
```xml
<uses-permission android:name="android.permission.INTERNET" />

<!-- Legacy Bluetooth permissions for Android 11 and below -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<!-- Android 12+ (API 31+) permissions -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Required for BLE scanning (only needed on Android 10/11) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
```

iOS:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to nearby devices.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to scan for Bluetooth devices.</string>
```

## 🧑‍💻 Code Highlights

### 🟦 Scan for BLE Devices

```dart
bluetooth.startScan(
  timeout: Duration(seconds: 10),
  onStopScan: () => // handle your function here,
  onError: (err) => log("Start Scan Error: $err"),
);
```

### 🟪 Listen for Scan Results and Filter Available Devices:

```dart
bluetooth.scanResults.listen((devices) {
  // handle the function here
},
cancelOnError: true,
onError: (err) {
  log("Scan Results Error: $err");
});
```

### 🟩 Connect and Listen to Status

```dart
bluetooth.connectToDevice(
  model.id,
  timeout: 20,
  onMessage: (message) {
    // Handle your statuses
  }
);
```

### 🟧 Send LED ON/OFF Commands

```dart
await bluetooth.sendCommand(!_isEnableLED ? "LED_ON" : "LED_OFF");
```