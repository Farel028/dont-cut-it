import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioService _audio = AudioService();
  final StorageService _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07140B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2818),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "SETTINGS & CONTROLS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Audio Settings Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F311E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.volume_up_rounded, color: Color(0xFFFFD54F), size: 22),
                          SizedBox(width: 10),
                          Text(
                            "AUDIO & SOUNDSCAPE",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // BGM Volume Slider
                      Row(
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text("BGM (Ambient):", style: TextStyle(color: Color(0xFFC8E6C9), fontSize: 13)),
                          ),
                          Expanded(
                            child: Slider(
                              value: _audio.bgmVolume,
                              min: 0.0,
                              max: 1.0,
                              activeColor: const Color(0xFF00E676),
                              inactiveColor: Colors.black45,
                              onChanged: (v) {
                                setState(() {
                                  _audio.setBgmVolume(v);
                                  _storage.bgmVolume = v;
                                });
                              },
                            ),
                          ),
                          Text(
                            "${(_audio.bgmVolume * 100).toInt()}%",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      // SFX Volume Slider
                      Row(
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text("SFX (Effects):", style: TextStyle(color: Color(0xFFC8E6C9), fontSize: 13)),
                          ),
                          Expanded(
                            child: Slider(
                              value: _audio.sfxVolume,
                              min: 0.0,
                              max: 1.0,
                              activeColor: const Color(0xFFFFD54F),
                              inactiveColor: Colors.black45,
                              onChanged: (v) {
                                setState(() {
                                  _audio.setSfxVolume(v);
                                  _storage.sfxVolume = v;
                                });
                              },
                            ),
                          ),
                          Text(
                            "${(_audio.sfxVolume * 100).toInt()}%",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Gameplay & Display Settings Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F311E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: Color(0xFFFFD54F), size: 22),
                          SizedBox(width: 10),
                          Text(
                            "GAMEPLAY & DISPLAY",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Screen Shake
                      SwitchListTile(
                        title: const Text("Combat Screen Shake", style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: const Text("Visual pulse during machinery destruction", style: TextStyle(color: Color(0xFFA5D6A7), fontSize: 11)),
                        value: _storage.screenShake,
                        activeTrackColor: const Color(0xFF00E676),
                        activeThumbColor: Colors.white,
                        onChanged: (v) {
                          setState(() => _storage.screenShake = v);
                        },
                      ),

                      // Fullscreen mode
                      SwitchListTile(
                        title: const Text("16:9 Cinema Letterbox", style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: const Text("Lock canvas to widescreen landscape ratio", style: TextStyle(color: Color(0xFFA5D6A7), fontSize: 11)),
                        value: _storage.isFullscreen,
                        activeTrackColor: const Color(0xFF00E676),
                        activeThumbColor: Colors.white,
                        onChanged: (v) {
                          setState(() => _storage.isFullscreen = v);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Reset Progress Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1312),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.restart_alt_rounded, color: Color(0xFFEF5350), size: 22),
                          SizedBox(width: 10),
                          Text(
                            "DATA & PROGRESS",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Clear unlocked levels, high scores, and saved seeds.",
                        style: TextStyle(color: Color(0xFFFFCDD2), fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          _storage.resetProgress();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Campaign progress has been reset to Stage 1."),
                              backgroundColor: Color(0xFF2E7D32),
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_forever_rounded),
                        label: const Text("RESET GAME PROGRESS"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
