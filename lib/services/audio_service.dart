import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_task/services/storage_service.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  late AudioPlayer _backgroundMusicPlayer;

  bool _isMusicEnabled = true;
  bool _isSoundEnabled = true;
  bool _isInitialized = false;
  bool _wasMusicPlayingBeforePause = false;
  double _currentMusicVolume = 0.5;
  double _currentSoundVolume = 0.5;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  double get currentMusicVolume => _currentMusicVolume;
  double get currentSoundVolume => _currentSoundVolume;

  Future<void> initialize() async {
    print('🎵 Початок ініціалізації AudioService...');

    if (_isInitialized) {
      print('✅ AudioService вже ініціалізований');
      return;
    }

    await StorageService().initialize();

    final audioSettings = StorageService().loadAudioSettings();
    _isMusicEnabled = audioSettings['musicEnabled'];
    _isSoundEnabled = audioSettings['soundEnabled'];
    _currentMusicVolume = audioSettings['musicVolume'];
    _currentSoundVolume = audioSettings['musicVolume'];
    _backgroundMusicPlayer = AudioPlayer();

    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);

    await _backgroundMusicPlayer.setPlayerMode(PlayerMode.mediaPlayer);

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      print('✅ Аудіо контекст налаштовано');
    } catch (e) {
      print('❌ Помилка налаштування аудіо контексту: $e');
    }
    WidgetsBinding.instance.addObserver(this);

    await _backgroundMusicPlayer.setVolume(_currentMusicVolume);

    _isInitialized = true;
    print('✅ AudioService ініціалізовано успішно');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔄 Зміна стану додатка: $state');

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _handleAppPause();
        break;
      case AppLifecycleState.resumed:
        _handleAppResume();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _handleAppPause() {
    print('⏸️ Додаток згорнуто - зупиняємо фонову музику');

    _wasMusicPlayingBeforePause = _isMusicEnabled && _isInitialized;

    if (_isInitialized) {
      pauseBackgroundMusic();
    }
  }

  void _handleAppResume() {
    print('▶️ Додаток відновлено');

    if (_wasMusicPlayingBeforePause && _isMusicEnabled && _isInitialized) {
      print('🎵 Відновлюємо фонову музику');
      playBackgroundMusic();
    }
  }

  Future<void> playBackgroundMusic() async {
    print('🎵 Спроба запуску фонової музики...');

    if (!_isInitialized) {
      print('❌ AudioService не ініціалізований');
      return;
    }

    if (!_isMusicEnabled) {
      print('❌ Фонова музика вимкнена');
      return;
    }

    try {
      // Перевіряємо поточний стан плеєра
      final currentState = _backgroundMusicPlayer.state;
      print('🎵 Поточний стан плеєра: $currentState');

      if (currentState == PlayerState.playing) {
        print('🎵 Фонова музика вже грає');
        return;
      }

      if (currentState == PlayerState.paused) {
        print('🎵 Відновлюємо паузу фонової музики');
        await _backgroundMusicPlayer.resume();
        print('✅ Фонову музику відновлено');
        return;
      }

      print('🎵 Запускаємо sounds/backgroundmusic.mp3...');
      await _backgroundMusicPlayer.play(
        AssetSource('sounds/backgroundmusic.mp3'),
      );
      print('✅ Фонова музика запущена');
    } catch (e) {
      print('❌ Помилка відтворення фонової музики: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    print('🔇 Спроба зупинки фонової музики...');

    if (!_isInitialized) {
      print('❌ AudioService не ініціалізований');
      return;
    }

    try {
      final currentState = _backgroundMusicPlayer.state;
      print('🔇 Поточний стан плеєра перед зупинкою: $currentState');

      await _backgroundMusicPlayer.stop();
      print('✅ Фонова музика зупинена');
    } catch (e) {
      print('❌ Помилка зупинки фонової музики: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    if (!_isInitialized) return;

    try {
      await _backgroundMusicPlayer.pause();
    } catch (e) {
      print('Помилка паузи фонової музики: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!_isInitialized) return;

    try {
      await _backgroundMusicPlayer.resume();
    } catch (e) {
      print('Помилка відновлення фонової музики: $e');
    }
  }

  Future<void> playClickSound() async {
    print('🔊 Спроба відтворення звуку кліку...');

    if (!_isInitialized) {
      print('❌ AudioService не ініціалізований');
      return;
    }

    if (!_isSoundEnabled) {
      print('❌ Звуки вимкнені');
      return;
    }

    try {
      print('🔊 Створюємо новий плеєр для звуку кліку...');
      final clickPlayer = AudioPlayer();

      // Налаштовуємо режим плеєра для кращої сумісності
      await clickPlayer.setPlayerMode(PlayerMode.lowLatency);
      await clickPlayer.setVolume(_currentSoundVolume);

      print('🔊 Запускаємо відтворення sounds/click.mp3...');

      // Спробуємо різні формати аудіо
      try {
        await clickPlayer.play(AssetSource('sounds/click.mp3'));
        print('✅ Звук кліку запущено успішно (MP3)');
      } catch (mp3Error) {
        print('⚠️ Помилка MP3, спробуємо WAV: $mp3Error');
        try {
          await clickPlayer.play(AssetSource('sounds/click.wav'));
          print('✅ Звук кліку запущено успішно (WAV)');
        } catch (wavError) {
          print('⚠️ Помилка WAV, спробуємо OGG: $wavError');
          try {
            await clickPlayer.play(AssetSource('sounds/click.ogg'));
            print('✅ Звук кліку запущено успішно (OGG)');
          } catch (oggError) {
            print('❌ Всі формати не працюють, пропускаємо звук кліку');
            clickPlayer.dispose();
            return;
          }
        }
      }

      clickPlayer.onPlayerComplete.listen((event) {
        print('🔊 Звук кліку завершено, звільняємо ресурси');
        clickPlayer.dispose();
      });

      clickPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.stopped) {
          print('🔊 Звук кліку зупинено');
        }
      });
    } catch (e) {
      print('❌ Помилка відтворення звуку кліку: $e');
    }
  }

  Future<void> playPopSound() async {
    print('🔊 Спроба відтворення pop звуку...');

    if (!_isInitialized) {
      print('❌ AudioService не ініціалізований');
      return;
    }

    if (!_isSoundEnabled) {
      print('❌ Звуки вимкнені');
      return;
    }

    try {
      print('🔊 Створюємо новий плеєр для pop звуку...');
      final popPlayer = AudioPlayer();

      // Налаштовуємо режим плеєра для кращої сумісності
      await popPlayer.setPlayerMode(PlayerMode.lowLatency);
      await popPlayer.setVolume(_currentSoundVolume);

      print('🔊 Запускаємо відтворення sounds/pop.mp3...');

      // Спробуємо різні формати аудіо
      try {
        await popPlayer.play(AssetSource('sounds/pop.mp3'));
        print('✅ Pop звук запущено успішно (MP3)');
      } catch (mp3Error) {
        print('⚠️ Помилка MP3, спробуємо WAV: $mp3Error');
        try {
          await popPlayer.play(AssetSource('sounds/pop.wav'));
          print('✅ Pop звук запущено успішно (WAV)');
        } catch (wavError) {
          print('⚠️ Помилка WAV, спробуємо OGG: $wavError');
          try {
            await popPlayer.play(AssetSource('sounds/pop.ogg'));
            print('✅ Pop звук запущено успішно (OGG)');
          } catch (oggError) {
            print('❌ Всі формати не працюють, пропускаємо pop звук');
            popPlayer.dispose();
            return;
          }
        }
      }

      popPlayer.onPlayerComplete.listen((event) {
        print('🔊 Pop звук завершено, звільняємо ресурси');
        popPlayer.dispose();
      });

      popPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.stopped) {
          print('🔊 Pop звук зупинено');
        }
      });
    } catch (e) {
      print('❌ Помилка відтворення pop звуку: $e');
    }
  }

  Future<void> playBreakingSound() async {
    print('🔊 Спроба відтворення breaking звуку...');

    if (!_isInitialized) {
      print('❌ AudioService не ініціалізований');
      return;
    }

    if (!_isSoundEnabled) {
      print('❌ Звуки вимкнені');
      return;
    }

    try {
      print('🔊 Створюємо новий плеєр для breaking звуку...');
      final breakingPlayer = AudioPlayer();

      // Налаштовуємо режим плеєра для кращої сумісності
      await breakingPlayer.setPlayerMode(PlayerMode.lowLatency);
      await breakingPlayer.setVolume(_currentSoundVolume);

      print('🔊 Запускаємо відтворення sounds/breaking.mp3...');

      // Спробуємо різні формати аудіо
      try {
        await breakingPlayer.play(AssetSource('sounds/breaking.mp3'));
        print('✅ Breaking звук запущено успішно (MP3)');
      } catch (mp3Error) {
        print('⚠️ Помилка MP3, спробуємо WAV: $mp3Error');
        try {
          await breakingPlayer.play(AssetSource('sounds/breaking.wav'));
          print('✅ Breaking звук запущено успішно (WAV)');
        } catch (wavError) {
          print('⚠️ Помилка WAV, спробуємо OGG: $wavError');
          try {
            await breakingPlayer.play(AssetSource('sounds/breaking.ogg'));
            print('✅ Breaking звук запущено успішно (OGG)');
          } catch (oggError) {
            print(
              '❌ Всі формати не працюють, використовуємо pop звук як заміну',
            );
            // Використовуємо pop звук як заміну
            await breakingPlayer.play(AssetSource('sounds/pop.mp3'));
            print('✅ Використовуємо pop звук як заміну');
          }
        }
      }

      breakingPlayer.onPlayerComplete.listen((event) {
        print('🔊 Breaking звук завершено, звільняємо ресурси');
        breakingPlayer.dispose();
      });

      breakingPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.stopped) {
          print('🔊 Breaking звук зупинено');
        }
      });
    } catch (e) {
      print('❌ Помилка відтворення breaking звуку: $e');
    }
  }

  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    _saveAudioSettings();
    if (_isMusicEnabled) {
      playBackgroundMusic();
    } else {
      pauseBackgroundMusic();
    }
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    _saveAudioSettings();
    print('🔊 Звуки ${_isSoundEnabled ? "увімкнено" : "вимкнено"}');
  }

  void setMusicVolume(double volume) {
    if (!_isInitialized) return;

    _currentMusicVolume = volume.clamp(0.0, 1.0);
    _currentSoundVolume = volume.clamp(0.0, 1.0);
    _backgroundMusicPlayer.setVolume(_currentMusicVolume);
    _saveAudioSettings();
    print('🎵 Гучність встановлено: ${(_currentMusicVolume * 100).round()}%');
  }

  void setSoundVolume(double volume) {}

  void _saveAudioSettings() {
    if (!_isInitialized) return;

    StorageService().saveAudioSettings(
      musicEnabled: _isMusicEnabled,
      soundEnabled: _isSoundEnabled,
      musicVolume: _currentMusicVolume,
    );
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;

    print('🗑️ Звільняємо ресурси AudioService...');

    WidgetsBinding.instance.removeObserver(this);

    await _backgroundMusicPlayer.dispose();
    _isInitialized = false;

    print('✅ AudioService очищено');
  }
}
