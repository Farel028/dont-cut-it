import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';
import 'models/entity.dart';
import 'models/plants.dart';
import 'models/enemies.dart';
import 'models/projectiles.dart';
import 'models/seed_drop.dart';
import 'models/particle.dart';

enum GameStatus { ready, playing, paused, victory, defeat }

class GameStageConfig {
  final int stageNumber;
  final String title;
  final String province;
  final String biome;
  final int totalWaves;
  final int targetScore;
  final List<EnemyType> allowedEnemies;
  final double spawnIntervalSeconds;
  final String educationalSnippet;

  const GameStageConfig({
    required this.stageNumber,
    required this.title,
    required this.province,
    required this.biome,
    required this.totalWaves,
    required this.targetScore,
    required this.allowedEnemies,
    required this.spawnIntervalSeconds,
    required this.educationalSnippet,
  });
}

const List<GameStageConfig> kGameStages = [
  GameStageConfig(
    stageNumber: 1,
    title: "Bukit Barisan Sanctum",
    province: "Sumatra, Indonesia",
    biome: "Tropical Lowland Rainforest",
    totalWaves: 3,
    targetScore: 800,
    allowedEnemies: [EnemyType.tractor, EnemyType.truck],
    spawnIntervalSeconds: 3.8,
    educationalSnippet:
        "Sumatran rainforests harbor over 10,000 plant species and the world's largest individual bloom, Rafflesia arnoldii. Illegal logging roads fragment vital wildlife corridors.",
  ),
  GameStageConfig(
    stageNumber: 2,
    title: "Heart of Borneo Peatlands",
    province: "Kalimantan, Indonesia",
    biome: "Peat Swamp & Ironwood Forest",
    totalWaves: 4,
    targetScore: 1600,
    allowedEnemies: [EnemyType.tractor, EnemyType.truck, EnemyType.excavator],
    spawnIntervalSeconds: 3.2,
    educationalSnippet:
        "Bornean Ironwood (Ulin) takes over a century to mature. Deep peat drainage by excavators releases gigatons of stored carbon and destroys ancient carnivorous pitcher plants.",
  ),
  GameStageConfig(
    stageNumber: 3,
    title: "Lorentz Ancient Canopy",
    province: "Papua, Indonesia",
    biome: "Montane Virgin Cloud Rainforest",
    totalWaves: 5,
    targetScore: 2500,
    allowedEnemies: [EnemyType.tractor, EnemyType.truck, EnemyType.excavator],
    spawnIntervalSeconds: 2.6,
    educationalSnippet:
        "Lorentz National Park is the largest protected area in Southeast Asia. Preserving intact primary forests safeguards indigenous biodiversity that exists nowhere else on Earth.",
  ),
];

class GameState extends ChangeNotifier {
  static const bool _particleEffectsEnabled = false;

  final int stageIndex;
  late final GameStageConfig stageConfig;
  final AudioService _audio = AudioService();
  final Random _rng = Random();

  GameStatus status = GameStatus.ready;

  // Resources & Sanctum Health
  int ecoSeeds = 150; // Starting eco-seed energy
  int maxSanctumHealth = 3;
  int sanctumHealth = 3;
  int enemiesDefeated = 0;
  int totalEnemiesSpawned = 0;
  int currentWave = 1;
  double waveProgress = 0.0;
  int seedsCollectedThisMatch = 0;
  double deforestationPreventedHa = 0.0;

  // Selected tool/plant in tray
  PlantType? selectedPlantType;
  bool isShovelActive = false;

  // Cooldown timers per plant type
  final Map<PlantType, double> plantCooldowns = {};

  // Rafflesia Defender state (moves strictly on left vertical rail, NOT in grid)
  int rafflesiaLane = 1; // 0 (top), 1 (middle), 2 (bottom)
  double rafflesiaVisualY =
      1.0; // Interpolated visual position for smooth sliding
  double rafflesiaAttackCooldown = 0.0;
  double rafflesiaMouthOpenTimer = 0.0;
  int rafflesiaSporeCombo = 0;

