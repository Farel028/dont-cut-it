import 'entity.dart';

enum PlantType {
  pakisSprout, // Spore Shooter (shoots eco-spores)
  ulinRoot, // High HP Root Wall (stops tractors/trucks)
  titanArum, // Contact trap that destroys itself and one enemy
  kantongSemar, // Pitcher plant (corrosive sap projectile)
  anggrekHutan, // Photosynthesis energy generator (drops seeds)
}

class PlantInfo {
  final PlantType type;
  final String name;
  final String indonesianName;
  final String scientificName;
  final int seedCost;
  final double maxHp;
  final double cooldownSeconds;
  final String description;
  final String iconEmoji;
  final String role;
  final String colorHex;

  const PlantInfo({
    required this.type,
    required this.name,
    required this.indonesianName,
    required this.scientificName,
    required this.seedCost,
    required this.maxHp,
    required this.cooldownSeconds,
    required this.description,
    required this.iconEmoji,
    required this.role,
    required this.colorHex,
  });
}

const List<PlantInfo> kPlantCatalog = [
  PlantInfo(
    type: PlantType.pakisSprout,
    name: "Ancient Fern Sprout",
    indonesianName: "Pakis Purba Hutan",
    scientificName: "Cyathea contaminans",
    seedCost: 50,
    maxHp: 150,
    cooldownSeconds: 4.0,
    description:
        "Rapidly fires high-velocity eco-spores at advancing deforestation machinery.",
    iconEmoji: "🌿",
    role: "Attacker (Spore Launcher)",
    colorHex: "#2E7D32",
  ),
  PlantInfo(
    type: PlantType.ulinRoot,
    name: "Bornean Ironwood Root",
    indonesianName: "Akar Kayu Ulin",
    scientificName: "Eusideroxylon zwageri",
    seedCost: 75,
    maxHp: 900,
    cooldownSeconds: 8.0,
    description:
        "Dense, indestructible tropical ironwood roots that stall and withstand heavy bulldozers.",
    iconEmoji: "🪵",
    role: "Defensive Wall (High HP)",
    colorHex: "#5D4037",
  ),
  PlantInfo(
    type: PlantType.titanArum,
    name: "Titan Arum / Corpse Flower",
    indonesianName: "Bunga Bangkai Raksasa",
    scientificName: "Amorphophallus titanum",
    seedCost: 100,
    maxHp: 250,
    cooldownSeconds: 10.0,
    description:
        "Detonates on contact with deforestation machinery, destroying both the plant and the vehicle.",
    iconEmoji: "🌺",
    role: "Contact Trap",
    colorHex: "#880E4F",
  ),
  PlantInfo(
    type: PlantType.kantongSemar,
    name: "Tropical Pitcher Plant",
    indonesianName: "Kantong Semar Hutan",
    scientificName: "Nepenthes ampullaria",
    seedCost: 125,
    maxHp: 200,
    cooldownSeconds: 9.0,
    description:
        "Launches heavy droplets of acidic digestive enzyme that weaken vehicle armor.",
    iconEmoji: "🪴",
    role: "Armor-Piercing Striker",
    colorHex: "#00695C",
  ),
  PlantInfo(
    type: PlantType.anggrekHutan,
    name: "Moon Forest Orchid",
    indonesianName: "Anggrek Bulan Hutan",
    scientificName: "Phalaenopsis amabilis",
    seedCost: 50,
    maxHp: 120,
    cooldownSeconds: 6.0,
    description:
        "Harnesses tropical rainforest sunlight and rainfall to produce +25 Eco-Seeds periodically.",
    iconEmoji: "🌸",
    role: "Eco-Energy Producer",
    colorHex: "#AD1457",
  ),
];

class PlantEntity extends LaneEntity {
  final PlantType type;
  final int gridCol; // 0 to 7
  final PlantInfo info;

  double attackTimer = 0.0;
  double productionTimer = 0.0;
  double animationPhase = 0.0;

  PlantEntity({
    required this.type,
    required super.lane,
    required this.gridCol,
    required super.x,
    required super.y,
  })  : info = kPlantCatalog.firstWhere((p) => p.type == type),
        super(
          width: 54,
          height: 54,
          health: kPlantCatalog.firstWhere((p) => p.type == type).maxHp,
          maxHealth: kPlantCatalog.firstWhere((p) => p.type == type).maxHp,
        );

  @override
  void update(double dt) {
    animationPhase += dt * 3.0;
    attackTimer += dt;
    productionTimer += dt;
  }
}
