import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_task/services/audio_service.dart';

class SlotAnimationGame extends FlameGame with HasGameRef {
  static const int gridRows = 5;
  static const int gridCols = 6;
  static const double symbolSize = 45.0;
  static const double symbolSpacing = 5.0;

  late double gridStartX;
  late double gridStartY;
  late List<List<SlotSymbol>> gridSymbols;
  bool isAnimating = false;
  Function(Map<String, int>)? onWinningsCallback;
  Function(List<String>)? onMultipliersCallback;
  Function()? onSpinCompleteCallback;
  Function(double, String)? onBuyFeatureWinCallback;
  Function(double)? onBuyFeatureWinAccumulate;

  bool useQuickAnimation = false;
  double animationSpeedMultiplier = 1.0;

  bool isBuyFeatureActive = false;
  int buyFeatureSpinsLeft = 0;
  bool _multipliersCollectedThisSpin = false;
  double _buyFeatureTotalWin = 0.0;
  Function(double, String)? onBuyFeatureComplete;

  Function(int)? onScatterCallback;

  static const List<String> candySymbols = [
    'assets/images/candy1.png',
    'assets/images/candy2.png',
    'assets/images/candy3.png',
    'assets/images/candy4.png',
    'assets/images/candy5.png',
    'assets/images/candy6.png',
    'assets/images/candy7.png',
  ];

  static const List<String> multiplierSymbols = [
    'assets/images/multi1.png',
    'assets/images/multi2.png',
    'assets/images/multi4.png',
    'assets/images/multi8.png',
    'assets/images/multi20.png',
    'assets/images/multi50.png',
    'assets/images/multi100.png',
  ];

  static const String scatterSymbol = 'assets/images/lolipop.png';
  @override
  Color backgroundColor() {
    return Colors.transparent;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    gridStartX =
        (size.x - (gridCols * (symbolSize + symbolSpacing) - symbolSpacing)) /
        2;
    gridStartY =
        (size.y - (gridRows * (symbolSize + symbolSpacing) - symbolSpacing)) /
        2;

    gridSymbols = List.generate(
      gridRows,
      (row) => List.generate(gridCols, (col) => SlotSymbol()),
    );

    await _initializeGrid();
  }

  void setAnimationSettings({
    required bool useQuick,
    required double speedMultiplier,
  }) {
    useQuickAnimation = useQuick;
    animationSpeedMultiplier = speedMultiplier;
  }

  String _getRandomSymbol() {
    final random = math.Random();

    if (random.nextDouble() < 0.01) {
      return scatterSymbol;
    }

    if (isBuyFeatureActive) {
      if (random.nextDouble() < 0.05) {
        return multiplierSymbols[random.nextInt(multiplierSymbols.length)];
      }
    }

    return candySymbols[random.nextInt(candySymbols.length)];
  }

