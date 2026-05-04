import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playStart() async {
    await _player.stop();
    await _player.play(AssetSource('audio/lets-a-go.mp3'));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> playSuccess() async {
    await _player.stop();
    await _player.play(AssetSource('audio/all-coming-together.mp3'));
    await HapticFeedback.lightImpact();
  }

  static Future<void> playFailure() async {
    await _player.stop();
    await _player.play(AssetSource('audio/oh-no.mp3'));
    await HapticFeedback.heavyImpact();
  }
}
