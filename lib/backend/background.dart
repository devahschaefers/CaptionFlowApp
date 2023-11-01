import 'deepgram_service.dart';
import 'bluetooth.dart';



void initDeepgram() async {
  // Define a function that will be called every time a new transcription is available
  void handleTranscription(String transcript) {
    if (isConnected()) {
      writeToDevice(transcript);
      print("sent to glasses: $transcript");
    } else {
      print("No connection New transcription: $transcript");
    }
  }

  final deepgramService = DeepgramService(
    updateTextCallback: handleTranscription,  // Pass the function as the callback
    serverUrl: buildDeepgramUrl(),
    apiKey: '042aec19602afb2dc4dd6f65a28bc38bcd97ab58',
  );

  await deepgramService.startRecording();
  // deepgramService.stopRecording();  // When you want to stop
}


String buildDeepgramUrl() {
  final baseUrl = 'wss://api.deepgram.com/v1/listen';
  final queryParams = {
    'model': 'general',
    'version': 'latest',
    'language': 'en-US',
    'encoding': 'linear16',
    'diarize': 'true',
    'interim_results': 'true',
    'channels': '1',
    'sample_rate': '16000',
  };
  
  final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
  return uri.toString();
}