  Future<void> _initializeGrid() async {
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final symbol = gridSymbols[row][col];

        final exactPosition = Vector2(
          gridStartX + col * (symbolSize + symbolSpacing),
          gridStartY + row * (symbolSize + symbolSpacing),
        );

        symbol.position = exactPosition;
        symbol.size = Vector2(symbolSize, symbolSize);

        symbol.setOriginalPosition(exactPosition);

        final randomSymbol = _getRandomSymbol();
        await symbol.setSymbol(randomSymbol);

        add(symbol);
      }
    }
  }

  Future<void> startSpinAnimation() async {
    if (isAnimating) return;

    isAnimating = true;
    _multipliersCollectedThisSpin = false;
    await _animateSymbolsOut();

    await _animateSymbolsIn();

    await _checkForWinningCombinations();

    if (isBuyFeatureActive) {
      buyFeatureSpinsLeft--;
      if (buyFeatureSpinsLeft <= 0) {
        isBuyFeatureActive = false;
      }
    }

    isAnimating = false;

    if (onSpinCompleteCallback != null) {
      onSpinCompleteCallback!();
    }
  }

  Future<void> activateBuyFeature() async {
    isBuyFeatureActive = true;
    buyFeatureSpinsLeft = 10;
    _buyFeatureTotalWin = 0.0;
    print('🎁 ПОЧИНАЄТЬСЯ BUY FEATURE з 10 спінами!');

    int spinNumber = 1;
    while (buyFeatureSpinsLeft > 0) {
      print(
        '🎰 Buy Feature спін $spinNumber (залишилось: $buyFeatureSpinsLeft)',
      );
      await startSpinAnimation();
      spinNumber++;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print(
      '🎁 BUY FEATURE ЗАВЕРШЕНО! Загальний виграш: \$${_buyFeatureTotalWin.toStringAsFixed(2)}',
    );

    if (onBuyFeatureWinCallback != null) {
      String winType = _getWinType(_buyFeatureTotalWin);

      AudioService().playBreakingSound();

      onBuyFeatureWinCallback!(_buyFeatureTotalWin, winType);
    }
  }

  Future<void> _animateSymbolsOut() async {
    List<Future> animations = [];

    if (useQuickAnimation) {
      for (int row = 0; row < gridRows; row++) {
        for (int col = 0; col < gridCols; col++) {
          final symbol = gridSymbols[row][col];
          symbol.animateOut(speedMultiplier: animationSpeedMultiplier);
        }
      }

      final waitTime = (800 / animationSpeedMultiplier).round();
      await Future.delayed(Duration(milliseconds: waitTime));
    } else {
      for (int col = 0; col < gridCols; col++) {
        final delay = (col * 150 / animationSpeedMultiplier).round();

        animations.add(
          Future.delayed(Duration(milliseconds: delay), () async {
            for (int row = 0; row < gridRows; row++) {
              final symbol = gridSymbols[row][col];
              symbol.animateOut(speedMultiplier: animationSpeedMultiplier);
            }
          }),
        );
      }

      await Future.wait(animations);
      final waitTime = (1000 / animationSpeedMultiplier).round();
      await Future.delayed(Duration(milliseconds: waitTime));
    }
  }

  Future<void> _animateSymbolsIn() async {
    List<Future> animations = [];

    if (useQuickAnimation) {
      for (int row = 0; row < gridRows; row++) {
        for (int col = 0; col < gridCols; col++) {
          final symbol = gridSymbols[row][col];

          final randomSymbol = _getRandomSymbol();
          await symbol.setSymbol(randomSymbol);

          final rowDelay = (row * 30 / animationSpeedMultiplier).round();
          Future.delayed(Duration(milliseconds: rowDelay), () {
            symbol.animateIn(speedMultiplier: animationSpeedMultiplier);
          });
        }
      }

      final waitTime = (1000 / animationSpeedMultiplier).round();
      await Future.delayed(Duration(milliseconds: waitTime));
    } else {
      for (int col = 0; col < gridCols; col++) {
        final delay = (col * 150 / animationSpeedMultiplier).round();

        animations.add(
          Future.delayed(Duration(milliseconds: delay), () async {
            for (int row = 0; row < gridRows; row++) {
              final symbol = gridSymbols[row][col];

              final randomSymbol = _getRandomSymbol();
              await symbol.setSymbol(randomSymbol);

              final rowDelay = (row * 50 / animationSpeedMultiplier).round();
              Future.delayed(Duration(milliseconds: rowDelay), () {
                symbol.animateIn(speedMultiplier: animationSpeedMultiplier);
              });
            }
          }),
        );
      }

      await Future.wait(animations);
      final waitTime = (1200 / animationSpeedMultiplier).round();
      await Future.delayed(Duration(milliseconds: waitTime));
    }
  }

  Future<void> _checkForWinningCombinations() async {
    if (isBuyFeatureActive && !_multipliersCollectedThisSpin) {
      _collectMultipliers();
      _multipliersCollectedThisSpin = true;
    }

    int scatterCount = 0;
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final symbol = gridSymbols[row][col];
        if (symbol.currentSymbolPath == scatterSymbol) {
          scatterCount++;
        }
      }
    }

    if (scatterCount > 0) {
      print('🍭 Знайдено $scatterCount Scatter символів (lolipop)');

      if (!isBuyFeatureActive && scatterCount >= 4) {
        print('🎁 ЗАПУСК BUY FEATURE! Знайдено $scatterCount Scatters');

        _stopAllAnimations();
        isAnimating = false;
        await startBuyFeatureFromScatter();

        if (onScatterCallback != null) {
          onScatterCallback!(scatterCount);
        }

        return;
      } else if (isBuyFeatureActive && scatterCount >= 3) {
        print(
          '🎁 ДОДАТКОВІ ФРІСПІНИ! Знайдено $scatterCount Scatters, додаємо 5 спінів',
        );
        buyFeatureSpinsLeft += 5;
        if (onScatterCallback != null) {
          onScatterCallback!(-scatterCount);
        }
      }
    }

    Map<String, List<SlotSymbol>> symbolGroups = {};

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final symbol = gridSymbols[row][col];
        final symbolPath = symbol.currentSymbolPath;

        if (symbolPath != scatterSymbol) {
          if (!symbolGroups.containsKey(symbolPath)) {
            symbolGroups[symbolPath] = [];
          }
          symbolGroups[symbolPath]!.add(symbol);
        }
      }
    }

    List<SlotSymbol> winningSymbols = [];
    Map<String, int> winningCounts = {};

    for (var entry in symbolGroups.entries) {
      final symbolPath = entry.key;
      final symbolList = entry.value;

      if (symbolList.length >= 8) {
        winningSymbols.addAll(symbolList);
        winningCounts[symbolPath] = symbolList.length;
      }
    }

    if (winningSymbols.isNotEmpty) {
      AudioService().playPopSound();

      if (onWinningsCallback != null) {
        onWinningsCallback!(winningCounts);
      }

      await _animateWinningSymbols(winningSymbols);
      await _checkForWinningCombinations();
    }
  }

  Future<void> _animateWinningSymbols(List<SlotSymbol> winningSymbols) async {
    for (var symbol in winningSymbols) {
      symbol.animateWinOut();
    }

    await Future.delayed(const Duration(milliseconds: 500));

    Map<int, List<int>> winningPositions = {};
    for (var symbol in winningSymbols) {
      for (int row = 0; row < gridRows; row++) {
        for (int col = 0; col < gridCols; col++) {
          if (gridSymbols[row][col] == symbol) {
            if (!winningPositions.containsKey(col)) {
              winningPositions[col] = [];
            }
            winningPositions[col]!.add(row);
          }
        }
      }
    }

    for (var symbol in winningSymbols) {
      remove(symbol);
    }

    for (int col = 0; col < gridCols; col++) {
      if (winningPositions.containsKey(col)) {
        await _animateColumnGravity(col, winningPositions[col]!);
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _collectMultipliers() {
    List<String> foundMultipliers = [];

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final symbol = gridSymbols[row][col];
        final symbolPath = symbol.currentSymbolPath;

        if (multiplierSymbols.contains(symbolPath)) {
          foundMultipliers.add(symbolPath);
        }
      }
    }

    print('🎰 Збір множників на сітці: $foundMultipliers');

    if (foundMultipliers.isNotEmpty &&
        isBuyFeatureActive &&
        onMultipliersCallback != null) {
      onMultipliersCallback!(foundMultipliers);
    } else if (foundMultipliers.isEmpty) {
      print('🎰 Множники на сітці не знайдені');
    }
  }

  Future<void> _animateColumnGravity(int col, List<int> winningRows) async {
    winningRows.sort();
    List<SlotSymbol> remainingSymbols = [];
    List<int> remainingFromRows = [];

    for (int row = 0; row < gridRows; row++) {
      if (!winningRows.contains(row)) {
        remainingSymbols.add(gridSymbols[row][col]);
        remainingFromRows.add(row);
      }
    }

    List<SlotSymbol> newSymbols = [];
    for (int i = 0; i < winningRows.length; i++) {
      final newSymbol = SlotSymbol();
      final randomSymbolPath = _getRandomSymbol();
      await newSymbol.setSymbol(randomSymbolPath);

      final startPosition = Vector2(
        gridStartX + col * (symbolSize + symbolSpacing),
        gridStartY - (winningRows.length - i) * (symbolSize + symbolSpacing),
      );
      newSymbol.position = startPosition;
      newSymbol.size = Vector2(symbolSize, symbolSize);

      add(newSymbol);
      newSymbols.add(newSymbol);
    }

    for (int targetRow = 0; targetRow < gridRows; targetRow++) {
      SlotSymbol symbolToPlace;

      if (targetRow < newSymbols.length) {
        symbolToPlace = newSymbols[targetRow];
      } else {
        symbolToPlace = remainingSymbols[targetRow - newSymbols.length];
      }

      gridSymbols[targetRow][col] = symbolToPlace;

      final targetPosition = Vector2(
        gridStartX + col * (symbolSize + symbolSpacing),
        gridStartY + targetRow * (symbolSize + symbolSpacing),
      );

      symbolToPlace.setOriginalPosition(targetPosition);

      final delay = targetRow * 80;
      Future.delayed(Duration(milliseconds: delay), () {
        symbolToPlace.animateGravityDrop(targetPosition);
      });
    }
  }

  List<List<String>> getCurrentGrid() {
    return gridSymbols
        .map((row) => row.map((symbol) => symbol.currentSymbolPath).toList())
        .toList();
  }

  bool get isBuyFeatureRunning => isBuyFeatureActive;
  int get remainingBuyFeatureSpins => buyFeatureSpinsLeft;

  Future<void> startBuyFeatureFromScatter() async {
    _stopAllAnimations();
    isAnimating = false;

    isBuyFeatureActive = true;
    buyFeatureSpinsLeft = 10;
    _buyFeatureTotalWin = 0.0;
    print('🎁 BUY FEATURE запущено через Scatter символи!');

    await activateBuyFeature();
  }

  void _stopAllAnimations() {
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final symbol = gridSymbols[row][col];
        symbol.removeAll(symbol.children.whereType<Effect>());
        symbol.position = symbol.originalPosition.clone();
        symbol.scale = Vector2.all(1.0);
        symbol.opacity = 1.0;
        symbol.angle = 0;
      }
    }
  }

  void addToBuyFeatureWin(double winAmount) {
    if (isBuyFeatureActive) {
      _buyFeatureTotalWin += winAmount;
      print(
        '💰 Додано до buy feature: \$${winAmount.toStringAsFixed(2)}, загалом: \$${_buyFeatureTotalWin.toStringAsFixed(2)}',
      );
    }
  }

  String _getWinType(double winAmount) {
    double baseStake = 2.50;
    double multiplier = winAmount / baseStake;

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
}

