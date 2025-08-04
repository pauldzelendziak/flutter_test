import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test_task/viewmodels/game_slot_viewmodel.dart';
import 'package:flutter_test_task/widgets/slot_animation_widget.dart';
import 'package:flutter_test_task/screens/bet_settings_screen.dart';
import 'package:flutter_test_task/screens/autoplay_settings_screen.dart';
import 'package:flutter_test_task/screens/system_settings_screen.dart';
import 'package:flutter_test_task/animations/slot_animation.dart';
import 'package:flutter_test_task/services/audio_service.dart';
import 'package:flutter_test_task/services/storage_service.dart';
import 'dart:math' as math;

class SlotSpinScreen extends StatefulWidget {
  const SlotSpinScreen({super.key});

  @override
  State<SlotSpinScreen> createState() => _SlotSpinScreenState();
}

class _SlotSpinScreenState extends State<SlotSpinScreen>
    with TickerProviderStateMixin {
  bool _isSpinning = false;
  bool _shouldAnimate = false;
  double _currentWin = 0.0;
  bool _showWin = false;
  String _currentBackground = 'bg';
  bool _showBuyFeatureWin = false;
  double _buyFeatureWinAmount = 0.0;
  String _buyFeatureWinType = '';
  double _currentAnimatedWin = 0.0;
  late AnimationController _winAnimationController;
  late Animation<double> _winAnimation;
  SlotAnimationGame? _slotGame;

  @override
  void initState() {
    super.initState();
    _loadBackground();
    _winAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _winAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _winAnimationController, curve: Curves.easeInOut),
    );
    AudioService().playBackgroundMusic();
  }

  Future<void> _loadBackground() async {
    await StorageService().initialize();
    setState(() {
      _currentBackground = StorageService().loadSelectedBackground();
    });
  }

  @override
  void dispose() {
    _winAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/$_currentBackground.webp'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopSection(),
                  Expanded(child: _buildGameArea()),
                  _buildBottomSection(),
                ],
              ),
            ),
          ),

          Consumer<GameSlotViewModel>(
            builder: (context, gameViewModel, child) {
              if (!gameViewModel.showWin || gameViewModel.currentWin <= 0) {
                return const SizedBox.shrink();
              }

              return Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: gameViewModel.showWin ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'WIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 1,
                                  offset: Offset(0.5, 0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            gameViewModel.getWinDisplayText().replaceFirst(
                              'WIN ',
                              '',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 1,
                                  offset: Offset(0.5, 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_showBuyFeatureWin)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _skipWinAnimation();
                },
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/${_buyFeatureWinType}.png',
                          width: 200,
                          height: 100,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            '\$${_currentAnimatedWin.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 3,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Consumer<GameSlotViewModel>(
            builder: (context, gameViewModel, child) {
              // Показуємо AUTO кнопку лише якщо:
              // 1. Автоплей активний (запущений) АБО
              // 2. Автоплей був запущений раніше (hasAutoplayBeenStarted = true)
              if (gameViewModel.hasAutoplayBeenStarted ||
                  gameViewModel.isAutoplayActive) {
                if (!gameViewModel.isAutoplayActive) {
                  return GestureDetector(
                    onTap: () {
                      if (gameViewModel.autoplayCount > 0) {
                        AudioService().playClickSound();
                        gameViewModel.startAutoplay();
                        _startAutoplay();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        'AUTO ${gameViewModel.autoplayCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.red],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AUTO ${gameViewModel.currentAutoplayCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            AudioService().playClickSound();
                            gameViewModel.stopAutoplay();
                          },
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                return const SizedBox.shrink();
              }
            },
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer<GameSlotViewModel>(
                            builder: (context, gameViewModel, child) {
                              final canBuy = gameViewModel.canBuyFeature();
                              return GestureDetector(
                                onTap: canBuy
                                    ? () {
                                        AudioService().playClickSound();
                                        gameViewModel.buyFeature();
                                      }
                                    : null,
                                child: Container(
                                  width: 120,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: canBuy
                                          ? [Colors.orange, Colors.pink]
                                          : [Colors.grey, Colors.grey.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'BUY FEATURE',
                                        style: TextStyle(
                                          color: canBuy
                                              ? Colors.white
                                              : Colors.grey.shade400,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '\$${gameViewModel.buyFeaturePrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: canBuy
                                              ? Colors.white
                                              : Colors.grey.shade400,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (!canBuy &&
                                          gameViewModel.doubleChanceEnabled)
                                        Text(
                                          'DISABLED',
                                          style: TextStyle(
                                            color: Colors.red.shade300,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 8),
                          Consumer<GameSlotViewModel>(
                            builder: (context, gameViewModel, child) {
                              return GestureDetector(
                                onTap: () {
                                  AudioService().playClickSound();
                                  gameViewModel.toggleDoubleChance();
                                },
                                child: Container(
                                  width: 90,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.green, Colors.lightGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'BET',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '\$${gameViewModel.effectiveBetAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (gameViewModel.doubleChanceEnabled)
                                        Text(
                                          '(+25%)',
                                          style: TextStyle(
                                            color: Colors.yellow.shade300,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'DOUBLE\nCHANCE TO\nWIN FEATURE',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            gameViewModel.doubleChanceEnabled
                                                ? Icons.toggle_on
                                                : Icons.toggle_off,
                                            color:
                                                gameViewModel
                                                    .doubleChanceEnabled
                                                ? Colors.yellow
                                                : Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            gameViewModel.doubleChanceEnabled
                                                ? 'ON'
                                                : 'OFF',
                                            style: TextStyle(
                                              color:
                                                  gameViewModel
                                                      .doubleChanceEnabled
                                                  ? Colors.yellow
                                                  : Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _buildAnimatedSlotGrid()),
                      const SizedBox(width: 5),
                      Consumer<GameSlotViewModel>(
                        builder: (context, gameViewModel, child) {
                          final canSpin =
                              gameViewModel.canSpin() && !_isSpinning;
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(shape: BoxShape.circle),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(40),
                                onTap: canSpin
                                    ? () {
                                        AudioService().playClickSound();
                                        _startSpinAnimation();
                                      }
                                    : null,
                                child: Center(
                                  child: _isSpinning
                                      ? GestureDetector(
                                          onTap: () {
                                            AudioService().playClickSound();
                                            _stopAllAnimations();
                                          },
                                          child: Image.asset(
                                            'assets/images/stopbutton.png',
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Text(
                                                    'STOP',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: canSpin
                                                          ? Colors.white
                                                          : Colors
                                                                .grey
                                                                .shade400,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1,
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/images/spinbutton.png',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Text(
                                                  'SPIN',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: canSpin
                                                        ? Colors.white
                                                        : Colors.grey.shade400,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1,
                                                  ),
                                                );
                                              },
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.pink],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Text(
                          'WIN OVER 21,100X',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSpinAnimation() {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );
    if (!gameViewModel.canSpin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enought money to spin!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    gameViewModel.placeBet();

    setState(() {
      _isSpinning = true;
      _shouldAnimate = true;
      _currentWin = 0.0;
      _showWin = false;
    });
  }

  void _stopAllAnimations() {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );

    setState(() {
      _isSpinning = false;
      _shouldAnimate = false;
    });
    if (gameViewModel.isAutoplayActive) {
      gameViewModel.stopAutoplay();
    }
  }

  void _onAnimationComplete(List<List<String>> newGrid) {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );
    gameViewModel.updateSlotsFromAnimation(newGrid);

    setState(() {
      _isSpinning = false;
      _shouldAnimate = false;
    });
    if (_showWin && _currentWin > 0) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showWin = false;
            _currentWin = 0.0;
          });
        }
      });
    }
  }

  void _startAutoplay() async {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );

    while (gameViewModel.isAutoplayActive &&
        gameViewModel.currentAutoplayCount > 0) {
      if (!gameViewModel.canSpin()) {
        gameViewModel.stopAutoplay();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough money to auto-spin!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        break;
      }
      _startSpinAnimation();
      while (_isSpinning) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      gameViewModel.decrementAutoplayCount();
      final delay = gameViewModel.turboSpinEnabled
          ? 500
          : gameViewModel.quickSpinEnabled
          ? 1000
          : 1500;

      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  void _skipWinAnimation() {
    if (_winAnimationController.isAnimating) {
      _winAnimationController.stop();
      setState(() {
        _currentAnimatedWin = _buyFeatureWinAmount;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showBuyFeatureWin = false;
            _currentAnimatedWin = 0.0;
          });
          _winAnimationController.reset();
        }
      });
    }
  }

  void _showBuyFeatureWinAnimation(double totalWin, String winType) {
    AudioService().playBreakingSound();

    setState(() {
      _showBuyFeatureWin = true;
      _buyFeatureWinAmount = totalWin;
      _buyFeatureWinType = winType;
      _currentAnimatedWin = 0.0;
    });
    _winAnimation.addListener(() {
      setState(() {
        _currentAnimatedWin = _buyFeatureWinAmount * _winAnimation.value;
      });
    });
    _winAnimationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showBuyFeatureWin = false;
            _currentAnimatedWin = 0.0;
          });
          _winAnimationController.reset();
        }
      });
    });
  }

  void _toggleSpinSpeed() {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );

    if (!gameViewModel.quickSpinEnabled && !gameViewModel.turboSpinEnabled) {
      // Звичайний → Quick
      gameViewModel.setAutoplaySettings(
        autoplayCount: gameViewModel.autoplayCount,
        quickSpin: true,
        turboSpin: false,
      );
    } else if (gameViewModel.quickSpinEnabled &&
        !gameViewModel.turboSpinEnabled) {
      // Quick → Turbo
      gameViewModel.setAutoplaySettings(
        autoplayCount: gameViewModel.autoplayCount,
        quickSpin: false,
        turboSpin: true,
      );
    } else if (gameViewModel.turboSpinEnabled) {
      // Turbo → Звичайний
      gameViewModel.setAutoplaySettings(
        autoplayCount: gameViewModel.autoplayCount,
        quickSpin: false,
        turboSpin: false,
      );
    }
  }

  Widget _buildAnimatedSlotGrid() {
    return Consumer<GameSlotViewModel>(
      builder: (context, gameViewModel, child) {
        gameViewModel.onBuyFeatureWinAccumulate = (winAmount) {
          if (_slotGame != null) {
            _slotGame!.addToBuyFeatureWin(winAmount);
          }
        };
        final double screenWidth = MediaQuery.of(context).size.width;
        final double screenHeight = MediaQuery.of(context).size.height;
        final double availableWidth = screenWidth * 0.85;
        final double availableHeight = screenHeight * 0.85;
        final double gridItemSizeByWidth =
            (availableWidth - 40) / GameSlotViewModel.colCount;
        final double gridItemSizeByHeight =
            (availableHeight - 80) / GameSlotViewModel.rowCount;
        final double gridItemSize = math.min(
          gridItemSizeByWidth,
          gridItemSizeByHeight,
        );

        final double gridWidth = gridItemSize * GameSlotViewModel.colCount + 12;
        final double gridHeight =
            gridItemSize * GameSlotViewModel.rowCount + 12;

        return Center(
          child: Container(
            width: gridWidth,
            height: gridHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.transparent,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SlotAnimationWidget(
                shouldAnimate: _shouldAnimate,
                shouldBuyFeature: gameViewModel.shouldBuyFeature,
                useQuickAnimation: gameViewModel.shouldUseQuickAnimation(),
                animationSpeed: gameViewModel.getAnimationSpeedMultiplier(),
                onAnimationComplete: _onAnimationComplete,
                onWinningsFound: (winnings) {
                  gameViewModel.processWinnings(winnings);
                },
                onMultipliersFound: (multipliers) {
                  gameViewModel.processMultipliers(multipliers);
                },
                onSpinComplete: () {
                  gameViewModel.clearMultipliersAfterSpin();
                },
                onBuyFeatureComplete: (totalWin, winType) {
                  _showBuyFeatureWinAnimation(totalWin, winType);
                },
                onBuyFeatureWinAccumulate: (winAmount) {
                  final vm = Provider.of<GameSlotViewModel>(
                    context,
                    listen: false,
                  );
                  if (vm.onBuyFeatureWinAccumulate != null) {
                    vm.onBuyFeatureWinAccumulate!(winAmount);
                  }
                  print(
                    '💰 Накопичення виграшу buy feature: \$${winAmount.toStringAsFixed(2)}',
                  );
                },
                onScatterCallback: (scatterCount) {
                  print('🍭 Callback отримав $scatterCount scatter символів');
                  if (scatterCount >= 4) {
                    print('🎁 Запуск buy feature через scatter callback');
                    gameViewModel.triggerBuyFeatureFromScatter();
                  } else if (scatterCount <= -3) {
                    print('🎁 +5 фріспінів під час buy feature');
                  }
                },
                onGameReady: (game) {
                  _slotGame = game;
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 10),
                Consumer<GameSlotViewModel>(
                  builder: (context, gameViewModel, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'CREDIT ',
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '\$${gameViewModel.credit.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 2),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'BET ',
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '\$${gameViewModel.effectiveBetAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (gameViewModel.doubleChanceEnabled)
                                  TextSpan(
                                    text: ' (+25%)',
                                    style: TextStyle(
                                      color: Colors.yellow.shade300,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildSettingsButton('autoplaysettings.png'),
              const SizedBox(width: 12),
              _buildSettingsButton('spinspeedsettings.png'),
              const SizedBox(width: 12),
              _buildSettingsButton('betsettings.png'),
              const SizedBox(width: 12),
              _buildSettingsButton('mainsettings.png'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(String imageName) {
    return GestureDetector(
      onTap: () {
        AudioService().playClickSound();

        if (imageName == 'betsettings.png') {
          BetSettingsDialog.show(context);
        } else if (imageName == 'autoplaysettings.png') {
          AutoplaySettingsDialog.show(context, onStartAutoplay: _startAutoplay);
        } else if (imageName == 'spinspeedsettings.png') {
          _toggleSpinSpeed();
        } else if (imageName == 'mainsettings.png') {
          SystemSettingsDialog.show(context);
        }
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color.fromARGB(255, 140, 6, 250).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ClipOval(
          child: Consumer<GameSlotViewModel>(
            builder: (context, gameViewModel, child) {
              String speedIcon = imageName;
              if (imageName == 'spinspeedsettings.png') {
                if (gameViewModel.turboSpinEnabled) {
                  speedIcon = 'spinspeedsettingsturbo.png';
                } else if (gameViewModel.quickSpinEnabled) {
                  speedIcon = 'spinspeedsettingsquick.png';
                } else {
                  speedIcon = 'spinspeedsettings.png';
                }
              }

              return Image.asset(
                'assets/images/$speedIcon',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[600],
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
