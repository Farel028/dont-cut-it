import 'entity.dart';

enum PlantType {
  titanArum,    // Bunga Bangkai (1 HP, Corpse Cloud)
  kantongSemar, // Kantong Semar (1 HP, Pitcher Trap)
  cendana,      // Cendana (4 HP, Scent Aura 3x3)
  eboni,        // Eboni Sulawesi (6 HP, Deep Root)
  gaharu,       // Gaharu (4 HP, Healing Resin 3x2)
  meranti,      // Meranti Merah (5 HP, Canopy Shield)
  damar,        // Damar (4 HP, Resin Goo)
  sonokeling,   // Sonokeling (2 HP, Crimson Shard)
}

class PlantInfo {
  final PlantType type;
  final String name;
  final String indonesianName;
  final String scientificName;
  final String status;
  final String assetPath;
  final double maxHp;
  final double cooldownSeconds;
  final String about;
  final String abilityName;
  final String abilityDescription;
  final String iconEmoji;
  final String colorHex;

  const PlantInfo({
    required this.type,
    required this.name,
    required this.indonesianName,
    required this.scientificName,
    required this.status,
    required this.assetPath,
    required this.maxHp,
    required this.cooldownSeconds,
    required this.about,
    required this.abilityName,
    required this.abilityDescription,
    required this.iconEmoji,
    required this.colorHex,
  });
}

