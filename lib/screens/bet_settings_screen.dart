import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test_task/viewmodels/game_slot_viewmodel.dart';

class BetSettingsDialog {
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _BetSettingsDialogWidget(),
    );
  }
}

class _BetSettingsDialogWidget extends StatefulWidget {
  const _BetSettingsDialogWidget();

  @override
  State<_BetSettingsDialogWidget> createState() =>
      _BetSettingsDialogWidgetState();
}

class _BetSettingsDialogWidgetState extends State<_BetSettingsDialogWidget> {
  static const List<int> betValues = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const List<double> coinValues = [0.01, 0.03, 0.10, 0.20, 0.50];
  static const List<double> totalBetValues = [
    0.20,
    0.40,
    0.60,
    0.80,
    1.20,
    1.40,
    1.60,
    1.80,
    2.40,
    3.0,
    3.60,
    4.0,
    4.20,
    4.80,
    5.0,
    5.4,
    6.0,
    7,
    8,
    9,
    10,
    12,
    14,
    16,
    18,
    20,
    24,
    28,
    30,
    32,
    36,
    40,
    50,
    60,
    70,
    80,
    90,
    100,
  ];

  int currentBetIndex = 0;
  int currentCoinIndex = 0;
  int currentTotalBetIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeFromViewModel();
  }

  void _initializeFromViewModel() {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );

    currentTotalBetIndex = _findClosestIndex(
      totalBetValues,
      gameViewModel.betAmount,
    );
    currentBetIndex = 4;
    currentCoinIndex = 2;
  }

  int _findClosestIndex(List<double> values, double target) {
    int closestIndex = 0;
    double minDifference = (values[0] - target).abs();

    for (int i = 1; i < values.length; i++) {
      double difference = (values[i] - target).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  void _updateTotalBet() {
    double calculatedBet =
        betValues[currentBetIndex] * coinValues[currentCoinIndex];
    currentTotalBetIndex = _findClosestIndex(totalBetValues, calculatedBet);

    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );
    gameViewModel.setBetAmount(totalBetValues[currentTotalBetIndex]);

    setState(() {});
  }

  void _updateTotalBetFromDirect() {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );
    gameViewModel.setBetAmount(totalBetValues[currentTotalBetIndex]);
    setState(() {});
  }

  void _setBetMax() {
    currentBetIndex = betValues.length - 1;
    currentCoinIndex = coinValues.length - 1;
    currentTotalBetIndex = totalBetValues.length - 1;

    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );
    gameViewModel.setBetAmount(totalBetValues[currentTotalBetIndex]);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.35,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1810), Color(0xFF4A2C1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A2C1A), Color(0xFF6B3D25)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BET MULTIPLIER 20x',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSettingRow(
                      'BET',
                      betValues[currentBetIndex].toString(),
                      () {
                        if (currentBetIndex > 0) {
                          currentBetIndex--;
                          _updateTotalBet();
                        }
                      },
                      () {
                        if (currentBetIndex < betValues.length - 1) {
                          currentBetIndex++;
                          _updateTotalBet();
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildSettingRow(
                      'COIN VALUE',
                      coinValues[currentCoinIndex].toStringAsFixed(2),
                      () {
                        if (currentCoinIndex > 0) {
                          currentCoinIndex--;
                          _updateTotalBet();
                        }
                      },
                      () {
                        if (currentCoinIndex < coinValues.length - 1) {
                          currentCoinIndex++;
                          _updateTotalBet();
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildSettingRow(
                      'TOTAL BET',
                      totalBetValues[currentTotalBetIndex].toStringAsFixed(2),
                      () {
                        if (currentTotalBetIndex > 0) {
                          currentTotalBetIndex--;
                          _updateTotalBetFromDirect();
                        }
                      },
                      () {
                        if (currentTotalBetIndex < totalBetValues.length - 1) {
                          currentTotalBetIndex++;
                          _updateTotalBetFromDirect();
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: _setBetMax,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.lightGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Text(
                            'BET MAX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    String title,
    String value,
    VoidCallback onDecrease,
    VoidCallback onIncrease,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onDecrease,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: const Icon(Icons.remove, color: Colors.black, size: 24),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            GestureDetector(
              onTap: onIncrease,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
