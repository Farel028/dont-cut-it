import 'dart:math';
import 'entity.dart';

enum EnemyType {
  tractor, // High speed chainsaw tractor
  truck, // Logging hauler truck
  excavator, // Heavy peatland excavator
}

class EnemyInfo {
  final EnemyType type;
  final String name;
  final String indonesianName;
  final double maxHp;
  final double speed;
  final double attackDamage;
  final int scoreValue;
  final String assetPath;
  final String description;
  final String threatLevel;

  const EnemyInfo({
    required this.type,
    required this.name,
    required this.indonesianName,
    required this.maxHp,
    required this.speed,
    required this.attackDamage,
    required this.scoreValue,
    required this.assetPath,
    required this.description,
    required this.threatLevel,
  });
}

const List<EnemyInfo> kEnemyCatalog = [
  // Updated enemy stats from deskripsi.md
  EnemyInfo(
    type: EnemyType.tractor,
    name: "Logging Tractor",
    indonesianName: "Traktor Penebang",
    maxHp: 4, // HP 4
    speed: 38.0,
    attackDamage: 2.0, // Attack 2
    scoreValue: 150,
    assetPath: "assets/images/tractor.png",
    description:
        "Traktor penebang cepat dengan bilah pemotong tajam. Menyerang tanaman dengan 2 damage setiap 2 detik.",
    threatLevel: "Fast Attacker",
  ),
  EnemyInfo(
    type: EnemyType.truck,
    name: "Timber Hauler Truck",
    indonesianName: "Truk Kayu Gelondongan",
    maxHp: 5, // HP 5
    speed: 28.0,
    attackDamage: 1.0, // Attack 1
    scoreValue: 250,
    assetPath: "assets/images/truck.png",
    description:
        "Truk muatan kayu lapis baja tebal dengan daya tahan 5 HP. Memberikan 1 damage setiap 2 detik.",
    threatLevel: "Heavy Armor",
  ),
  EnemyInfo(
    type: EnemyType.excavator,
    name: "Land Dredge Excavator",
    indonesianName: "Ekskavator Tambang & Lahan",
    maxHp: 3, // HP 3
    speed: 20.0,
    attackDamage: 3.0, // Attack 3
    scoreValue: 400,
    assetPath: "assets/images/excavator.png",
    description:
        "Ekskavator pengeruk berdaya hancur tinggi dengan 3 damage setiap 2 detik.",
    threatLevel: "High Damage",
  ),
];

class EnemyEntity extends LaneEntity {
  final EnemyType type;
  final EnemyInfo info;

  double attackTimer = 0.0;
  bool isBlocked = false;
  double slowEffectMultiplier = 1.0;
  double slowTimer = 0.0;
  double trapTimer = 0.0;
  double cendanaAuraTimer = 0.0;
  double animationWheelAngle = 0.0;
  double hitFlashTimer = 0.0;

  EnemyEntity({
    required this.type,
    required super.lane,
    required super.x,
    required super.y,
  })  : info = kEnemyCatalog.firstWhere((e) => e.type == type),
        super(
          width: 78,
          height: 60,
          health: kEnemyCatalog.firstWhere((e) => e.type == type).maxHp,
          maxHealth: kEnemyCatalog.firstWhere((e) => e.type == type).maxHp,
        );

  @override
  void takeDamage(double damage) {
    super.takeDamage(damage);
    hitFlashTimer = 0.12;
  }

  void applySlow(double multiplier, double duration) {
    slowEffectMultiplier = multiplier;
    slowTimer = max(slowTimer, duration);
  }

  void applyTrap(double duration) {
    trapTimer = max(trapTimer, duration);
  }

  bool get isTrapped => trapTimer > 0;
  bool get hasCendanaAura => cendanaAuraTimer > 0;

  /// Drops a plant card upon defeat
  bool rollPlantCardDrop(Random rng) {
    return rng.nextDouble() < 0.70; // 70% chance to drop plant card when killed
  }

  @override
  void update(double dt) {
    if (hitFlashTimer > 0) {
      hitFlashTimer = max(0, hitFlashTimer - dt);
    }

    if (slowTimer > 0) {
      slowTimer -= dt;
      if (slowTimer <= 0) {
        slowEffectMultiplier = 1.0;
      }
    }

    if (trapTimer > 0) {
      trapTimer -= dt;
    }

    if (cendanaAuraTimer > 0) {
      cendanaAuraTimer = max(0, cendanaAuraTimer - dt);
    }

    if (!isBlocked && !isTrapped) {
      final effectiveSpeed = info.speed * slowEffectMultiplier;
      x -= effectiveSpeed * dt; // Moves left towards the left rail & sanctum
      animationWheelAngle += effectiveSpeed * dt * 0.08;
    }
  }
}