  // Arena coordinates are mapped from the original 2750 x 1536 map artwork.
  // X and Y use the same pixel scale so sprites stay aligned at every size.
  static const double arenaWidth = 1000.0;
  static const double arenaHeight = arenaWidth * 1536.0 / 2750.0;
  static const double lane0Y = 194.182;
  static const double lane1Y = 288.364;
  static const double lane2Y = 384.364;
  static const List<double> laneYPositions = [lane0Y, lane1Y, lane2Y];

  static const double trackX = 225.818;
  static const double gridStartX = 297.091;
  static const double gridCellWidth = 67.844;
  static const double gridCellHeight = 89.400;
  static const double enemySpawnX = 1040.0;

  // Entities
  final List<PlantEntity?> gridPlants = List.filled(
    kGridCols * kGridRows,
    null,
  );
  final List<EnemyEntity> enemies = [];
  final List<Projectile> projectiles = [];
  final List<SeedDrop> droppedSeeds = [];
  final List<GameParticle> particles = [];

  // Spawning & Wave Engine
  double enemySpawnTimer = 1.5;
  int enemiesRemainingInWave = 6;
  bool isWaveSpawning = true;
  double waveBreakTimer = 0.0;

  GameState({this.stageIndex = 0}) {
    stageConfig = kGameStages[stageIndex.clamp(0, kGameStages.length - 1)];
    enemiesRemainingInWave = 4 + (stageConfig.stageNumber * 3);
    for (var plant in kPlantCatalog) {
      plantCooldowns[plant.type] = 0.0;
    }
  }

  void startGame() {
    status = GameStatus.playing;
    _audio.playBgm();
    notifyListeners();
  }

  void pauseGame() {
    if (status == GameStatus.playing) {
      status = GameStatus.paused;
      notifyListeners();
    }
  }

  void resumeGame() {
    if (status == GameStatus.paused) {
      status = GameStatus.playing;
      notifyListeners();
    }
  }

  // --- Rafflesia Vertical Rail Movement ---
  void moveRafflesiaUp() {
    if (rafflesiaLane > 0) {
      rafflesiaLane--;
      _audio.playSfx(SfxType.rafflesiaMove);
      _createPuffParticles(trackX, laneYPositions[rafflesiaLane]);
      notifyListeners();
    }
  }

  void moveRafflesiaDown() {
    if (rafflesiaLane < kLaneCount - 1) {
      rafflesiaLane++;
      _audio.playSfx(SfxType.rafflesiaMove);
      _createPuffParticles(trackX, laneYPositions[rafflesiaLane]);
      notifyListeners();
    }
  }

  void setRafflesiaLane(int targetLane) {
    if (targetLane >= 0 &&
        targetLane < kLaneCount &&
        targetLane != rafflesiaLane) {
      rafflesiaLane = targetLane;
      _audio.playSfx(SfxType.rafflesiaMove);
      _createPuffParticles(trackX, laneYPositions[rafflesiaLane]);
      notifyListeners();
    }
  }

  // --- Plant Placement & Shovel ---
  void selectPlant(PlantType type) {
    isShovelActive = false;
    if (selectedPlantType == type) {
      selectedPlantType = null; // Toggle off
    } else {
      selectedPlantType = type;
      _audio.playSfx(SfxType.buttonClick);
    }
    notifyListeners();
  }

  void selectShovel() {
    selectedPlantType = null;
    isShovelActive = !isShovelActive;
    _audio.playSfx(SfxType.buttonClick);
    notifyListeners();
  }

  bool canAfford(PlantType type) {
    final info = kPlantCatalog.firstWhere((p) => p.type == type);
    return ecoSeeds >= info.seedCost && (plantCooldowns[type] ?? 0.0) <= 0.0;
  }

  int _gridIndex(int col, int row) => row * kGridCols + col;

  PlantEntity? getPlantAt(int col, int row) {
    if (col < 0 || col >= kGridCols || row < 0 || row >= kGridRows) return null;
    return gridPlants[_gridIndex(col, row)];
  }

