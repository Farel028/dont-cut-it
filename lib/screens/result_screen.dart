import 'package:flutter/material.dart';
import '../game/game_state.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final bool isVictory;
  final int stageIndex;
  final int enemiesDefeated;
  final double deforestationPreventedHa;
  final int seedsCollected;
  final int sanctumHealthRemaining;

  const ResultScreen({
    super.key,
    required this.isVictory,
    required this.stageIndex,
    required this.enemiesDefeated,
    required this.deforestationPreventedHa,
    required this.seedsCollected,
    required this.sanctumHealthRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final stageConfig = kGameStages[stageIndex.clamp(0, kGameStages.length - 1)];
    final stars = isVictory ? (sanctumHealthRemaining == 3 ? 3 : (sanctumHealthRemaining == 2 ? 2 : 1)) : 0;
    final isLastStage = stageIndex >= kGameStages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF07140B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2B1B),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isVictory ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isVictory ? const Color(0x444CAF50) : const Color(0x44E53935),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji & Outcome Title
                  Text(
                    isVictory ? "🌺 🌳 🏆" : "🚜 ⚠️ 💔",
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVictory ? "SANCTUM DEFENDED!" : "CANOPY BREACHED",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: isVictory ? const Color(0xFF81C784) : const Color(0xFFFF8A80),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stageConfig.title,
                    style: const TextStyle(
                      color: Color(0xFFA5D6A7),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Star Rating (for victory)
                  if (isVictory)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final earned = i < stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            earned ? Icons.star_rounded : Icons.star_border_rounded,
                            color: earned ? const Color(0xFFFFD54F) : Colors.white24,
                            size: 42,
                          ),
                        );
                      }),
                    ),

                  const SizedBox(height: 18),

                  // Deforestation Prevention Stats Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xCC05180E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn("MACHINERY CRUSHED", "$enemiesDefeated", "🚜"),
                        Container(width: 1.5, height: 45, color: Colors.white24),
                        _buildStatColumn(
                          "FOREST SAVED",
                          "${deforestationPreventedHa.toStringAsFixed(1)} Ha",
                          "🌳",
                        ),
                        Container(width: 1.5, height: 45, color: Colors.white24),
                        _buildStatColumn("ECO-SEEDS", "$seedsCollected", "🌱"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Educational Message Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF163E27),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD54F), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "RAINFOREST ECOSYSTEM FACT",
                              style: TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stageConfig.educationalSnippet,
                          style: const TextStyle(
                            color: Color(0xFFE8F5E9),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Replay Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF81C784), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameScreen(stageIndex: stageIndex),
                                ),
                              );
                            },
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text("REPLAY", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Next Stage or Menu
                      if (isVictory && !isLastStage)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameScreen(stageIndex: stageIndex + 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text("NEXT STAGE", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.home_rounded),
                              label: const Text("HOME MENU", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String icon) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA5D6A7),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
