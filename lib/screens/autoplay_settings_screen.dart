import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test_task/viewmodels/game_slot_viewmodel.dart';
import 'package:flutter_test_task/services/audio_service.dart';

class AutoplaySettingsDialog {
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onStartAutoplay,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          _AutoplaySettingsDialogWidget(onStartAutoplay: onStartAutoplay),
    );
  }
}

class _AutoplaySettingsDialogWidget extends StatefulWidget {
  final VoidCallback? onStartAutoplay;

  const _AutoplaySettingsDialogWidget({this.onStartAutoplay});

  @override
  State<_AutoplaySettingsDialogWidget> createState() =>
      _AutoplaySettingsDialogWidgetState();
}

class _AutoplaySettingsDialogWidgetState
    extends State<_AutoplaySettingsDialogWidget> {
  static const List<int> autoplaySteps = [10, 20, 30, 50, 70, 100, 500, 1000];
  bool _soundEnabled = true;
  double _musicVolume = 100.0;
  int selectedAutoplayCount = 10;
  @override
  void initState() {
    super.initState();
    _initializeFromViewModel();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final audioService = AudioService();
    setState(() {
      _soundEnabled = audioService.isSoundEnabled;
      _musicVolume = audioService.currentMusicVolume * 100.0;
    });
  }

  void _initializeFromViewModel() {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );
    selectedAutoplayCount = gameViewModel.autoplayCount;
  }

  void _applySettings() {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );

    gameViewModel.setAutoplaySettings(autoplayCount: selectedAutoplayCount);

    gameViewModel.startAutoplay();

    Navigator.of(context).pop();

    if (widget.onStartAutoplay != null) {
      widget.onStartAutoplay!();
    }
  }

  void _saveSettingsAndClose() {
    final gameViewModel = Provider.of<GameSlotViewModel>(
      context,
      listen: false,
    );

    gameViewModel.setAutoplaySettings(autoplayCount: selectedAutoplayCount);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1810), Color(0xFF4A2C1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.5),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  Image.asset(
                    'assets/images/autoplaysettings.webp',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.play_circle_outline,
                        color: Colors.amber,
                        size: 32,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AUTOPLAY SETTINGS',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (_soundEnabled) {
                        AudioService().playClickSound();
                      }
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NUMBER OF AUTOSPINS',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 0, 0, 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.green, Colors.lightGreen],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$selectedAutoplayCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.green,
                              inactiveTrackColor: Colors.grey,
                              thumbColor: Colors.green,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                              overlayColor: const Color.fromRGBO(
                                76,
                                175,
                                80,
                                0.5,
                              ),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: autoplaySteps
                                  .indexOf(selectedAutoplayCount)
                                  .toDouble(),
                              min: 0,
                              max: (autoplaySteps.length - 1).toDouble(),
                              divisions: autoplaySteps.length - 1,
                              onChanged: (value) {
                                setState(() {
                                  selectedAutoplayCount =
                                      autoplaySteps[value.round()];
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Видаляємо секцію налаштування швидкості, оскільки завжди використовуємо turbo spin
                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: _applySettings,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.lightGreen],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            'START AUTOPLAY ($selectedAutoplayCount)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
