import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';

bool _isScanning = false;

Future<List<BluetoothDevice>> scanAndReturnDevices() async {
  if (_isScanning) {
    print("Already scanning.");
    return [];
  }
  _isScanning = true;
  final flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> foundDevices = [];

  Completer<List<BluetoothDevice>> completer = Completer();

  // Start scanning
  flutterBlue.startScan(timeout: Duration(seconds: 4));

  // Listen to scan results
  final subscription = flutterBlue.scanResults.listen((results) {
    // Do something with scan results
    for (ScanResult r in results) {
      if (r.device.name.isNotEmpty) {
        foundDevices.add(r.device);
      }
    }
  });

  // Stop scanning and complete the completer when done
  Future.delayed(Duration(seconds: 4)).then((_) {
    subscription.cancel();
    flutterBlue.stopScan();
    _isScanning = false;
    completer.complete(foundDevices);
  });

  return completer.future;
}

Future<void> scanAndPrintDevices() async {
  List<BluetoothDevice> devices = await scanAndReturnDevices();
  print("Scanning complete.");

  if (devices.isEmpty) {
    print("No devices found.");
  } else {
    for (BluetoothDevice device in devices) {
      print('${device.name} found!');
    }
  }
}

void scanAndConnect() async {
  List<BluetoothDevice> devices = await scanAndReturnDevices();
  print("Scanning complete.");

  if (devices.isEmpty) {
    print("No devices found.");
  } else {
    for (BluetoothDevice device in devices) {
      print('${device.name} found!');
      if (device.name == 'CaptionFlow Glass') {
        print('Connecting to ${device.name}...');
        await device.connect();
        print('Connected to ${device.name}!');
      }
    }
  }
}
