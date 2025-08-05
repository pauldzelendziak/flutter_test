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
import 'package:flutter_test_task/widgets/buy_feature_confirm_dialog.dart';
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

  // Прапор для відстеження чи віджет знищується
  bool _isDisposing = false;

  // Для debouncing кнопки HOME
  DateTime? _lastHomeButtonPress;

  @override
  void initState() {
    super.initState();
    _lastHomeButtonPress = null; // Ініціалізуємо debounce змінну
    _loadBackground(); // Завантажуємо вибраний фон
    _winAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _winAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _winAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadBackground() async {
    await StorageService().initialize();
    if (mounted && !_isDisposing) {
      setState(() {
        _currentBackground = StorageService().loadSelectedBackground();
      });
      print(
        '🎨 Вибраний фон завантажено на slot_spin_screen: $_currentBackground',
      );
    }
  }

  @override
  void dispose() {
    print('🗑️ Disposing SlotSpinScreen...');

    // Встановлюємо прапор що віджет знищується
    _isDisposing = true;

    // Зупиняємо автоплей якщо він активний
    try {
      final gameViewModel = Provider.of<GameSlotViewModel>(
        context,
        listen: false,
      );
      if (gameViewModel.isAutoplayActive) {
        gameViewModel.stopAutoplay();
        print('🛑 Автоплей зупинено в dispose');
      }
    } catch (e) {
      print('⚠️ Помилка зупинки автоплей в dispose: $e');
    }

    // Зупиняємо всі анімації контролера
    if (_winAnimationController.isAnimating) {
      _winAnimationController.stop();
    }

    // Видаляємо всі listeners перед dispose
    _winAnimation.removeListener(() {});

    // Dispose animation controller
    _winAnimationController.dispose();

    // Зупиняємо всі анімації слотів якщо вони ще активні
    if (_slotGame != null) {
      try {
        _slotGame!.stopAllAnimations();
      } catch (e) {
        print('⚠️ Помилка при зупинці анімацій в dispose: $e');
      }
    }

    print('✅ SlotSpinScreen disposed');
    super.dispose();
  }

  Future<void> _returnToHomeScreen() async {
    // Перевіряємо чи вже починається процес повернення
    if (_isDisposing) {
      print('⚠️ Повернення вже в процесі, ігноруємо повторний виклик');
      return;
    }

    // Debounce - перевіряємо чи минула секунда з останнього натискання
    final now = DateTime.now();
    if (_lastHomeButtonPress != null &&
        now.difference(_lastHomeButtonPress!).inMilliseconds < 1000) {
      print('⚠️ Кнопка натиснута занадто швидко, ігноруємо');
      return;
    }
    _lastHomeButtonPress = now;

    print('🏠 Повернення на головний екран...');

    // Відтворюємо звук кліку СПОЧАТКУ
    AudioService().playClickSound();

    // ОДРАЗУ робимо навігацію перед будь-якими іншими операціями
    if (mounted) {
      print('🏠 Навігація на головний екран...');
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
      print('✅ Навігація завершена');
    }

    // Тепер встановлюємо прапор що віджет знищується
    _isDisposing = true;

    // Отримуємо GameSlotViewModel для зупинки всіх процесів
    try {
      final gameViewModel = Provider.of<GameSlotViewModel>(
        context,
        listen: false,
      );

      // СПОЧАТКУ зупиняємо автоплей якщо він активний
      if (gameViewModel.isAutoplayActive) {
        gameViewModel.stopAutoplay();
        print('🛑 Автоплей зупинено');
      }
    } catch (e) {
      print('⚠️ Помилка при отриманні GameSlotViewModel: $e');
    }

    // Зупиняємо всі анімації та спіни
    if (mounted) {
      setState(() {
        _isSpinning = false;
        _shouldAnimate = false;
        _showWin = false;
        _currentWin = 0.0;
        _showBuyFeatureWin = false;
        _buyFeatureWinAmount = 0.0;
        _currentAnimatedWin = 0.0;
      });
    }

    // Зупиняємо всі анімації контролера
    if (_winAnimationController.isAnimating) {
      _winAnimationController.stop();
      _winAnimationController.reset();
    }

    // Видаляємо всі listeners з анімації щоб уникнути setState після dispose
    _winAnimation.removeListener(() {});

    // Зупиняємо анімації слотів через SlotGame
    if (_slotGame != null) {
      try {
        _slotGame!.stopAllAnimations();
        print('🎰 Всі анімації слотів зупинено');
      } catch (e) {
        print('⚠️ Помилка при зупинці анімацій слотів: $e');
      }
    }

    // НЕ зупиняємо фонову музику тут - HomeScreen сам її керуватиме
    print('🎵 Залишаємо фонову музику для HomeScreen');
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
                    duration: const Duration(
                      milliseconds: 300,
                    ), // Прискорено з 500 до 300ms
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
                          'assets/images/${_buyFeatureWinType}.webp',
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
          // Кнопка повернення на домашній екран
          GestureDetector(
            onTap: _isDisposing
                ? null
                : _returnToHomeScreen, // Відключаємо кнопку якщо вже відбувається повернення
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDisposing
                      ? [
                          Colors.grey,
                          Colors.grey.shade600,
                        ] // Сіра якщо відключена
                      : [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home,
                    color: _isDisposing ? Colors.grey.shade400 : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'HOME',
                    style: TextStyle(
                      color: _isDisposing ? Colors.grey.shade400 : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        // Зайва `)` та `,` були видалені тут
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
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
                                  ? () async {
                                      AudioService().playClickSound();
                                      final confirmed =
                                          await BuyFeatureConfirmDialog.show(
                                            context,
                                            gameViewModel.buyFeaturePrice,
                                            () {
                                              gameViewModel.buyFeature();
                                            },
                                          );
                                      if (confirmed == false) {
                                        print(
                                          '❌ Користувач скасував Buy Feature',
                                        );
                                      }
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
                                            ? const Color.fromARGB(
                                                255,
                                                245,
                                                241,
                                                13,
                                              )
                                            : Colors.grey.shade400,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      gameViewModel.buyFeaturePrice
                                          .toStringAsFixed(0),
                                      style: TextStyle(
                                        color: canBuy
                                            ? const Color.fromARGB(
                                                255,
                                                81,
                                                245,
                                                16,
                                              )
                                            : Colors.grey.shade400,
                                        fontSize: 14,
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
                                        color: Color.fromRGBO(245, 241, 13, 1),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      gameViewModel.effectiveBetAmount
                                          .toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: Color.fromRGBO(81, 245, 16, 1),
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
                                        color: Color.fromRGBO(245, 241, 13, 1),
                                        fontSize: 10,
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
                                              gameViewModel.doubleChanceEnabled
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
                        final canSpin = gameViewModel.canSpin() && !_isSpinning;
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
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
                                                        : Colors.grey.shade400,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startSpinAnimation() {
    if (_isDisposing) return; // Перевірка перед початком

    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );
    if (!gameViewModel.canSpin()) {
      if (mounted && !_isDisposing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enought money to spin!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2), // Прискорено з 2 до 1.5 секунд
          ),
        );
      }
      return;
    }
    gameViewModel.placeBet();

    if (mounted && !_isDisposing) {
      setState(() {
        _isSpinning = true;
        _shouldAnimate = true;
        _currentWin = 0.0;
        _showWin = false;
      });
    }
  }

  void _stopAllAnimations() {
    if (_isDisposing) return; // Перевірка перед початком

    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );

    if (mounted && !_isDisposing) {
      setState(() {
        _isSpinning = false;
        _shouldAnimate = false;
      });
    }
    if (gameViewModel.isAutoplayActive) {
      gameViewModel.stopAutoplay();
    }
  }

  void _onAnimationComplete(List<List<String>> newGrid) {
    if (_isDisposing) return; // Перевірка перед початком

    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );
    gameViewModel.updateSlotsFromAnimation(newGrid);

    if (mounted && !_isDisposing) {
      setState(() {
        _isSpinning = false;
        _shouldAnimate = false;
      });
    }
    if (_showWin && _currentWin > 0) {
      Future.delayed(const Duration(seconds: 2), () {
        // Прискорено з 3 до 2 секунд
        if (mounted && !_isDisposing) {
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
        gameViewModel.currentAutoplayCount > 0 &&
        mounted &&
        !_isDisposing) {
      // Додали перевірку _isDisposing
      if (!gameViewModel.canSpin()) {
        gameViewModel.stopAutoplay();

        // Перевіряємо mounted і _isDisposing перед використанням context
        if (mounted && !_isDisposing) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Not enough money to auto-spin!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2), // Прискорено з 2 до 1.5 секунд
            ),
          );
        }
        break;
      }

      // Перевіряємо mounted і _isDisposing перед спіном
      if (!mounted || _isDisposing) break;

      _startSpinAnimation();

      while (_isSpinning && mounted && !_isDisposing) {
        // Додали перевірку _isDisposing
        await Future.delayed(
          const Duration(milliseconds: 50),
        ); // Прискорено з 100 до 50ms
      }

      // Перевіряємо mounted і _isDisposing перед наступними операціями
      if (!mounted || _isDisposing || !gameViewModel.isAutoplayActive) break;

      gameViewModel.decrementAutoplayCount();
      final delay = 300; // Прискорено з 500 до 300ms

      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  void _skipWinAnimation() {
    if (_isDisposing) return; // Перевірка перед початком

    if (_winAnimationController.isAnimating) {
      _winAnimationController.stop();
      if (mounted && !_isDisposing) {
        setState(() {
          _currentAnimatedWin = _buyFeatureWinAmount;
        });
      }
      Future.delayed(const Duration(milliseconds: 300), () {
        // Прискорено з 500 до 300ms
        if (mounted && !_isDisposing) {
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
    // Перевіряємо чи віджет ще змонтований перед початком анімації
    if (!mounted || _isDisposing) return;

    AudioService().playBreakingSound();

    if (mounted && !_isDisposing) {
      setState(() {
        _showBuyFeatureWin = true;
        _buyFeatureWinAmount = totalWin;
        _buyFeatureWinType = winType;
        _currentAnimatedWin = 0.0;
      });
    }

    // Створюємо listener для анімації з перевіркою mounted
    void animationListener() {
      if (mounted && !_isDisposing) {
        setState(() {
          _currentAnimatedWin = _buyFeatureWinAmount * _winAnimation.value;
        });
      }
    }

    _winAnimation.addListener(animationListener);

    _winAnimationController.forward().then((_) {
      // Видаляємо listener після завершення анімації
      _winAnimation.removeListener(animationListener);

      Future.delayed(const Duration(seconds: 2), () {
        // Прискорено з 3 до 2 секунд
        if (mounted && !_isDisposing) {
          setState(() {
            _showBuyFeatureWin = false;
            _currentAnimatedWin = 0.0;
          });
          _winAnimationController.reset();
        }
      });
    });
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
              color: const Color.fromARGB(123, 39, 167, 176),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SlotAnimationWidget(
                shouldAnimate: _shouldAnimate,
                shouldBuyFeature: gameViewModel.shouldBuyFeature,
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
                        color: const Color.fromARGB(158, 176, 112, 39),
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
                                  text: gameViewModel.credit.toStringAsFixed(2),
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
                                  text: gameViewModel.effectiveBetAmount
                                      .toStringAsFixed(2),
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
              _buildSettingsButton('autoplaysettings.webp'),
              const SizedBox(width: 12),
              _buildSettingsButton('betsettings.webp'),
              const SizedBox(width: 12),
              _buildSettingsButton('mainsettings.webp'),
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

        if (imageName == 'betsettings.webp') {
          BetSettingsDialog.show(context);
        } else if (imageName == 'autoplaysettings.webp') {
          AutoplaySettingsDialog.show(context, onStartAutoplay: _startAutoplay);
        } else if (imageName == 'mainsettings.webp') {
          SystemSettingsDialog.show(context);
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color.fromARGB(255, 140, 6, 250).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/$imageName',
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
          ),
        ),
      ),
    );
  }
}
