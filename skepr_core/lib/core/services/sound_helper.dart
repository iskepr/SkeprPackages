import "package:audioplayers/audioplayers.dart";

abstract final class SoundHelper {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isInitialized = false;

  static Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    try {
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
      _isInitialized = true;
    } catch (_) {}
  }

  static Future<void> playAsset(String path, {double volume = 1}) async {
    try {
      await _ensureInitialized();

      await _player.setVolume(volume);

      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (_) {}
  }
}
