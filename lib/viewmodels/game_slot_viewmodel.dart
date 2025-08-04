import 'package:flutter/material.dart';
import 'package:flutter_test_task/services/storage_service.dart';
import 'dart:math';

class GameSlotViewModel extends ChangeNotifier {
  static const int rowCount = 5;
  static const int colCount = 6;

  Function(double)? onAnimationWinCallback;

  Function(double)? onBuyFeatureWinAccumulate;

  double _betAmount = 2.50;
  double _credit = 100000.00;
  int _multiplier = 21100;
  bool _doubleChanceEnabled = false;
  bool _shouldBuyFeature = false;
  List<String> _collectedMultipliers = [];
  double _currentWin = 0.0;
  bool _showWin = false;

  int _autoplayCount = 10;
  bool _quickSpinEnabled = false;
  bool _turboSpinEnabled = false;
  bool _isAutoplayActive = false;
  int _currentAutoplayCount = 0;
  bool _hasAutoplayBeenStarted = false;
  bool _isInitialized = false;

  GameSlotViewModel() {
    _initializeFromStorage();
    _initializeSlots();
  }

  Future<void> _initializeFromStorage() async {
    if (_isInitialized) return;

    print('🗃️ Завантаження даних з локального сховища...');

    await StorageService().initialize();

    _credit = StorageService().loadCredit();
    _betAmount = StorageService().loadBetAmount();
    _doubleChanceEnabled = StorageService().loadDoubleChance();

    final autoplaySettings = StorageService().loadAutoplaySettings();
    _autoplayCount = autoplaySettings['count'];
    _quickSpinEnabled = autoplaySettings['quickSpin'];
    _turboSpinEnabled = autoplaySettings['turboSpin'];

    _isInitialized = true;
    print('✅ Дані завантажено з локального сховища');

    notifyListeners();
  }

  double get betAmount => _betAmount;
  double get credit => _credit;
  int get multiplier => _multiplier;
  bool get doubleChanceEnabled => _doubleChanceEnabled;
  bool get shouldBuyFeature => _shouldBuyFeature;
  List<String> get collectedMultipliers => _collectedMultipliers;
  double get currentWin => _currentWin;
  bool get showWin => _showWin;

  int get autoplayCount => _autoplayCount;
  bool get quickSpinEnabled => _quickSpinEnabled;
  bool get turboSpinEnabled => _turboSpinEnabled;
  bool get isAutoplayActive => _isAutoplayActive;
  int get currentAutoplayCount => _currentAutoplayCount;
  bool get hasAutoplayBeenStarted => _hasAutoplayBeenStarted;

  double get effectiveBetAmount =>
      _doubleChanceEnabled ? _betAmount * 1.25 : _betAmount;

  final List<String> slotSymbols = [
    'assets/images/candy1.png',
    'assets/images/candy2.png',
    'assets/images/candy3.png',
    'assets/images/candy4.png',
    'assets/images/candy5.png',
    'assets/images/candy6.png',
    'assets/images/candy7.png',
    'assets/images/candy8.png',
    'assets/images/candy9.png',
    'assets/images/lolipop.png',
  ];

  final Map<String, Map<String, double>> payoutMultipliers = {
    'assets/images/candy1.png': {'12+': 50.0, '10-11': 25.0, '8-9': 10.0},
    'assets/images/candy2.png': {'12+': 25.0, '10-11': 10.0, '8-9': 2.5},
    'assets/images/candy3.png': {'12+': 15.0, '10-11': 5.0, '8-9': 2.0},
    'assets/images/candy4.png': {'12+': 12.0, '10-11': 2.0, '8-9': 1.0},
    'assets/images/candy5.png': {'12+': 10.0, '10-11': 1.5, '8-9': 1.0},
    'assets/images/candy6.png': {'12+': 8.0, '10-11': 1.2, '8-9': 0.8},
    'assets/images/candy7.png': {'12+': 5.0, '10-11': 1.0, '8-9': 0.5},
    'assets/images/candy8.png': {'12+': 4.0, '10-11': 0.75, '8-9': 0.4},
    'assets/images/candy9.png': {'12+': 2.0, '10-11': 0.5, '8-9': 0.25},
    'assets/images/lolipop.png': {'12+': 2.0, '10-11': 0.5, '8-9': 0.25},
  };

  final Map<String, double> multiplierValues = {
    'assets/images/multi1.png': 1.0,
    'assets/images/multi2.png': 2.0,
    'assets/images/multi4.png': 4.0,
    'assets/images/multi8.png': 8.0,
    'assets/images/multi20.png': 20.0,
    'assets/images/multi50.png': 50.0,
    'assets/images/multi100.png': 100.0,
  };

  List<List<String>> _currentSlots = [];
  List<List<String>> get currentSlots => _currentSlots;

  void _initializeSlots() {
    _currentSlots = List.generate(
      rowCount,
      (row) => List.generate(
        colCount,
        (col) => slotSymbols[Random().nextInt(slotSymbols.length)],
      ),
    );
    notifyListeners();
  }

