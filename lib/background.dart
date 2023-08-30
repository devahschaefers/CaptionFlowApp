import 'dart:isolate';
import 'deepgram_service.dart';

void initBackgroundTask() async {
  final ReceivePort receivePort = ReceivePort();
  await Isolate.spawn(_backgroundTask, receivePort.sendPort);

  // Wait for the SendPort from the background Isolate
  final SendPort sendPort = await receivePort.first;

  // You can use this sendPort to communicate between the two isolates
}

void _backgroundTask(SendPort sendPort) {
  final ReceivePort receivePort = ReceivePort();

  // Define a function that will be called every time a new transcription is available
  void handleTranscription(String transcript) {
    print("New transcription: $transcript");
    // You can handle the transcription here directly, like storing it, etc.
  }

  final deepgramService = DeepgramService(
    updateTextCallback: handleTranscription,  // Pass the function as the callback
    serverUrl: 'wss://api.deepgram.com/v1/listen',
    apiKey: '042aec19602afb2dc4dd6f65a28bc38bcd97ab58',
  );

  // Notify any other isolates what port this isolate listens to.
  sendPort.send(receivePort.sendPort);

  // receivePort.listen((dynamic message) {
  //   if (message == 'start') {
  //     deepgramService.startRecording();
  //   } else if (message == 'stop') {
  //     deepgramService.stopRecording();
  //   }
  // });
  deepgramService.startRecording();
}
