import 'package:flutter/material.dart';
import '../game/models/plants.dart';
import '../game/models/enemies.dart';

class AlmanacScreen extends StatefulWidget {
  const AlmanacScreen({super.key});

  @override
  State<AlmanacScreen> createState() => _AlmanacScreenState();
}

class _AlmanacScreenState extends State<AlmanacScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedFloraIndex = 0;
  int _selectedThreatIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          "TROPICAL RAINFOREST ALMANAC",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 1.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD54F),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFFD54F),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.spa_rounded), text: "INDONESIAN FLORA"),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: "DEFORESTATION THREATS"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFloraTab(),
            _buildThreatsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloraTab() {
    final flora = kPlantCatalog[_selectedFloraIndex];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Row(
          children: [
            // Left List of Plant Cards
            SizedBox(
              width: 280,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: kPlantCatalog.length,
                itemBuilder: (context, index) {
                  final plant = kPlantCatalog[index];
                  final isSelected = (_selectedFloraIndex == index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFloraIndex = index),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF102819),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF2E7D32),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(plant.iconEmoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plant.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    plant.scientificName,
                                    style: const TextStyle(
                                      color: Color(0xFFA5D6A7),
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Right Flora Botanical Detail Panel
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F311E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                            ),
                            child: Text(flora.iconEmoji, style: const TextStyle(fontSize: 48)),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flora.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  "${flora.indonesianName} (${flora.scientificName})",
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0x334CAF50),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    flora.status,
                                    style: const TextStyle(color: Color(0xFFC8E6C9), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Color(0x334CAF50)),
                      const SizedBox(height: 12),

                      // Botanical Lore & Conservation info
                      const Text(
                        "ECOLOGICAL PROFILE & ABOUT",
                        style: TextStyle(
                          color: Color(0xFFFFD54F),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        flora.about,
                        style: const TextStyle(color: Color(0xFFE8F5E9), fontSize: 13, height: 1.5),
                      ),

                      const SizedBox(height: 16),

                      // Game stats card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0x8805180E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat("ABILITY", "✦ ${flora.abilityName}"),
                            _buildStat("MAX HP", "♥ ${flora.maxHp.toInt()}"),
                            _buildStat("COOLDOWN", "⏱️ ${flora.cooldownSeconds}s"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatsTab() {
    final threat = kEnemyCatalog[_selectedThreatIndex];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Row(
          children: [
            // Left List of Threats
            SizedBox(
              width: 280,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: kEnemyCatalog.length,
                itemBuilder: (context, index) {
                  final enemy = kEnemyCatalog[index];
                  final isSelected = (_selectedThreatIndex == index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedThreatIndex = index),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFB71C1C) : const Color(0xFF1E1412),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF8A80) : const Color(0xFF5D4037),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text("🚜", style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    enemy.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    enemy.threatLevel,
                                    style: const TextStyle(color: Color(0xFFFFAB91), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Right Threat Detail Panel
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF261210),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEF5350), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3E1F1D),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFEF5350), width: 2),
                            ),
                            child: const Text("⚠️", style: TextStyle(fontSize: 48)),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  threat.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  threat.indonesianName,
                                  style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33EF5350),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    threat.threatLevel,
                                    style: const TextStyle(color: Color(0xFFFFCDD2), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Color(0x33EF5350)),
                      const SizedBox(height: 12),

                      const Text(
                        "DEFORESTATION IMPACT & METHOD",
                        style: TextStyle(
                          color: Color(0xFFFF8A80),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        threat.description,
                        style: const TextStyle(color: Color(0xFFFFEBEE), fontSize: 13, height: 1.5),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0x88150706),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat("ARMOR / HP", "🛡️ ${threat.maxHp.toInt()}"),
                            _buildStat("SPEED", "⚡ ${threat.speed.toStringAsFixed(0)} px/s"),
                            _buildStat("SEED DROP", "🌱 20% Chance"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
