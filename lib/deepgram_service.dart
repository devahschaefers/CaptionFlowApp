import 'package:sound_stream/sound_stream.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'dart:async';

class DeepgramService {
  final RecorderStream _recorder = RecorderStream();
  late StreamSubscription _recorderStatus;
  late StreamSubscription _audioStream;
  late IOWebSocketChannel channel;
  final Function(String) updateTextCallback;
  final String serverUrl;
  final String apiKey;

  DeepgramService({
    required this.updateTextCallback,
    required this.serverUrl,
    required this.apiKey,
  });

  Future<void> _initStream() async {
    channel = IOWebSocketChannel.connect(Uri.parse(serverUrl),
        headers: {'Authorization': 'Token $apiKey'});

    channel.stream.listen((event) async {
      final parsedJson = jsonDecode(event);
      updateTextCallback(parsedJson['channel']['alternatives'][0]['transcript']);
    });

    _audioStream = _recorder.audioStream.listen((data) {
      channel.sink.add(data);
    });

    _recorderStatus = _recorder.status.listen((status) {
      // You may want to do something with the status or remove it
    });

    await Future.wait([
      _recorder.initialize(),
    ]);
  }

  Future<void> startRecording() async {
    await _initStream();
    await _recorder.start();
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
    _recorderStatus.cancel();
    _audioStream.cancel();
    channel.sink.close();
  }
}


