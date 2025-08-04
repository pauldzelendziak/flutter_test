import 'package:flutter/material.dart';
import 'package:flutter_test_task/services/storage_service.dart';
import 'package:flutter_test_task/services/audio_service.dart';

class ShopDialog extends StatefulWidget {
  final double currentBalance;
  final Function(double newBalance, String selectedBackground) onPurchase;

  const ShopDialog({
    super.key,
    required this.currentBalance,
    required this.onPurchase,
  });

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  late double _balance;
  late String _selectedBackground;
  late List<String> _purchasedBackgrounds;

  final Map<String, int> _backgroundPrices = {
    'bg': 0,
    'bg2': 10000,
    'bg3': 15000,
    'bg4': 20000,
    'bg5': 25000,
    'bg6': 30000,
    'bg7': 35000,
    'bg8': 40000,
    'bg9': 45000,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _balance = widget.currentBalance;
    _selectedBackground = StorageService().loadSelectedBackground();
    _purchasedBackgrounds = StorageService().loadPurchasedBackgrounds();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.9),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildBalanceSection(),
            Expanded(child: _buildBackgroundsList()),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: Colors.white, size: 30),
          const SizedBox(width: 5),
          const Expanded(
            child: Text(
              'BACKGROUND SHOP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Container(
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.orange,
            size: 25,
          ),
          const SizedBox(width: 8),
          Text(
            'Balance: \$${_balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundsList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _backgroundPrices.length,
        itemBuilder: (context, index) {
          final bgName = _backgroundPrices.keys.elementAt(index);
          final price = _backgroundPrices[bgName]!;
          final isPurchased = _purchasedBackgrounds.contains(bgName);
          final isSelected = _selectedBackground == bgName;
          final canAfford = _balance >= price;

          return _buildBackgroundCard(
            bgName: bgName,
            price: price,
            isPurchased: isPurchased,
            isSelected: isSelected,
            canAfford: canAfford,
          );
        },
      ),
    );
  }

  Widget _buildBackgroundCard({
    required String bgName,
    required int price,
    required bool isPurchased,
    required bool isSelected,
    required bool canAfford,
  }) {
    return GestureDetector(
      onTap: () => _handleBackgroundTap(bgName, price, isPurchased),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.orange
                : isPurchased
                ? Colors.green
                : canAfford
                ? Colors.white.withOpacity(0.5)
                : Colors.red,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.orange.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/$bgName.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: _buildStatusIcon(isPurchased, isSelected),
              ),
              Positioned(
                bottom: 5,
                left: 5,
                right: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bgName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isPurchased) ...[
                      Text(
                        '\$${price}',
                        style: TextStyle(
                          color: canAfford ? Colors.green : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isPurchased, bool isSelected) {
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text(
          'SELECTED',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (isPurchased) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                AudioService().playClickSound();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBackgroundTap(String bgName, int price, bool isPurchased) {
    AudioService().playClickSound();

    if (isPurchased) {
      _selectBackground(bgName);
    } else {
      _attemptPurchase(bgName, price);
    }
  }

  void _selectBackground(String bgName) {
    setState(() {
      _selectedBackground = bgName;
    });
    StorageService().saveSelectedBackground(bgName);
    widget.onPurchase(_balance, bgName);
  }

  void _attemptPurchase(String bgName, int price) {
    if (_balance >= price) {
      setState(() {
        _balance -= price;
        _purchasedBackgrounds.add(bgName);
        _selectedBackground = bgName;
      });
      StorageService().saveCredit(_balance);
      StorageService().addPurchasedBackground(bgName);
      StorageService().saveSelectedBackground(bgName);

      widget.onPurchase(_balance, bgName);
    }
  }
}
