import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/background_slot_viewmodel.dart';
import '../widgets/candy_grid.dart';
import '../screens/slot_spin_screen.dart';

class SlotScreen extends StatefulWidget {
  const SlotScreen({Key? key}) : super(key: key);

  @override
  State<SlotScreen> createState() => _SlotScreenState();
}

class _SlotScreenState extends State<SlotScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Consumer<BackgroundSlotViewModel>(
                    builder: (context, vm, _) => CandyGrid(
                      grid: vm.grid,
                      animatedCells: vm.animatedCells,
                      explodingCells: vm.explodingCells,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SlotSpinScreen(),
                      ),
                    );
                  },
                  child: const Text('Spin'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
