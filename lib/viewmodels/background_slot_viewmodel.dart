import 'package:flutter/material.dart';
import 'package:flutter_test_task/models/candy_model.dart';
import 'dart:math';

class BackgroundSlotViewModel extends ChangeNotifier {
  static const int rowCount = 6;
  static const int colCount = 5;
  final List<String> candyImages = [
    'assets/images/candy1.png',
    'assets/images/candy2.png',
    'assets/images/candy3.png',
    'assets/images/candy4.png',
    'assets/images/candy5.png',
    'assets/images/candy6.png',
    'assets/images/candy7.png',
    'assets/images/candy8.png',
    'assets/images/candy9.png',
  ];

  late List<List<CandyModel?>> grid;
  late List<List<bool>> animatedCells;
  late List<List<bool>> explodingCells;
  final Random _random = Random();
  int _candyUniqueId = 0;

  BackgroundSlotViewModel() {
    _initGrid(empty: true);
    _startLoopingAnimation();
  }

  void _initGrid({bool empty = false}) {
    grid = List.generate(
      rowCount,
      (row) => List.generate(colCount, (col) => empty ? null : _randomCandy()),
    );
    animatedCells = List.generate(
      rowCount,
      (row) => List.generate(colCount, (col) => false),
    );
    explodingCells = List.generate(
      rowCount,
      (row) => List.generate(colCount, (col) => false),
    );
    notifyListeners();
  }

  CandyModel _randomCandy() {
    final image = candyImages[_random.nextInt(candyImages.length)];
    return CandyModel(id: _candyUniqueId++, imagePath: image);
  }

  Future<void> _playExplosion() async {
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        explodingCells[row][col] = true;
      }
    }
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        explodingCells[row][col] = false;
      }
    }
    notifyListeners();
  }

  void _clearGrid() {
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        grid[row][col] = null;
        animatedCells[row][col] = false;
      }
    }
    notifyListeners();
  }

  Future<void> _playFallInColumns() async {
    _clearGrid();
    await Future.delayed(const Duration(milliseconds: 250));
    for (int col = 0; col < colCount; col++) {
      for (int row = 0; row < rowCount; row++) {
        grid[row][col] = _randomCandy();
        animatedCells[row][col] = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 30));
      }
      await Future.delayed(const Duration(milliseconds: 60));
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _startLoopingAnimation() async {
    while (true) {
      await _playFallInColumns();
      await Future.delayed(const Duration(milliseconds: 600));
      await _playExplosion();
      await Future.delayed(const Duration(milliseconds: 200));
      _clearGrid();
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }
}
