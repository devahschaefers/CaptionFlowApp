import 'dart:isolate';

void initBackgroundTask() async {
  final ReceivePort receivePort = ReceivePort();
  await Isolate.spawn(_backgroundTask, receivePort.sendPort);

  // Wait for the SendPort from the background Isolate
  final SendPort sendPort = await receivePort.first;

  // You can use this sendPort to communicate between the two isolates
}

void _backgroundTask(SendPort sendPort) {
  final ReceivePort receivePort = ReceivePort();

  // Notify any other isolates what port this isolate listens to.
  sendPort.send(receivePort.sendPort);

  receivePort.listen((dynamic message) {
    // Handle the message or do work here
  });

  // Do the heavy work here, without affecting the UI
  // Infinite loop
  while (true) {
      Future.delayed(Duration(seconds: 1)); // Add a delay
  }
}