  void onCellTapped(int col, int row) {
    if (status != GameStatus.playing) return;

    final index = _gridIndex(col, row);
    final existingPlant = gridPlants[index];

    if (isShovelActive) {
      if (existingPlant != null) {
        gridPlants[index] = null;
        _audio.playSfx(SfxType.enemyHit);
        _createPuffParticles(existingPlant.x, existingPlant.y);
        isShovelActive = false;
        notifyListeners();
      }
      return;
    }

    if (selectedPlantType != null) {
      final info = kPlantCatalog.firstWhere((p) => p.type == selectedPlantType);
      if (existingPlant == null &&
          ecoSeeds >= info.seedCost &&
          (plantCooldowns[selectedPlantType!] ?? 0) <= 0) {
        // Place plant
        ecoSeeds -= info.seedCost;
        plantCooldowns[selectedPlantType!] = info.cooldownSeconds;

        final cellCenterX =
            gridStartX + (col * gridCellWidth) + (gridCellWidth / 2);
        final cellCenterY = laneYPositions[row];

        final newPlant = PlantEntity(
          type: selectedPlantType!,
          lane: row,
          gridCol: col,
          x: cellCenterX,
          y: cellCenterY,
        );
        gridPlants[index] = newPlant;

        _audio.playSfx(SfxType.plantPlaced);
        _createGreenLeafParticles(cellCenterX, cellCenterY);

        selectedPlantType = null;
        notifyListeners();
      }
    }
  }

  void collectSeed(SeedDrop drop) {
    if (drop.isCollected) return;
    drop.isCollected = true;
    ecoSeeds += drop.seedValue;
    seedsCollectedThisMatch += drop.seedValue;
    _audio.playSfx(SfxType.seedPickup);
    _createSeedGlowParticles(drop.x, drop.y);
    notifyListeners();
  }

