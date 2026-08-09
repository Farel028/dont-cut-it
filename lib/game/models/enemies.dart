import 'dart:math';
import 'entity.dart';

enum EnemyType {
  tractor, // High speed, low HP chainsaw tractor
  truck, // Medium speed, high HP logging hauler
  excavator, // Slow, heavily armored excavator
}

class EnemyInfo {
  final EnemyType type;
  final String name;
  final String indonesianName;
  final double maxHp;
  final double speed;
  final double damagePerSecond;
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
    required this.damagePerSecond,
    required this.scoreValue,
    required this.assetPath,
    required this.description,
    required this.threatLevel,
  });
}

const List<EnemyInfo> kEnemyCatalog = [
  // Enemy hit points are configured through maxHp below.
  EnemyInfo(
    type: EnemyType.tractor,
    name: "Clearcut Logging Tractor",
    indonesianName: "Traktor Penebang Hutan",
    maxHp: 2,
    speed: 48.0, // pixels per second normalized
    damagePerSecond: 45.0,
    scoreValue: 100,
    assetPath: "assets/images/tractor.png",
    description:
        "Rapidly cuts down seedlings and clears underbrush to pave illegal roads.",
    threatLevel: "Fast Scout",
  ),
  EnemyInfo(
    type: EnemyType.truck,
    name: "Timber Hauler Truck",
    indonesianName: "Truk Pengangkut Kayu Gelondongan",
    maxHp: 3,
    speed: 32.0,
    damagePerSecond: 65.0,
    scoreValue: 250,
    assetPath: "assets/images/truck.png",
    description:
        "Heavy multi-axle truck carrying stolen ancient ironwood logs. Crushes barriers.",
    threatLevel: "Heavy Transporter",
  ),
  EnemyInfo(
    type: EnemyType.excavator,
    name: "Heavy Land Dredge Excavator",
    indonesianName: "Ekskavator Tambang & Lahan",
    maxHp: 5,
    speed: 18.0,
    damagePerSecond: 110.0,
    scoreValue: 500,
    assetPath: "assets/images/excavator.png",
    description:
        "Massive hydraulic bucket dredges peatland and tears ancient root systems from the earth.",
    threatLevel: "Boss Destroyer",
  ),
];

class EnemyEntity extends LaneEntity {
  final EnemyType type;
  final EnemyInfo info;

  double attackTimer = 0.0;
  bool isBlocked = false;
  double slowEffectMultiplier = 1.0;
  double slowTimer = 0.0;
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

  /// Determines if this defeated enemy drops an eco-seed pod (20% chance)
  bool rollSeedDrop(Random rng) {
    return rng.nextDouble() < 0.20; // Exact 20% drop chance
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

    if (!isBlocked) {
      final effectiveSpeed = info.speed * slowEffectMultiplier;
      x -= effectiveSpeed * dt; // Moves left towards the left rail & sanctum
      animationWheelAngle += effectiveSpeed * dt * 0.08;
    }
  }
}
