import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_test_task/animations/slot_animation.dart';

class SlotAnimationWidget extends StatefulWidget {
  final Function(List<List<String>>)? onAnimationComplete;
  final Function(Map<String, int>)? onWinningsFound;
  final Function(List<String>)? onMultipliersFound;
  final Function()? onSpinComplete;
  final Function(double, String)? onBuyFeatureComplete;
  final Function(double)? onBuyFeatureWinAccumulate;
  final Function(SlotAnimationGame)? onGameReady;
  final Function(int)? onScatterCallback;
  final Function(int)?
  onBuyFeatureSpinsUpdate; // Новий callback для оновлення лічильника спінів
  final bool shouldAnimate;
  final bool shouldBuyFeature;

  const SlotAnimationWidget({
    super.key,
    this.onAnimationComplete,
    this.onWinningsFound,
    this.onMultipliersFound,
    this.onSpinComplete,
    this.onBuyFeatureComplete,
    this.onBuyFeatureWinAccumulate,
    this.onGameReady,
    this.onScatterCallback,
    this.onBuyFeatureSpinsUpdate,
    this.shouldAnimate = false,
    this.shouldBuyFeature = false,
  });

  @override
  State<SlotAnimationWidget> createState() => _SlotAnimationWidgetState();
}

class _SlotAnimationWidgetState extends State<SlotAnimationWidget> {
  late SlotAnimationGame game;
  bool hasAnimated = false;
  bool hasBuyFeatureActivated = false;

  SlotAnimationGame get animationGame => game;
  @override
  void initState() {
    super.initState();
    game = SlotAnimationGame();

    game.onWinningsCallback = widget.onWinningsFound;
    game.onMultipliersCallback = widget.onMultipliersFound;
    game.onSpinCompleteCallback = widget.onSpinComplete;
    game.onBuyFeatureComplete = (totalWin, winType) {
      // Скидаємо прапор після завершення buy feature
      hasBuyFeatureActivated = false;
      print('🎁 Buy feature завершено, скидаємо hasBuyFeatureActivated');

      // Викликаємо оригінальний callback тільки якщо віджет ще змонтований
      if (mounted && widget.onBuyFeatureComplete != null) {
        widget.onBuyFeatureComplete!(totalWin, winType);
      } else {
        print(
          '⚠️ Buy feature завершено, але віджет вже знищений - callback пропущено',
        );
      }
    };
    print(
      '🎯 onBuyFeatureComplete встановлено: ${widget.onBuyFeatureComplete != null}',
    );
    game.onScatterCallback = widget.onScatterCallback;
    game.onBuyFeatureSpinsUpdate = widget.onBuyFeatureSpinsUpdate;

    game.onBuyFeatureWinAccumulate = (winAmount) {
      game.addToBuyFeatureWin(winAmount);
      if (mounted && widget.onBuyFeatureWinAccumulate != null) {
        widget.onBuyFeatureWinAccumulate!(winAmount);
      }
    };

    if (widget.onGameReady != null) {
      widget.onGameReady!(game);
    }

    // Завжди використовуємо максимальну швидкість
    game.setAnimationSettings(useQuick: true, speedMultiplier: 2.0);
  }

  @override
  void didUpdateWidget(SlotAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Завжди використовуємо максимальну швидкість
    game.setAnimationSettings(useQuick: true, speedMultiplier: 2.0);

    if (widget.shouldBuyFeature && !hasBuyFeatureActivated) {
      print('🎁 shouldBuyFeature=true, запускаємо buy feature');
      hasBuyFeatureActivated = true;
      _startBuyFeature();
    } else if (!widget.shouldBuyFeature) {
      print('🎁 shouldBuyFeature=false, скидаємо hasBuyFeatureActivated');
      hasBuyFeatureActivated = false;
    }

    if (widget.shouldAnimate && !hasAnimated) {
      hasAnimated = true;
      _startAnimation();
    } else if (!widget.shouldAnimate) {
      hasAnimated = false;
    }
  }

  Future<void> _startBuyFeature() async {
    print(
      '🎁 _startBuyFeature викликано, hasBuyFeatureActivated=$hasBuyFeatureActivated',
    );
    await Future.delayed(
      const Duration(milliseconds: 50),
    ); // Прискорено з 100 до 50ms
    await game.activateBuyFeature();

    if (widget.onAnimationComplete != null) {
      final currentGrid = game.getCurrentGrid();
      widget.onAnimationComplete!(currentGrid);
    }
  }

  Future<void> _startAnimation() async {
    await Future.delayed(
      const Duration(milliseconds: 50),
    ); // Прискорено з 100 до 50ms
    await game.startSpinAnimation();

    if (widget.onAnimationComplete != null) {
      final currentGrid = game.getCurrentGrid();
      widget.onAnimationComplete!(currentGrid);
    }
  }

  void resetFlags() {
    print('🎁 Скидання прапорів анімації');
    hasAnimated = false;
    hasBuyFeatureActivated = false;
  }

  @override
  void dispose() {
    print('🎁 SlotAnimationWidget dispose - скидаємо прапори');
    hasAnimated = false;
    hasBuyFeatureActivated = false;

    // Очищуємо всі callbacks щоб уникнути викликів після dispose
    game.onWinningsCallback = null;
    game.onMultipliersCallback = null;
    game.onSpinCompleteCallback = null;
    game.onBuyFeatureComplete = null;
    game.onBuyFeatureWinAccumulate = null;
    game.onScatterCallback = null;
    game.onBuyFeatureSpinsUpdate = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GameWidget(game: game),
    );
  }
}