  void increaseBet() {
    _betAmount += 0.50;
    StorageService().saveBetAmount(_betAmount);
    notifyListeners();
  }

  void decreaseBet() {
    if (_betAmount > 0.50) {
      _betAmount -= 0.50;
      StorageService().saveBetAmount(_betAmount);
      notifyListeners();
    }
  }

  void setBetAmount(double amount) {
    _betAmount = amount;
    StorageService().saveBetAmount(_betAmount);
    notifyListeners();
  }

  bool canSpin() {
    return _credit >= effectiveBetAmount;
  }

  void placeBet() {
    if (canSpin()) {
      _credit -= effectiveBetAmount;
      StorageService().saveCredit(_credit);
      clearWin();
      if (!_shouldBuyFeature) {
        _collectedMultipliers.clear();
      }
      notifyListeners();
    }
  }

  void toggleDoubleChance() {
    _doubleChanceEnabled = !_doubleChanceEnabled;
    StorageService().saveDoubleChance(_doubleChanceEnabled);
    notifyListeners();
  }

  double get buyFeaturePrice {
    final calculatedPrice = _betAmount * 100;
    return calculatedPrice > 10000 ? 10000 : calculatedPrice;
  }

  bool canBuyFeature() {
    return _credit >= buyFeaturePrice && !_doubleChanceEnabled;
  }

  void addWinnings(double amount) {
    _credit += amount;
    StorageService().saveCredit(_credit);
    notifyListeners();
  }

  void buyFeature() {
    if (canBuyFeature()) {
      print('🎁 ПОЧИНАЄТЬСЯ BUY FEATURE!');
      print('Ціна: \$${buyFeaturePrice.toStringAsFixed(2)}');

      _credit -= buyFeaturePrice;
      StorageService().saveCredit(_credit);
      _collectedMultipliers = [];
      clearWin();
      _shouldBuyFeature = true;

      print('Множники очищені для нової buy feature');

      notifyListeners();

      Future.delayed(const Duration(milliseconds: 100), () {
        _shouldBuyFeature = false;
        notifyListeners();
      });
    }
  }

