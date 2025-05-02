# bluetooth_manager

A lightweight Flutter package to scan and connect to Bluetooth Low Energy (BLE) devices — such as Arduino — with built-in permission handling for Android (including Android 12+).

---

## ✨ Features

- 🔍 Scan for BLE devices nearby
- 🔗 Connect and disconnect from devices
- ✅ Request and handle runtime permissions (Android 12+)

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  bluetooth_handler:
    git:
      url: https://github.com/AbnerBaluyut/bluetooth.git
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
