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
  final bool shouldAnimate;
  final bool shouldBuyFeature;
  final bool useQuickAnimation;
  final double animationSpeed;
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
    this.shouldAnimate = false,
    this.shouldBuyFeature = false,
    this.useQuickAnimation = false,
    this.animationSpeed = 1.0,
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
    game.onBuyFeatureWinCallback = widget.onBuyFeatureComplete;
    game.onScatterCallback = widget.onScatterCallback;

    game.onBuyFeatureWinAccumulate = (winAmount) {
      game.addToBuyFeatureWin(winAmount);
      if (widget.onBuyFeatureWinAccumulate != null) {
        widget.onBuyFeatureWinAccumulate!(winAmount);
      }
    };

    if (widget.onGameReady != null) {
      widget.onGameReady!(game);
    }

    game.setAnimationSettings(
      useQuick: widget.useQuickAnimation,
      speedMultiplier: widget.animationSpeed,
    );
  }

  @override
  void didUpdateWidget(SlotAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.useQuickAnimation != widget.useQuickAnimation ||
        oldWidget.animationSpeed != widget.animationSpeed) {
      game.setAnimationSettings(
        useQuick: widget.useQuickAnimation,
        speedMultiplier: widget.animationSpeed,
      );
    }

    if (widget.shouldBuyFeature && !hasBuyFeatureActivated) {
      hasBuyFeatureActivated = true;
      _startBuyFeature();
    } else if (!widget.shouldBuyFeature) {
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
    await Future.delayed(const Duration(milliseconds: 100));
    await game.activateBuyFeature();

    if (widget.onAnimationComplete != null) {
      final currentGrid = game.getCurrentGrid();
      widget.onAnimationComplete!(currentGrid);
    }
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await game.startSpinAnimation();

    if (widget.onAnimationComplete != null) {
      final currentGrid = game.getCurrentGrid();
      widget.onAnimationComplete!(currentGrid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GameWidget(game: game),
    );
  }
}
