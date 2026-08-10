import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final audio = AudioService();
  final storage = StorageService()..load();
  audio
    ..setBgmVolume(storage.bgmEnabled ? storage.bgmVolume : 0)
    ..setSfxVolume(storage.sfxEnabled ? storage.sfxVolume : 0)
    ..init();
  runApp(const DontCutItApp());
}

class DontCutItApp extends StatelessWidget {
  const DontCutItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "DON'T CUT IT - Tropical Rainforest Lane Defense",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07140B),
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2E7D32),
          secondary: Color(0xFFFFD54F),
          surface: Color(0xFF0F2B1B),
        ),
        fontFamily: 'Montserrat',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE8F5E9)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
