import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  static const String _keyCredit = 'credit';
  static const String _keyBetAmount = 'bet_amount';
  static const String _keyDoubleChance = 'double_chance';
  static const String _keyAutoplayCount = 'autoplay_count';
  static const String _keyMusicEnabled = 'music_enabled';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyMusicVolume = 'music_volume';
  static const String _keyPurchasedBackgrounds = 'purchased_backgrounds';
  static const String _keySelectedBackground = 'selected_background';

  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🗃️ Ініціалізація StorageService...');
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    print('✅ StorageService ініціалізовано');
  }

  Future<void> saveCredit(double credit) async {
    if (!_isInitialized) await initialize();
    await _prefs.setDouble(_keyCredit, credit);
    print('💰 Кредити збережено: \$${credit.toStringAsFixed(2)}');
  }

  double loadCredit() {
    if (!_isInitialized) return 100000.0;
    final credit = _prefs.getDouble(_keyCredit) ?? 100000.0;
    print('💰 Кредити завантажено: \$${credit.toStringAsFixed(2)}');
    return credit;
  }

  Future<void> saveBetAmount(double betAmount) async {
    if (!_isInitialized) await initialize();
    await _prefs.setDouble(_keyBetAmount, betAmount);
    print('🎰 Ставка збережена: \$${betAmount.toStringAsFixed(2)}');
  }

  double loadBetAmount() {
    if (!_isInitialized) return 2.50;
    final betAmount = _prefs.getDouble(_keyBetAmount) ?? 2.50;
    print('🎰 Ставка завантажена: \$${betAmount.toStringAsFixed(2)}');
    return betAmount;
  }

  Future<void> saveDoubleChance(bool enabled) async {
    if (!_isInitialized) await initialize();
    await _prefs.setBool(_keyDoubleChance, enabled);
    print('🎲 Double Chance збережено: ${enabled ? "ON" : "OFF"}');
  }

  bool loadDoubleChance() {
    if (!_isInitialized) return false;
    final enabled = _prefs.getBool(_keyDoubleChance) ?? false;
    print('🎲 Double Chance завантажено: ${enabled ? "ON" : "OFF"}');
    return enabled;
  }

  Future<void> saveAutoplaySettings({
    required int count,
  }) async {
    if (!_isInitialized) await initialize();
    await _prefs.setInt(_keyAutoplayCount, count);
    print(
      '⚡ Автоспін збережено: $count спінів (завжди turbo)',
    );
  }

  Map<String, dynamic> loadAutoplaySettings() {
    if (!_isInitialized) {
      return {'count': 10};
    }

    final settings = {
      'count': _prefs.getInt(_keyAutoplayCount) ?? 10,
    };

    print(
      '⚡ Автоспін завантажено: ${settings['count']} спінів (завжди turbo)',
    );
    return settings;
  }

  Future<void> saveAudioSettings({
    required bool musicEnabled,
    required bool soundEnabled,
    required double musicVolume,
  }) async {
    if (!_isInitialized) await initialize();
    await _prefs.setBool(_keyMusicEnabled, musicEnabled);
    await _prefs.setBool(_keySoundEnabled, soundEnabled);
    await _prefs.setDouble(_keyMusicVolume, musicVolume);
    print(
      '🔊 Аудіо збережено: Music: $musicEnabled, Sound: $soundEnabled, Volume: ${(musicVolume * 100).round()}%',
    );
  }

  Map<String, dynamic> loadAudioSettings() {
    if (!_isInitialized) {
      return {'musicEnabled': true, 'soundEnabled': true, 'musicVolume': 0.5};
    }

    final settings = {
      'musicEnabled': _prefs.getBool(_keyMusicEnabled) ?? true,
      'soundEnabled': _prefs.getBool(_keySoundEnabled) ?? true,
      'musicVolume': _prefs.getDouble(_keyMusicVolume) ?? 0.5,
    };

    print(
      '🔊 Аудіо завантажено: Music: ${settings['musicEnabled']}, Sound: ${settings['soundEnabled']}, Volume: ${((settings['musicVolume'] as double) * 100).round()}%',
    );
    return settings;
  }

  Future<void> resetToDefaults() async {
    if (!_isInitialized) await initialize();

    await _prefs.clear();
    print('🔄 Всі налаштування скинуто до значень за замовчуванням');
  }

  Future<void> savePurchasedBackgrounds(List<String> backgrounds) async {
    if (!_isInitialized) await initialize();
    await _prefs.setStringList(_keyPurchasedBackgrounds, backgrounds);
    print('🎨 Куплені фони збережено: $backgrounds');
  }

  List<String> loadPurchasedBackgrounds() {
    if (!_isInitialized) return ['bg'];
    final backgrounds =
        _prefs.getStringList(_keyPurchasedBackgrounds) ?? ['bg'];
    print('🎨 Куплені фони завантажено: $backgrounds');
    return backgrounds;
  }

  Future<void> saveSelectedBackground(String background) async {
    if (!_isInitialized) await initialize();
    await _prefs.setString(_keySelectedBackground, background);
    print('🎨 Вибраний фон збережено: $background');
  }

  String loadSelectedBackground() {
    if (!_isInitialized) return 'bg';
    final background = _prefs.getString(_keySelectedBackground) ?? 'bg';
    print('🎨 Вибраний фон завантажено: $background');
    return background;
  }

  Future<void> addPurchasedBackground(String background) async {
    if (!_isInitialized) await initialize();

    List<String> purchased = loadPurchasedBackgrounds();
    if (!purchased.contains(background)) {
      purchased.add(background);
      await savePurchasedBackgrounds(purchased);
      print('🎨 Новий фон додано до куплених: $background');
    }
  }

  bool isBackgroundPurchased(String background) {
    if (!_isInitialized) return background == 'bg';
    final purchased = loadPurchasedBackgrounds();
    return purchased.contains(background);
  }

  bool get isInitialized => _isInitialized;
}
