import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

BluetoothDevice? _captionFlowGlassesDevice;

void scanAndPrintDevices() async {
  // Setup Listener for scan results
  // device not found? see "Common Problems" in the README
  FlutterBluePlus.scanResults.listen((results) {
    for (ScanResult r in results) {
      print('${r.device.platformName} found! rssi: ${r.rssi}');
    }
  });

  // Start scanning
  FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
}

bool isConnectionAttemptInProgress = false;

void scanAndConnect() async {
  StreamSubscription? scanSubscription;

  // Make sure we're not already scanning
  if (FlutterBluePlus.isScanningNow) {
    await FlutterBluePlus.stopScan();
  }

  // Setup Listener for scan results
  scanSubscription = FlutterBluePlus.scanResults.listen((results) {
    for (ScanResult r in results) {
      if (r.device.platformName == "CaptionFlow Glasses" &&
          !isConnectionAttemptInProgress) {
        isConnectionAttemptInProgress = true; // Set the flag
        print("Connecting to ${r.device.platformName}");

        // Attempt to connect
        r.device.connect().then((_) async {
          print("Connected to ${r.device.platformName}");
          // Stop scanning
          await FlutterBluePlus.stopScan();

          // Unsubscribe from the scanResults stream
          if (scanSubscription != null) {
            await scanSubscription.cancel();
          }
          _captionFlowGlassesDevice = r.device;
        }).catchError((error) {
          print("An error occurred while connecting: $error");
        });

        // Break the loop as we've started a connection attempt
        break;
      }
    }
  });

  // Start scanning
  FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
}

Future<BluetoothDevice?> findConnectedCaptionFlowGlasses() async {
  List<BluetoothDevice> connectedDevices = await FlutterBluePlus.systemDevices;

  for (BluetoothDevice device in connectedDevices) {
    if (device.platformName == "CaptionFlow Glasses") {
      _captionFlowGlassesDevice = device;
      return device;
    }
  }

  return null;
}

bool isConnected() {
  return _captionFlowGlassesDevice != null;
}

BluetoothCharacteristic? _characteristic;

void writeToDevice(String text) async {
  if (_characteristic != null) {
    await _characteristic!.write(text.codeUnits);
    return;
  }
  const String serviceUuid = "84f347dc-4b00-11ee-be56-0242ac120002";
  const String characteristicUuid = "84f34aac-4b00-11ee-be56-0242ac120002";

  if (_captionFlowGlassesDevice == null) {
    print("No device connected");
    return;
  }

  // Get the services
  List<BluetoothService> services =
      await _captionFlowGlassesDevice!.discoverServices();

  // Find the service we want
  BluetoothService? service;
  print("services:");
  for (BluetoothService s in services) {
    if (s.uuid.toString() == serviceUuid) {
      service = s;
      break;
    }
  }
  print("\n");

  if (service == null) {
    print("service not found");
    return;
  }

  // Find the characteristic we want
  BluetoothCharacteristic? characteristic;
  for (BluetoothCharacteristic c in service.characteristics) {
    print(c.uuid.toString());
    if (c.uuid.toString() == characteristicUuid) {
      characteristic = c;
      _characteristic = c;
      break;
    }
  }

  if (characteristic == null) {
    print("characteristic not found");
    return;
  }

  // Write to the characteristic
  await characteristic.write(text.codeUnits);
}