const List<PlantInfo> kPlantCatalog = [
  PlantInfo(
    type: PlantType.titanArum,
    name: "Titan Arum",
    indonesianName: "Bunga Bangkai",
    scientificName: "Amorphophallus titanum",
    status: "ENDANGERED",
    assetPath: "assets/images/titan_arum.png",
    maxHp: 1,
    cooldownSeconds: 8.0,
    about:
        "Bunga bangkai raksasa merupakan tumbuhan asli Sumatra dengan salah satu perbungaan terbesar di dunia. Saat mekar, bunganya mengeluarkan aroma seperti daging membusuk untuk menarik serangga yang membantu penyerbukan.",
    abilityName: "CORPSE CLOUD",
    abilityDescription:
        "Menyebarkan aroma menyengat di area sekitar dan memberikan damage kepada semua musuh yang berada di dalamnya.",
    iconEmoji: "🌺",
    colorHex: "#880E4F",
  ),
  PlantInfo(
    type: PlantType.kantongSemar,
    name: "Pitcher Plant",
    indonesianName: "Kantong Semar",
    scientificName: "Nepenthes sp.",
    status: "CRITICALLY ENDANGERED",
    assetPath: "assets/images/trees/kantungsemar.png",
    maxHp: 1,
    cooldownSeconds: 6.0,
    about:
        "Kantong semar merupakan tumbuhan karnivora yang memerangkap serangga menggunakan daun berbentuk kantong. Permukaan licin dan cairan di dalam kantong membuat mangsa sulit melarikan diri setelah terjebak.",
    abilityName: "PITCHER TRAP",
    abilityDescription:
        "Memasang perangkap yang menangkap musuh yang melewatinya dan menahannya selama beberapa saat.",
    iconEmoji: "🪴",
    colorHex: "#00695C",
  ),
  PlantInfo(
    type: PlantType.cendana,
    name: "Sandalwood",
    indonesianName: "Pohon Cendana",
    scientificName: "Santalum album",
    status: "VULNERABLE",
    assetPath: "assets/images/trees/cendana.png",
    maxHp: 4,
    cooldownSeconds: 5.0,
    about:
        "Cendana dikenal karena kayunya yang menghasilkan aroma khas dan minyak atsiri bernilai tinggi. Kayunya telah lama digunakan untuk parfum, dupa, kosmetik, dan berbagai kerajinan.",
    abilityName: "SCENT AURA",
    abilityDescription:
        "Menyebarkan aroma khas yang memperlambat kendaraan dan musuh di sekitarnya dalam area 3x3.",
    iconEmoji: "🌿",
    colorHex: "#2E7D32",
  ),
  PlantInfo(
    type: PlantType.eboni,
    name: "Sulawesi Ebony",
    indonesianName: "Eboni Sulawesi",
    scientificName: "Diospyros celebica",
    status: "VULNERABLE",
    assetPath: "assets/images/trees/eboni.png",
    maxHp: 6,
    cooldownSeconds: 8.0,
    about:
        "Eboni Sulawesi merupakan pohon endemik Sulawesi yang terkenal karena kayunya yang gelap dengan pola belang yang khas. Kayunya bernilai tinggi dan banyak digunakan untuk furnitur, ukiran, serta alat musik.",
    abilityName: "DEEP ROOT",
    abilityDescription:
        "Akar yang kuat menambatkan pohon ke tanah, membuatnya lebih tahan terhadap serangan dan gangguan di sekitarnya.",
    iconEmoji: "🪵",
    colorHex: "#3E2723",
  ),
  PlantInfo(
    type: PlantType.gaharu,
    name: "Agarwood",
    indonesianName: "Pohon Gaharu",
    scientificName: "Aquilaria malaccensis",
    status: "VULNERABLE*",
    assetPath: "assets/images/trees/gaharu.png",
    maxHp: 4,
    cooldownSeconds: 7.0,
    about:
        "Gaharu menghasilkan kayu beraroma harum ketika mengalami infeksi atau kerusakan tertentu yang memicu pembentukan resin. Kayu ber-resin ini sangat bernilai dan digunakan dalam parfum, dupa, serta minyak atsiri.",
    abilityName: "HEALING RESIN",
    abilityDescription:
        "Mengeluarkan resin khusus yang memulihkan +2 HP tanaman sekitar dalam area 3x2 di depan saat pohon terkena serangan.",
    iconEmoji: "🌳",
    colorHex: "#5D4037",
  ),
  PlantInfo(
    type: PlantType.meranti,
    name: "Red Meranti",
    indonesianName: "Meranti Merah",
    scientificName: "Shorea leprosula",
    status: "NEAR THREATENED*",
    assetPath: "assets/images/trees/meranti.png",
    maxHp: 5,
    cooldownSeconds: 7.0,
    about:
        "Meranti merah merupakan salah satu pohon penting di hutan hujan Asia Tenggara. Kanopinya membantu membentuk lapisan atas hutan sekaligus menyediakan habitat dan naungan bagi berbagai organisme.",
    abilityName: "CANOPY SHIELD",
    abilityDescription:
        "Membentangkan kanopi pelindung rimbun yang memberikan perisai pertahanan (shield) kepada pohon teman di sebelah kiri dan kanannya.",
    iconEmoji: "🌲",
    colorHex: "#C62828",
  ),
  PlantInfo(
    type: PlantType.damar,
    name: "Dammar Tree",
    indonesianName: "Pohon Damar",
    scientificName: "Agathis dammara",
    status: "VULNERABLE",
    assetPath: "assets/images/trees/damar.png",
    maxHp: 4,
    cooldownSeconds: 6.0,
    about:
        "Damar merupakan pohon besar yang menghasilkan resin bernilai ekonomi. Resin damar telah dimanfaatkan untuk berbagai keperluan, termasuk bahan pelapis, perekat, dan produk tradisional.",
    abilityName: "RESIN GOO",
    abilityDescription:
        "Menembakkan getah resin pekat yang memberikan damage dan memperlambat laju kendaraan musuh.",
    iconEmoji: "🌴",
    colorHex: "#F57F17",
  ),
  PlantInfo(
    type: PlantType.sonokeling,
    name: "Rosewood",
    indonesianName: "Pohon Sonokeling",
    scientificName: "Dalbergia latifolia",
    status: "VULNERABLE",
    assetPath: "assets/images/trees/sonokeling.png",
    maxHp: 2,
    cooldownSeconds: 5.0,
    about:
        "Sonokeling dikenal karena kayunya yang keras, tahan lama, dan memiliki warna gelap dengan pola serat yang indah. Kayunya banyak dimanfaatkan untuk furnitur, ukiran, alat musik, dan kerajinan bernilai tinggi.",
    abilityName: "CRIMSON ROSEWOOD SHARD",
    abilityDescription:
        "Menembakkan serpihan peluru merah berdaya tusuk tajam ke arah barisan alat berat di jalurnya.",
    iconEmoji: "🎋",
    colorHex: "#4A148C",
  ),
];

class PlantEntity extends LaneEntity {
  final PlantType type;
  final int gridCol; // 0 to 6 (7 cols)
  final PlantInfo info;

  double attackTimer = 0.0;
  double animationPhase = 0.0;
  double abilityTimer = 0.0;
  double shieldAmount = 0.0;

  // Visual effect timers for special skills
  double healEffectTimer = 0.0;
  double cloudEffectTimer = 0.0;

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
  void takeDamage(double damage) {
    if (shieldAmount > 0) {
      if (damage <= shieldAmount) {
        shieldAmount -= damage;
        return;
      } else {
        final remainingDamage = damage - shieldAmount;
        shieldAmount = 0;
        super.takeDamage(remainingDamage);
        return;
      }
    }
    super.takeDamage(damage);
  }

  void heal(double amount) {
    health = (health + amount).clamp(0.0, maxHealth);
    healEffectTimer = 1.2;
  }

  @override
  void update(double dt) {
    animationPhase += dt * 3.0;
    attackTimer += dt;
    abilityTimer += dt;
    if (healEffectTimer > 0) healEffectTimer = (healEffectTimer - dt).clamp(0.0, 5.0);
    if (cloudEffectTimer > 0) cloudEffectTimer = (cloudEffectTimer - dt).clamp(0.0, 5.0);
  }
}


