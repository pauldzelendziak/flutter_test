import 'package:flutter/material.dart';

class CandyGrid extends StatelessWidget {
  final List<List<dynamic>> grid;
  final List<dynamic> animatedCells;
  final List<dynamic> explodingCells;

  const CandyGrid({
    Key? key,
    required this.grid,
    required this.animatedCells,
    required this.explodingCells,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(child: Text('CandyGrid Placeholder')),
    );
  }
}
