import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class HomeAnimationGame extends FlameGame with HasGameReference {
  static const int gridRows = 5;
  static const int gridCols = 6;
  static const double symbolSize = 40.0;
  static const double symbolSpacing = 4.0;

  late double gridStartX;
  late double gridStartY;
  late List<List<HomeSymbol>> gridSymbols;
  bool isAnimating = false;
  bool _shouldContinueAnimation = true;

  static const List<String> candySymbols = [
    'assets/images/candy1.webp',
    'assets/images/candy2.webp',
    'assets/images/candy3.webp',
    'assets/images/candy4.webp',
    'assets/images/candy5.webp',
    'assets/images/candy6.webp',
    'assets/images/candy7.webp',
    'assets/images/candy8.webp',
    'assets/images/candy9.webp',
  ];

  static const List<String> multiplierSymbols = [
    'assets/images/multi1.webp',
    'assets/images/multi2.webp',
    'assets/images/multi4.webp',
    'assets/images/multi8.webp',
    'assets/images/multi20.webp',
    'assets/images/multi50.webp',
    'assets/images/multi100.webp',
  ];

  static const String scatterSymbol = 'assets/images/lolipop.webp';

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
      (row) => List.generate(gridCols, (col) => HomeSymbol()),
    );

    await _initializeGrid();
    _startBackgroundAnimation();
  }

  void stopBackgroundAnimation() {
    _shouldContinueAnimation = false;
  }

  void _startBackgroundAnimation() async {
    while (_shouldContinueAnimation) {
      if (!isAnimating) {
        await startSimpleAnimation();
      }
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  String _getRandomSymbol() {
    final random = math.Random();
    // Scatter 1% шанс для home screen
    if (random.nextDouble() < 0.01) {
      return scatterSymbol;
    }

    // 90% шанс на candy, 9% на multiplier
    if (random.nextDouble() < 0.9) {
      return candySymbols[random.nextInt(candySymbols.length)];
    } else {
      return multiplierSymbols[random.nextInt(multiplierSymbols.length)];
    }
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

  Future<void> startSimpleAnimation() async {
    if (isAnimating) return;
    isAnimating = true;
    await _animateSymbolsOut();
    await _animateSymbolsIn();
    isAnimating = false;
  }

  Future<void> _animateSymbolsOut() async {
    List<Future> animations = [];
    for (int col = 0; col < gridCols; col++) {
      final delay = col * 150;
      animations.add(
        Future.delayed(Duration(milliseconds: delay), () async {
          for (int row = 0; row < gridRows; row++) {
            final symbol = gridSymbols[row][col];
            symbol.animateOut();
          }
        }),
      );
    }
    await Future.wait(animations);
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  Future<void> _animateSymbolsIn() async {
    List<Future> animations = [];
    for (int col = 0; col < gridCols; col++) {
      final delay = col * 150;

      animations.add(
        Future.delayed(Duration(milliseconds: delay), () async {
          for (int row = 0; row < gridRows; row++) {
            final symbol = gridSymbols[row][col];
            final randomSymbol = _getRandomSymbol();
            await symbol.setSymbol(randomSymbol);
            final rowDelay = row * 50;
            Future.delayed(Duration(milliseconds: rowDelay), () {
              symbol.animateIn();
            });
          }
        }),
      );
    }
    await Future.wait(animations);
    await Future.delayed(const Duration(milliseconds: 1200));
  }

  List<List<String>> getCurrentGrid() {
    return gridSymbols
        .map((row) => row.map((symbol) => symbol.currentSymbolPath).toList())
        .toList();
  }
}

class HomeSymbol extends SpriteComponent
    with HasGameReference<HomeAnimationGame> {
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

  void animateOut() {
    const duration = 0.8;

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

  void animateIn() {
    final startY = originalPosition.y - 550;
    position = Vector2(originalPosition.x, startY);
    scale = Vector2.all(0.8);
    opacity = 1.0;
    angle = 0;

    const moveDuration = 0.8;
    const scaleDuration = 0.6;
    const shakeDuration = 0.12;
    const shakeDelay = 0.68;
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
}
