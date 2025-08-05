import 'package:flutter/material.dart';
import 'package:flutter_test_task/services/audio_service.dart';
import 'dart:async';

class BuyFeatureWinDialog {
  static Future<void> show(
    BuildContext context,
    double totalWin,
    String winType,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _BuyFeatureWinDialogWidget(totalWin: totalWin, winType: winType),
    );
  }
}

class _BuyFeatureWinDialogWidget extends StatefulWidget {
  final double totalWin;
  final String winType;

  const _BuyFeatureWinDialogWidget({
    required this.totalWin,
    required this.winType,
  });

  @override
  State<_BuyFeatureWinDialogWidget> createState() =>
      _BuyFeatureWinDialogWidgetState();
}

class _BuyFeatureWinDialogWidgetState extends State<_BuyFeatureWinDialogWidget>
    with TickerProviderStateMixin {
  late AnimationController _counterController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  double _currentDisplayWin = 0.0;
  bool _isAnimating = true;
  bool _hasPlayedSound = false;
  bool _wasCounterSkipped = false; // 👈 новий прапорець

  @override
  void initState() {
    super.initState();

    _counterController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _startAnimation();
  }

  void _startAnimation() {
    if (!_hasPlayedSound) {
      AudioService().playBreakingSound();
      _hasPlayedSound = true;
    }

    _fadeController.forward();
    _scaleController.forward();

    _counterController.addListener(() {
      setState(() {
        _currentDisplayWin = widget.totalWin * _counterController.value;
      });
    });

    _counterController.forward();
  }

  void _completeAnimation() {
    setState(() {
      _currentDisplayWin = widget.totalWin;
      _isAnimating = false;
    });
    _counterController.stop();
  }

  void _handleTap() {
    if (!_wasCounterSkipped) {
      // 👈 Перший тап — пришвидшує
      _completeAnimation();
      _wasCounterSkipped = true;
    } else {
      // 👈 Другий тап — закриває
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _counterController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color _getWinColor() {
    switch (widget.winType) {
      case 'grandiosewin':
        return Colors.purple;
      case 'megawin':
        return Colors.deepPurple;
      case 'epicwin':
        return Colors.indigo;
      case 'bigwin':
        return Colors.blue;
      case 'superwin':
        return Colors.cyan;
      case 'nicewin':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: FadeTransition(
            opacity: _fadeController,
            child: ScaleTransition(
              scale: _scaleController,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.1,
                height: MediaQuery.of(context).size.height * 0.67,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getWinColor().withOpacity(0.9),
                      _getWinColor().withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _getWinColor().withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Заголовок виграшу (зображення)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: SizedBox(
                        height: 130,
                        child: Image.asset(
                          'assets/images/${widget.winType}.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              'WIN TITLE IMAGE NOT FOUND',
                              style: TextStyle(color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ),
                    // Сума виграшу
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL WIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentDisplayWin.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 6,
                                    offset: Offset(3, 3),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