  // --- Game Loop (60 FPS Update) ---
  void update(double dt) {
    if (status != GameStatus.playing) return;

    // 1. Smooth visual slide for Rafflesia
    final targetY = rafflesiaLane.toDouble();
    rafflesiaVisualY += (targetY - rafflesiaVisualY) * min(1.0, dt * 14.0);

    // 2. Decrement plant cooldowns
    plantCooldowns.forEach((key, value) {
      if (value > 0) {
        plantCooldowns[key] = max(0.0, value - dt);
      }
    });

    // 3. Rafflesia Automatic Lane Attack
    rafflesiaAttackCooldown = max(0.0, rafflesiaAttackCooldown - dt);
    if (rafflesiaMouthOpenTimer > 0) {
      rafflesiaMouthOpenTimer = max(0.0, rafflesiaMouthOpenTimer - dt);
    }

    final hasEnemiesInRafflesiaLane = enemies.any(
      (e) => e.lane == rafflesiaLane && e.x > trackX && e.x < 950,
    );
    if (hasEnemiesInRafflesiaLane && rafflesiaAttackCooldown <= 0.0) {
      // Fire heavy eco-spore
      rafflesiaAttackCooldown = 1.05;
      rafflesiaMouthOpenTimer = 0.28;
      rafflesiaSporeCombo++;

      projectiles.add(
        Projectile(
          type: ProjectileType.rafflesiaSpore,
          lane: rafflesiaLane,
          x: trackX + 35.0,
          y: laneYPositions[rafflesiaLane],
          damage: 1.0,
        ),
      );
      _audio.playSfx(SfxType.shootSpore);
      _createSporeBurstParticles(trackX + 35.0, laneYPositions[rafflesiaLane]);
    }

    // 4. Plant updates & attacks
    for (int i = 0; i < gridPlants.length; i++) {
      final plant = gridPlants[i];
      if (plant == null || plant.isDead) continue;

      plant.update(dt);

      // Attack / Production logic per plant type
      if (plant.type == PlantType.pakisSprout) {
        final enemiesInLane = enemies.any(
          (e) => e.lane == plant.lane && e.x > plant.x,
        );
        if (enemiesInLane && plant.attackTimer >= 1.35) {
          plant.attackTimer = 0.0;
          projectiles.add(
            Projectile(
              type: ProjectileType.fernSpore,
              lane: plant.lane,
              x: plant.x + 20.0,
              y: plant.y,
              damage: 1.0,
            ),
          );
          _audio.playSfx(SfxType.shootSpore);
        }
      } else if (plant.type == PlantType.kantongSemar) {
        final enemiesInLane = enemies.any(
          (e) => e.lane == plant.lane && e.x > plant.x,
        );
        if (enemiesInLane && plant.attackTimer >= 2.2) {
          plant.attackTimer = 0.0;
          projectiles.add(
            Projectile(
              type: ProjectileType.pitcherAcid,
              lane: plant.lane,
              x: plant.x + 20.0,
              y: plant.y,
              speed: 380.0,
              damage: 1.0,
            ),
          );
          _audio.playSfx(SfxType.shootSpore);
        }
      } else if (plant.type == PlantType.anggrekHutan) {
        if (plant.productionTimer >= 7.5) {
          plant.productionTimer = 0.0;
          droppedSeeds.add(
            SeedDrop(
              id: 'orchid_${DateTime.now().microsecondsSinceEpoch}',
              x: plant.x + (_rng.nextDouble() - 0.5) * 20,
              y: plant.y - 15,
              targetY: plant.y + 15,
              seedValue: 25,
            ),
          );
          _createSeedGlowParticles(plant.x, plant.y);
        }
      }
    }

    // Clean up dead plants
    for (int i = 0; i < gridPlants.length; i++) {
      if (gridPlants[i]?.isDead == true) {
        _createPuffParticles(gridPlants[i]!.x, gridPlants[i]!.y);
        gridPlants[i] = null;
      }
    }

    // 5. Update Projectiles & Collision with nearest enemy in lane
    for (final proj in projectiles) {
      proj.update(dt);

      for (final enemy in enemies) {
        if (enemy.lane == proj.lane && !enemy.isDead) {
          final dist = (enemy.x - proj.x).abs();
          if (dist < 28.0) {
            proj.isDead = true;
            enemy.takeDamage(proj.damage);
            _audio.playSfx(SfxType.enemyHit);
            _createSparkParticles(proj.x, proj.y);
            break;
          }
        }
      }
    }
    projectiles.removeWhere((p) => p.isDead);

    // 6. Update Enemies & Machinery Attacks on Plants / Sanctum
    for (final enemy in enemies) {
      // Check collision with plants in current lane
      PlantEntity? plantToChop;
      for (int c = 0; c < kGridCols; c++) {
        final p = getPlantAt(c, enemy.lane);
        if (p != null && !p.isDead) {
          if (enemy.x - p.x > -15 && enemy.x - p.x < 35) {
            plantToChop = p;
            break;
          }
        }
      }

      if (plantToChop != null) {
        enemy.isBlocked = true;
        if (plantToChop.type == PlantType.titanArum) {
          _detonateTitanArum(plantToChop, enemy);
        } else {
          plantToChop.takeDamage(enemy.info.damagePerSecond * dt);
          _createWoodSplinterParticles(plantToChop.x, plantToChop.y);
        }
      } else {
        enemy.isBlocked = false;
      }

      enemy.update(dt);

      // Check if enemy crossed the left defense rail (Sanctum Breach!)
      if (enemy.x < trackX - 10) {
        enemy.isDead = true;
        sanctumHealth--;
        _audio.playSfx(SfxType.defeat);
        _createSmokeParticles(enemy.x, laneYPositions[enemy.lane]);

        if (sanctumHealth <= 0) {
          sanctumHealth = 0;
          status = GameStatus.defeat;
          _audio.stopBgm();
          notifyListeners();
          return;
        }
      }
    }

    // Check enemy deaths & 20% Seed Drop Chance!
    for (final enemy in enemies) {
      if (enemy.isDead && enemy.health <= 0) {
        enemiesDefeated++;
        deforestationPreventedHa += (enemy.info.scoreValue / 20.0);
        _audio.playSfx(SfxType.enemyDestroyed);
        _createExplosionParticles(enemy.x, laneYPositions[enemy.lane]);

        // 20% CHANCE TO DROP A SEED POD!
        if (enemy.rollSeedDrop(_rng)) {
          droppedSeeds.add(
            SeedDrop(
              id: 'drop_${DateTime.now().microsecondsSinceEpoch}',
              x: enemy.x,
              y: laneYPositions[enemy.lane] - 20,
              targetY: laneYPositions[enemy.lane] + 10,
              seedValue: (enemy.type == EnemyType.excavator) ? 50 : 25,
            ),
          );
        }
      }
    }
    enemies.removeWhere((e) => e.isDead);

    // 7. Update Floating Seed Drops & Auto magnet if near Rafflesia
    for (final drop in droppedSeeds) {
      drop.update(dt);
      final distToRafflesia = (drop.x - trackX).abs() +
          (drop.y - laneYPositions[rafflesiaLane]).abs();
      if (distToRafflesia < 60.0) {
        collectSeed(drop);
      }
    }
    droppedSeeds.removeWhere((d) => d.isCollected);

    // 8. Update Particles
    particles.removeWhere((p) => !p.update(dt));

    // 9. Spawning Logic & Waves
    _updateSpawner(dt);

    notifyListeners();
  }