class SlotSymbol extends SpriteComponent with HasGameRef<SlotAnimationGame> {
  String currentSymbolPath = '';
  late Vector2 originalPosition;

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  void setOriginalPosition(Vector2 pos) {
    originalPosition = pos.clone();
  }

  Future<void> setSymbol(String symbolPath) async {
    currentSymbolPath = symbolPath;
    sprite = await Sprite.load(symbolPath.replaceAll('assets/images/', ''));
  }

  void animateOut({double speedMultiplier = 1.0}) {
    final duration = 0.8 / speedMultiplier;

    final moveEffect = MoveToEffect(
      Vector2(position.x, position.y + 600),
      EffectController(duration: duration, curve: Curves.easeIn),
    );

    final scaleEffect = ScaleEffect.to(
      Vector2.all(0.5),
      EffectController(duration: duration, curve: Curves.easeIn),
    );

    final opacityEffect = OpacityEffect.to(
      0.3,
      EffectController(duration: duration, curve: Curves.easeIn),
    );

    add(moveEffect);
    add(scaleEffect);
    add(opacityEffect);
  }

  void animateIn({double speedMultiplier = 1.0}) {
    final startY = originalPosition.y - 550;
    position = Vector2(originalPosition.x, startY);
    scale = Vector2.all(0.8);
    opacity = 1.0;
    angle = 0;

    final moveDuration = 0.8 / speedMultiplier;
    final scaleDuration = 0.6 / speedMultiplier;
    final shakeDuration = 0.12 / speedMultiplier;
    final shakeDelay = 0.68 / speedMultiplier;

    final moveEffect = MoveToEffect(
      originalPosition.clone(),
      EffectController(duration: moveDuration, curve: Curves.easeOut),
    );

    final scaleEffect = ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: scaleDuration, curve: Curves.easeOutBack),
    );

    final shakeEffect = MoveByEffect(
      Vector2(0, -5),
      EffectController(
        duration: shakeDuration,
        curve: Curves.bounceOut,
        startDelay: shakeDelay,
      ),
    );

    add(moveEffect);
    add(scaleEffect);
    add(shakeEffect);

    moveEffect.onComplete = () {
      position = originalPosition.clone();
      scale = Vector2.all(1.0);
    };
  }

  void animateWinOut() {
    final scaleEffect = ScaleEffect.to(
      Vector2.all(1.3),
      EffectController(duration: 0.1, curve: Curves.easeOut),
    );

    final fadeEffect = ScaleEffect.to(
      Vector2.zero(),
      EffectController(duration: 0.3, curve: Curves.easeIn, startDelay: 0.1),
    );

    final flashEffect = OpacityEffect.fadeOut(
      EffectController(duration: 0.4, curve: Curves.easeInOut),
    );

    add(scaleEffect);
    add(fadeEffect);
    add(flashEffect);
  }

  void animateGravityDrop(Vector2 targetPosition) {
    angle = 0;

    final moveEffect = MoveToEffect(
      targetPosition.clone(),
      EffectController(duration: 0.6, curve: Curves.easeOut),
    );

    final shakeEffect = MoveByEffect(
      Vector2(0, -3),
      EffectController(duration: 0.1, curve: Curves.bounceOut, startDelay: 0.5),
    );

    add(moveEffect);
    add(shakeEffect);

    moveEffect.onComplete = () {
      position = targetPosition.clone();
      originalPosition = targetPosition.clone();
    };
  }

  void animateWinIn() {
    final startY = originalPosition.y - 200;
    position = Vector2(originalPosition.x, startY);
    scale = Vector2.all(0.5);
    opacity = 1.0;
    angle = 0;

    final moveEffect = MoveToEffect(
      originalPosition.clone(),
      EffectController(duration: 0.5, curve: Curves.bounceOut),
    );

    final scaleEffect = ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.4, curve: Curves.elasticOut),
    );

    add(moveEffect);
    add(scaleEffect);

    moveEffect.onComplete = () {
      position = originalPosition.clone();
    };
  }
}
