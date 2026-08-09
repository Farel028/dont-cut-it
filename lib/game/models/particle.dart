import 'dart:math';
import 'dart:ui';

enum ParticleType {
  leaf,
  sporeBurst,
  woodSplinter,
  metalSpark,
  dieselSmoke,
  seedGlow,
}

class GameParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double life; // 0.0 to 1.0 (1.0 = full life)
  final double maxLife;
  final Color color;
  final ParticleType type;
  double rotation = 0.0;
  double rotationSpeed = 0.0;

  GameParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.maxLife,
    required this.color,
    required this.type,
  })  : life = maxLife,
        rotation = Random().nextDouble() * pi * 2,
        rotationSpeed = (Random().nextDouble() - 0.5) * 8.0;

  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;
    rotation += rotationSpeed * dt;
    life -= dt;

    if (type == ParticleType.leaf || type == ParticleType.woodSplinter) {
      vy += 120 * dt; // gravity
    } else if (type == ParticleType.dieselSmoke) {
      vy -= 25 * dt; // rises
      size += 15 * dt;
    }

    return life > 0;
  }
}
