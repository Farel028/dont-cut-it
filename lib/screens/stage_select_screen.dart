import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';

class StageSelectScreen extends StatelessWidget {
  const StageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();

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
          "DEFENSE SECTOR MAP",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F311E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Text("🌏", style: TextStyle(fontSize: 36)),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "INDONESIAN RAINFOREST BIODIVERSITY SANCTUMS",
                              style: TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Deploy Rafflesia and ancient botanical sentinels to halt illegal logging machinery across Sumatra, Kalimantan, and Papua.",
                              style: TextStyle(color: Color(0xFFC8E6C9), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stages List
                ...List.generate(kGameStages.length, (index) {
                  final config = kGameStages[index];
                  final stars = storage.stageStars[index] ?? 0;
                  final isUnlocked = (index == 0 || (storage.stageStars[index - 1] ?? 0) > 0 || index <= storage.completedStagesCount);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: isUnlocked ? const Color(0xFF133822) : const Color(0xFF15201A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isUnlocked ? const Color(0xFF4CAF50) : Colors.white12,
                        width: isUnlocked ? 2 : 1,
                      ),
                      boxShadow: isUnlocked
                          ? const [BoxShadow(color: Color(0x334CAF50), blurRadius: 14, offset: Offset(0, 4))]
                          : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Level Number Badge
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: isUnlocked ? const Color(0xFF2E7D32) : const Color(0xFF263238),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnlocked ? const Color(0xFFFFD54F) : Colors.white24,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: isUnlocked
                                ? Text(
                                    "${config.stageNumber}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                    ),
                                  )
                                : const Icon(Icons.lock_rounded, color: Colors.white38, size: 28),
                          ),

                          const SizedBox(width: 18),

                          // Stage Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      config.title,
                                      style: TextStyle(
                                        color: isUnlocked ? Colors.white : Colors.white54,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isUnlocked && stars > 0)
                                      Row(
                                        children: List.generate(3, (s) {
                                          return Icon(
                                            s < stars ? Icons.star_rounded : Icons.star_border_rounded,
                                            color: s < stars ? const Color(0xFFFFD54F) : Colors.white24,
                                            size: 20,
                                          );
                                        }),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${config.province} • ${config.biome}",
                                  style: const TextStyle(
                                    color: Color(0xFFA5D6A7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  config.educationalSnippet,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFE0E0E0),
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Play Button
                          if (isUnlocked)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameScreen(stageIndex: index),
                                  ),
                                );
                              },
                              child: const Row(
                                children: [
                                  Text("PLAY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                  SizedBox(width: 4),
                                  Icon(Icons.play_arrow_rounded, size: 20),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
