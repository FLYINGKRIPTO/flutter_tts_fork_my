import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef void ErrorHandler(dynamic message);
typedef FlutterTTSProgressHandler = void Function(
  String , int, int, String);

// Provides Platform specific TTS services (Android: TextToSpeech, IOS: AVSpeechSynthesizer)
class FlutterTts {
  static const MethodChannel _channel = const MethodChannel('flutter_tts');

  VoidCallback initHandler;
  VoidCallback startHandler;
  VoidCallback completionHandler;
  ErrorHandler errorHandler;
  FlutterTTSProgressHandler progressHandler;

  FlutterTts() {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  static int QUEUE_ADD = 1;
  static int QUEUE_FLUSH = 0;

  /// [Future] which invokes the platform specific method for speaking
  Future<dynamic> speak(String text, {QUEUE queue = QUEUE.QUEUE_FLUSH}) =>
      _channel.invokeMapMethod('speak', {"text": text, "queue": queue.index});

  Future<dynamic> playSilence(double duration,
      {QUEUE queue = QUEUE.QUEUE_ADD}) =>
      _channel.invokeMapMethod(
          'playSilence', {"duration": duration, "queue": queue.index});

  /// [Future] which invokes the platform specific method for setLanguage
  Future<dynamic> setLanguage(String language) =>
      _channel.invokeMethod('setLanguage', language);

  Future<dynamic> setOnUtteranceProgressListener() =>
      _channel.invokeMapMethod('setOnUtteranceProgressListener');

  /// [Future] which invokes the platform specific method for setSpeechRate
  /// Allowed values are in the range from 0.0 (silent) to 1.0 (loudest)
  Future<dynamic> setSpeechRate(double rate) =>
      _channel.invokeMethod('setSpeechRate', rate);

  /// [Future] which invokes the platform specific method for setVolume
  /// Allowed values are in the range from 0.0 (silent) to 1.0 (loudest)
  Future<dynamic> setVolume(double volume) =>
      _channel.invokeMethod('setVolume', volume);

  /// [Future] which invokes the platform specific method for setPitch
  /// 1.0 is default and ranges from .5 to 2.0
  Future<dynamic> setPitch(double pitch) =>
      _channel.invokeMethod('setPitch', pitch);

  /// [Future] which invokes the platform specific method for setVoice
  /// ***Android supported only***
  Future<dynamic> setVoice(String voice) =>
      _channel.invokeMethod('setVoice', voice);

  /// [Future] which invokes the platform specific method for stop
  Future<dynamic> stop() => _channel.invokeMethod('stop');

  /// [Future] which invokes the platform specific method for getLanguages
  /// Android issues with API 21 & 22
  /// Returns a list of available languages
  Future<dynamic> get getLanguages async {
    final languages = await _channel.invokeMethod('getLanguages');
    return languages;
  }

  /// [Future] which invokes the platform specific method for getVoices
  /// ***Android supported only ***
  /// Returns a `List` of voice names
  Future<dynamic> get getVoices async {
    final voices = await _channel.invokeMethod('getVoices');
    return voices;
  }

  /// [Future] which invokes the platform specific method for isLanguageAvailable
  /// Returns `true` or `false`
  Future<dynamic> isLanguageAvailable(String language) =>
      _channel.invokeMethod(
          'isLanguageAvailable', <String, Object>{'language': language});
  
  /// [Future] which invokes the platform specific method for setSilence
  /// 0 means start the utterance immediately. If the value is greater than zero a silence period in milliseconds is set according to the parameter
  Future<dynamic> setSilence(int timems) =>
      _channel.invokeMethod('setSilence', timems ?? 0);

  void setStartHandler(VoidCallback callback) {
    startHandler = callback;
  }

  void setCompletionHandler(VoidCallback callback) {
    completionHandler = callback;
  }
  void setProgressHandler(FlutterTTSProgressHandler callback) {
    progressHandler = callback;
  }

  void setErrorHandler(ErrorHandler handler) {
    errorHandler = handler;
  }

  void ttsInitHandler(VoidCallback handler) {
    initHandler = handler;
  }

  /// Platform listeners
  Future<void> platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case "tts.init":
        if (initHandler != null) {
          initHandler();
        }
        break;
      case "speak.onStart":
        if (startHandler != null) {
          startHandler();
        }
        break;
      case "speak.onComplete":
        if (completionHandler != null) {
          completionHandler();
        }
        break;
      case 'speak.onProgress':
        if (progressHandler != null) {
          final Map<dynamic, dynamic> args = call.arguments as Map;
          progressHandler(
            args['string'].toString(),
            int.parse(args['start'].toString()),
            int.parse(args['end'].toString()),
            args['word'].toString(),
          );
        }
        break;
      case "speak.onError":
        if (errorHandler != null) {
          errorHandler(call.arguments);
        }
        break;

      default:
        print('Unknowm method ${call.method}');
    }
  }
}

enum QUEUE {
  QUEUE_ADD,
  QUEUE_FLUSH,
  QUEUE_DESTROY,
}
