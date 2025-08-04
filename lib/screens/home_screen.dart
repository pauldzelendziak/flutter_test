import 'package:flutter/material.dart';
import 'package:flutter_test_task/services/audio_service.dart';
import 'package:flutter_test_task/services/storage_service.dart';
import 'package:flutter_test_task/screens/slot_spin_screen.dart';
import 'package:flutter_test_task/animations/home_animation.dart';
import 'package:flutter_test_task/widgets/shop_dialog.dart';
import 'package:flame/game.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeAnimationGame _gameInstance;
  bool _isSpinButtonAnimating = false;
  String _currentBackground = 'bg';
  double _currentBalance = 100000.0;

  @override
  void initState() {
    super.initState();
    _gameInstance = HomeAnimationGame();
    _initializeData();
    _startSpinButtonAnimation();
  }

  Future<void> _initializeData() async {
    await StorageService().initialize();
    setState(() {
      _currentBackground = StorageService().loadSelectedBackground();
      _currentBalance = StorageService().loadCredit();
    });
  }

  @override
  void dispose() {
    _gameInstance.stopBackgroundAnimation();
    super.dispose();
  }

  void _startSpinButtonAnimation() async {
    while (mounted) {
      if (mounted) {
        setState(() {
          _isSpinButtonAnimating = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          _isSpinButtonAnimating = false;
        });
      }

      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/$_currentBackground.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),

              Expanded(child: _buildGameArea()),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildShopButton(),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  const Text(
                    'SWEET BONANZA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                        Shadow(
                          color: Colors.purple,
                          blurRadius: 15,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Balance: \$${_currentBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 5,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopButton() {
    return GestureDetector(
      onTap: _openShop,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.shopping_cart, color: Colors.white, size: 25),
      ),
    );
  }

  void _openShop() {
    AudioService().playClickSound();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShopDialog(
        currentBalance: _currentBalance,
        onPurchase: (newBalance, selectedBackground) {
          setState(() {
            _currentBalance = newBalance;
            _currentBackground = selectedBackground;
          });
        },
      ),
    );
  }

  Widget _buildGameArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(child: _buildSlotGrid()),
          const SizedBox(width: 8),
          _buildSpinButton(),
        ],
      ),
    );
  }

  Widget _buildSlotGrid() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final double availableWidth = screenWidth * 0.60;
    final double availableHeight = screenHeight * 0.95;

    final double gridWidth = availableWidth * 0.65;
    final double gridHeight = availableHeight * 0.9;

    return Container(
      width: gridWidth,
      height: gridHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: GameWidget<HomeAnimationGame>.controlled(
            gameFactory: () => _gameInstance,
          ),
        ),
      ),
    );
  }

  Widget _buildSpinButton() {
    final double buttonSize = _isSpinButtonAnimating ? 120.0 : 90.0;

    return SizedBox(
      width: 120,
      height: 120,
      child: Center(
        child: GestureDetector(
          onTap: () {
            AudioService().playClickSound();
            _gameInstance.stopBackgroundAnimation();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SlotSpinScreen()),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: _isSpinButtonAnimating ? 20 : 15,
                  spreadRadius: _isSpinButtonAnimating ? 5 : 3,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/spinbutton.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.red],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Center(
                    child: Text(
                      'SPIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const SizedBox.shrink(),
    );
  }
}