  void _detonateTitanArum(PlantEntity plant, EnemyEntity enemy) {
    plant.takeDamage(plant.health);
    enemy.takeDamage(enemy.health);

    final plantIndex = _gridIndex(plant.gridCol, plant.lane);
    if (gridPlants[plantIndex] == plant) {
      gridPlants[plantIndex] = null;
    }

    _createExplosionParticles(plant.x, plant.y);
    _createGreenLeafParticles(plant.x, plant.y);
  }

  void _updateSpawner(double dt) {
    if (isWaveSpawning) {
      enemySpawnTimer -= dt;
      if (enemySpawnTimer <= 0) {
        enemySpawnTimer =
            stageConfig.spawnIntervalSeconds + (_rng.nextDouble() * 0.8 - 0.4);

        // Pick a lane and enemy type
        final lane = _rng.nextInt(kLaneCount);
        final availableTypes = stageConfig.allowedEnemies;
        EnemyType type = availableTypes[_rng.nextInt(availableTypes.length)];

        // Weight excavator more heavily in later waves
        if (currentWave >= 3 &&
            availableTypes.contains(EnemyType.excavator) &&
            _rng.nextDouble() < 0.35) {
          type = EnemyType.excavator;
        }

        enemies.add(
          EnemyEntity(
            type: type,
            lane: lane,
            x: enemySpawnX,
            y: laneYPositions[lane],
          ),
        );
        totalEnemiesSpawned++;
        enemiesRemainingInWave--;

        if (enemiesRemainingInWave <= 0) {
          isWaveSpawning = false;
          waveBreakTimer = 5.0; // 5 second rest before next wave
        }
      }
    } else {
      // Wave break or final check
      if (enemies.isEmpty) {
        if (currentWave < stageConfig.totalWaves) {
          waveBreakTimer -= dt;
          if (waveBreakTimer <= 0) {
            currentWave++;
            isWaveSpawning = true;
            enemiesRemainingInWave = 4 + (currentWave * 3);
            enemySpawnTimer = 1.0;
            // Reward wave bonus seeds
            ecoSeeds += 50;
            _audio.playSfx(SfxType.seedPickup);
          }
        } else {
          // VICTORY!
          status = GameStatus.victory;
          _audio.stopBgm();
          _audio.playSfx(SfxType.victory);
          notifyListeners();
        }
      }
    }

    waveProgress = (currentWave -
            1 +
            (1.0 - (enemiesRemainingInWave / max(1, 4 + (currentWave * 3))))) /
        stageConfig.totalWaves;
  }