  void triggerBuyFeatureFromScatter() {
    print('🍭 БЕЗКОШТОВНИЙ BUY FEATURE через Scatter символи!');

    _collectedMultipliers = [];
    clearWin();
    _shouldBuyFeature = true;

    print('Buy feature запущений через scatters, без витрат кредиту');

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 100), () {
      _shouldBuyFeature = false;
      notifyListeners();
    });
  }

  void clearMultipliersAfterSpin() {
    print('🎰 Очищення множників після спіну: $_collectedMultipliers');
    _collectedMultipliers.clear();
    notifyListeners();
  }

  void processMultipliers(List<String> foundMultipliers) {
    print('=== ЗБІР МНОЖНИКІВ ===');
    print('Знайдені множники: $foundMultipliers');
    print('Попередні множники: $_collectedMultipliers');

    _collectedMultipliers.addAll(foundMultipliers);

    print('Усі зібрані множники: $_collectedMultipliers');
    print('======================');

    notifyListeners();
  }

  double getTotalMultiplier() {
    if (_collectedMultipliers.isEmpty) return 1.0;

    print('--- Розрахунок множника ---');
    print('Зібрані множники: $_collectedMultipliers');

    double totalMultiplier = 0.0;
    for (String multiplier in _collectedMultipliers) {
      double value = multiplierValues[multiplier] ?? 0.0;
      totalMultiplier += value;
      print('$multiplier додає $value, поточна сума: $totalMultiplier');
    }

    double result = totalMultiplier > 0 ? totalMultiplier : 1.0;
    print('Фінальний множник: x$result');
    print('---------------------------');

    return result;
  }

  String getFormattedWinString(double baseWin) {
    double totalMultiplier = getTotalMultiplier();

    if (totalMultiplier > 1.0) {
      double finalWin = baseWin * totalMultiplier;
      return '\$${baseWin.toStringAsFixed(2)} x${totalMultiplier.toStringAsFixed(1)} = \$${finalWin.toStringAsFixed(2)}';
    } else {
      return '\$${baseWin.toStringAsFixed(2)}';
    }
  }

  String getWinDisplayText() {
    if (!_showWin || _currentWin <= 0) return '';

    double totalMultiplier = getTotalMultiplier();

    if (totalMultiplier > 1.0) {
      return 'WIN \$${_currentWin.toStringAsFixed(2)} x${totalMultiplier.toStringAsFixed(1)}';
    } else {
      return 'WIN \$${_currentWin.toStringAsFixed(2)}';
    }
  }

  void clearWin() {
    _currentWin = 0.0;
    _showWin = false;
    notifyListeners();
  }

  void setAutoplaySettings({
    required int autoplayCount,
    required bool quickSpin,
    required bool turboSpin,
  }) {
    _autoplayCount = autoplayCount;
    _quickSpinEnabled = quickSpin;
    _turboSpinEnabled = turboSpin;

    StorageService().saveAutoplaySettings(
      count: autoplayCount,
      quickSpin: quickSpin,
      turboSpin: turboSpin,
    );

    if (autoplayCount == 0) {
      _hasAutoplayBeenStarted = false;
    }
    notifyListeners();
  }

  void startAutoplay() {
    _isAutoplayActive = true;
    _currentAutoplayCount = _autoplayCount;
    _hasAutoplayBeenStarted = true;
    notifyListeners();
  }

  void stopAutoplay() {
    _isAutoplayActive = false;
    _currentAutoplayCount = 0;
    _hasAutoplayBeenStarted = false;
    notifyListeners();
  }

  void decrementAutoplayCount() {
    if (_currentAutoplayCount > 0) {
      _currentAutoplayCount--;
      if (_currentAutoplayCount <= 0) {
        stopAutoplay();
      }
      notifyListeners();
    }
  }

  bool shouldUseQuickAnimation() {
    return _quickSpinEnabled || _turboSpinEnabled;
  }

  double getAnimationSpeedMultiplier() {
    if (_turboSpinEnabled) {
      return 2.0;
    } else if (_quickSpinEnabled) {
      return 1.5;
    }
    return 1.0;
  }

  void setCurrentWin(double win) {
    _currentWin = win;
    _showWin = win > 0;
    notifyListeners();
  }

  void processBuyFeatureComplete(double totalWin) {
    print(
      '🎁 BUY FEATURE ЗАВЕРШЕНО! Загальний виграш: \$${totalWin.toStringAsFixed(2)}',
    );

    String winType = _getWinType(totalWin);
    print('🏆 Тип виграшу: $winType');
  }

  String _getWinType(double winAmount) {
    double multiplier = winAmount / _betAmount;

    if (multiplier >= 1000) {
      return 'grandiosewin';
    } else if (multiplier >= 500) {
      return 'megawin';
    } else if (multiplier >= 200) {
      return 'epicwin';
    } else if (multiplier >= 50) {
      return 'bigwin';
    } else if (multiplier >= 10) {
      return 'nicewin';
    } else {
      return 'nicewin';
    }
  }

  void generateNewSlots() {
    _currentSlots = List.generate(
      rowCount,
      (row) => List.generate(
        colCount,
        (col) => slotSymbols[Random().nextInt(slotSymbols.length)],
      ),
    );
    notifyListeners();
  }

  void updateSlotsFromAnimation(List<List<String>> newGrid) {
    _currentSlots = newGrid;
    notifyListeners();
  }

  void processWinnings(Map<String, int> winningCounts) {
    double baseWinnings = calculateWinnings(winningCounts);

    if (baseWinnings > 0) {
      setCurrentWin(baseWinnings);

      double totalMultiplier = getTotalMultiplier();
      double finalWinnings = baseWinnings * totalMultiplier;

      print('=== РОЗРАХУНОК ВИГРАШУ ===');
      print(
        'Базовий виграш (без множників): \$${baseWinnings.toStringAsFixed(2)}',
      );

      if (_collectedMultipliers.isNotEmpty) {
        print('Зібрані множники: $_collectedMultipliers');
        for (String multiplier in _collectedMultipliers) {
          double value = multiplierValues[multiplier] ?? 0.0;
          print('  $multiplier = x$value');
        }
        print('Сума множників: x${totalMultiplier.toStringAsFixed(1)}');
        print(
          'Розрахунок: \$${baseWinnings.toStringAsFixed(2)} × ${totalMultiplier.toStringAsFixed(1)} = \$${finalWinnings.toStringAsFixed(2)}',
        );
      } else {
        print('Множники відсутні');
      }

      print('Загальна сума виграшу: \$${finalWinnings.toStringAsFixed(2)}');
      print('=========================');

      addWinnings(finalWinnings);

      if (onAnimationWinCallback != null) {
        onAnimationWinCallback!(finalWinnings);
      }

      if (onBuyFeatureWinAccumulate != null) {
        print(
          '💸 Передаємо виграш до анімації: \$${finalWinnings.toStringAsFixed(2)}',
        );
        onBuyFeatureWinAccumulate!(finalWinnings);
      }
    } else {
      clearWin();
    }
  }

  double calculateWinnings(Map<String, int> winningCounts) {
    double totalWinnings = 0.0;
    final currentBet = effectiveBetAmount;
    winningCounts.forEach((symbol, count) {
      if (payoutMultipliers.containsKey(symbol)) {
        final multipliers = payoutMultipliers[symbol]!;
        double multiplier = 0.0;

        if (count >= 12) {
          multiplier = multipliers['12+'] ?? 0.0;
        } else if (count >= 10) {
          multiplier = multipliers['10-11'] ?? 0.0;
        } else if (count >= 8) {
          multiplier = multipliers['8-9'] ?? 0.0;
        }

        if (multiplier > 0) {
          totalWinnings += currentBet * multiplier;
        }
      }
    });

    return totalWinnings;
  }
}
