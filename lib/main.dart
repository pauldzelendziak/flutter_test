import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test_task/viewmodels/background_slot_viewmodel.dart';
import 'package:flutter_test_task/viewmodels/game_slot_viewmodel.dart';
import 'package:flutter_test_task/services/audio_service.dart';
import 'package:flutter_test_task/services/storage_service.dart';
import 'package:flutter_test_task/screens/splash_screen.dart';
import 'package:flutter_test_task/screens/home_screen.dart';
import 'package:flutter_test_task/screens/slot_spin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().initialize();
  await AudioService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BackgroundSlotViewModel()),

        ChangeNotifierProvider(create: (context) => GameSlotViewModel()),
      ],

      child: MaterialApp(
        title: 'Slot Machine',

        theme: ThemeData(
          primarySwatch: Colors.blue,

          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

        initialRoute: '/',

        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/game': (context) => const SlotSpinScreen(),
        },
      ),
    );
  }
}
