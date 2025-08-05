// lib/utils/preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _balanceKey = 'player_balance';
  static const String _autoSpinCountKey = 'autoSpin_count';
  static const String _skipScenesKey = 'autoSpin_skipScenes';
  static const String _quickSpinKey = 'quickSpin_enabled';
  static const String _turboSpinKey = 'turboSpin_enabled';
  static const String _isDoubleChanceEnabledKey = 'doubleChance_enabled';
  static const String _currentBetKey = 'current_bet';
  static const String _currentCoinValueKey = 'current_coinValue';

  // Збереження балансу
  static Future<void> saveBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, balance);
    print('💾 Збережено баланс: $balance');
  }

  // Завантаження балансу
  static Future<double> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final balance = prefs.getDouble(_balanceKey) ?? 1000.0; // Дефолтний баланс
    print('📂 Завантажено баланс: $balance');
    return balance;
  }

  // Збереження налаштувань автоспіну
  static Future<void> saveAutoSpinSettings(int count, bool skipScenes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoSpinCountKey, count);
    await prefs.setBool(_skipScenesKey, skipScenes);
    print('💾 Збережено налаштування автоспіну: count=$count, skipScenes=$skipScenes');
  }

  // Завантаження налаштувань автоспіну
  static Future<Map<String, dynamic>> loadAutoSpinSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_autoSpinCountKey) ?? 100;
    final skipScenes = prefs.getBool(_skipScenesKey) ?? false;
    print('📂 Завантажено налаштування автоспіну: count=$count, skipScenes=$skipScenes');
    return {
      'count': count,
      'skipScenes': skipScenes,
    };
  }

  // Збереження налаштувань швидкості спіну
  static Future<void> saveSpinSpeedSettings(bool quickSpin, bool turboSpin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quickSpinKey, quickSpin);
    await prefs.setBool(_turboSpinKey, turboSpin);
    print('💾 Збережено налаштування швидкості: quickSpin=$quickSpin, turboSpin=$turboSpin');
  }

  // Завантаження налаштувань швидкості спіну
  static Future<Map<String, bool>> loadSpinSpeedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final quickSpin = prefs.getBool(_quickSpinKey) ?? false;
    final turboSpin = prefs.getBool(_turboSpinKey) ?? false;
    print('📂 Завантажено налаштування швидкості: quickSpin=$quickSpin, turboSpin=$turboSpin');
    return {
      'quickSpin': quickSpin,
      'turboSpin': turboSpin,
    };
  }

  // Збереження налаштування Double Chance
  static Future<void> saveDoubleChanceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDoubleChanceEnabledKey, enabled);
    print('💾 Збережено Double Chance: $enabled');
  }

  // Завантаження налаштування Double Chance
  static Future<bool> loadDoubleChanceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_isDoubleChanceEnabledKey) ?? false;
    print('📂 Завантажено Double Chance: $enabled');
    return enabled;
  }

  // Збереження ставки
  static Future<void> saveBetSettings(int currentBet, double currentCoinValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentBetKey, currentBet);
    await prefs.setDouble(_currentCoinValueKey, currentCoinValue);
    print('💾 Збережено ставки: bet=$currentBet, coinValue=$currentCoinValue');
  }

  // Завантаження ставки
  static Future<Map<String, dynamic>> loadBetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currentBet = prefs.getInt(_currentBetKey) ?? 5; // Дефолтна ставка
    final currentCoinValue = prefs.getDouble(_currentCoinValueKey) ?? 0.10; // Дефолтна вартість монети
    print('📂 Завантажено ставки: bet=$currentBet, coinValue=$currentCoinValue');
    return {
      'currentBet': currentBet,
      'currentCoinValue': currentCoinValue,
    };
  }

  // Очищення всіх налаштувань (для дебагу)
  static Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('🧹 Очищено всі збережені налаштування');
  }
}
