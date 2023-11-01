import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


BluetoothDevice? _captionFlowGlassesDevice;


void scanAndPrintDevices() async {
  // Setup Listener for scan results
  // device not found? see "Common Problems" in the README
  FlutterBluePlus.scanResults.listen((results) {
    for (ScanResult r in results) {
      print('${r.device.localName} found! rssi: ${r.rssi}');
    }
  });

  // Start scanning
  FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

}

bool isConnectionAttemptInProgress = false;

void scanAndConnect() async {
  StreamSubscription? scanSubscription;

  // Make sure we're not already scanning
  if (FlutterBluePlus.isScanningNow){
    await FlutterBluePlus.stopScan();
  }

  // Setup Listener for scan results
  scanSubscription = FlutterBluePlus.scanResults.listen((results) {
    for (ScanResult r in results) {
      if (r.device.localName == "CaptionFlow Glasses" && !isConnectionAttemptInProgress) {  
        isConnectionAttemptInProgress = true; // Set the flag
        print("Connecting to ${r.device.localName}");

        // Attempt to connect
        r.device.connect().then((_) async {
          print("Connected to ${r.device.localName}");
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
  List<BluetoothDevice> connectedDevices = await FlutterBluePlus.connectedSystemDevices;

  for (BluetoothDevice device in connectedDevices) {
    if (device.localName == "CaptionFlow Glasses") {
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
  const String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  const String characteristicUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";


  if (_captionFlowGlassesDevice == null) {
    print("No device connected");
    return;
  }

  // Get the services
  List<BluetoothService> services = await _captionFlowGlassesDevice!.discoverServices(); 

  // Find the service we want
  BluetoothService? service;
  for (BluetoothService s in services) {
    if (s.uuid.toString() == serviceUuid) {
      service = s;
      break;
    }
  }

  if (service == null) {
    print("service not found");
    return;
  }

  // Find the characteristic we want
  BluetoothCharacteristic? characteristic;
  for (BluetoothCharacteristic c in service.characteristics) {
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