  // --- Particle Generators ---
  void _createGreenLeafParticles(double x, double y) {
    if (!_particleEffectsEnabled) return;
    for (int i = 0; i < 12; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final spd = 40 + _rng.nextDouble() * 90;
      particles.add(
        GameParticle(
          x: x,
          y: y,
          vx: cos(angle) * spd,
          vy: sin(angle) * spd - 30,
          size: 4 + _rng.nextDouble() * 4,
          maxLife: 0.6 + _rng.nextDouble() * 0.4,
          color: const Color(0xFF4CAF50),
          type: ParticleType.leaf,
        ),
      );
    }
  }

  void _createPuffParticles(double x, double y) {
    if (!_particleEffectsEnabled) return;
    for (int i = 0; i < 8; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final spd = 30 + _rng.nextDouble() * 50;
      particles.add(
        GameParticle(
          x: x,
          y: y,
          vx: cos(angle) * spd,
          vy: sin(angle) * spd,
          size: 5 + _rng.nextDouble() * 5,
          maxLife: 0.4,
          color: const Color(0xFF8D6E63),
          type: ParticleType.woodSplinter,
        ),
      );
    }
  }

  void _createSporeBurstParticles(double x, double y) {
    if (!_particleEffectsEnabled) return;
    for (int i = 0; i < 8; i++) {
      final angle = (_rng.nextDouble() - 0.5) * 1.2;
      final spd = 80 + _rng.nextDouble() * 120;
      particles.add(
        GameParticle(
          x: x,
          y: y,
          vx: cos(angle) * spd,
          vy: sin(angle) * spd,
          size: 4 + _rng.nextDouble() * 3,
          maxLife: 0.35,
          color: const Color(0xFFE91E63),
          type: ParticleType.sporeBurst,
        ),
      );
    }
  }

  void _createSparkParticles(double x, double y) {
    if (!_particleEffectsEnabled) return;
    for (int i = 0; i < 6; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final spd = 60 + _rng.nextDouble() * 80;
      particles.add(
        GameParticle(
          x: x,
          y: y,
          vx: cos(angle) * spd,
          vy: sin(angle) * spd,
          size: 3,
          maxLife: 0.25,
          color: const Color(0xFFFFD54F),
          type: ParticleType.metalSpark,
        ),
      );
    }
  }

  void _createExplosionParticles(double x, double y) {
    if (!_particleEffectsEnabled) return;
    for (int i = 0; i < 16; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final spd = 70 + _rng.nextDouble() * 140;
      particles.add(
        GameParticle(
          x: x,
          y: y,
          vx: cos(angle) * spd,
          vy: sin(angle) * spd - 40,
          size: 6 + _rng.nextDouble() * 6,
          maxLife: 0.7,
          color: const Color(0xFFFF7043),
          type: ParticleType.metalSpark,
        ),
      );
    }
  }

  void _createWoodSplinterParticles(double x, double y) {
    if (!_particleEffectsEnabled) return;
    for (int i = 0; i < 4; i++) {
      particles.add(
        GameParticle(
          x: x,
          y: y,
          vx: (_rng.nextDouble() - 0.5) * 70,
          vy: -30 - _rng.nextDouble() * 60,
          size: 4,
          maxLife: 0.4,
          color: const Color(0xFF6D4C41),
          type: ParticleType.woodSplinter,
        ),
      );
    }
  }

  void _createSmokeParticles(double x, double y) {
    if (!_particleEffectsEnabled) return;
    for (int i = 0; i < 6; i++) {
      particles.add(
        GameParticle(
          x: x + (_rng.nextDouble() - 0.5) * 20,
          y: y,
          vx: (_rng.nextDouble() - 0.5) * 30,
          vy: -40 - _rng.nextDouble() * 30,
          size: 8,
          maxLife: 0.8,
          color: const Color(0x88424242),
          type: ParticleType.dieselSmoke,
        ),
      );
    }
  }

  void _createSeedGlowParticles(double x, double y) {
    if (!_particleEffectsEnabled) return;
    for (int i = 0; i < 8; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      particles.add(
        GameParticle(
          x: x,
          y: y,
          vx: cos(angle) * 45,
          vy: sin(angle) * 45,
          size: 4,
          maxLife: 0.5,
          color: const Color(0xFFFFEB3B),
          type: ParticleType.seedGlow,
        ),
      );
    }
  }
}
