import 'dart:ui';

enum ProjectileType {
  rafflesiaSpore,   // Rafflesia main attack spore
  damarResin,       // Damar sticky resin projectile (assets/images/trees/damarammo.png)
  sonokelingShard,  // Sonokeling crimson bullet (assets/images/trees/sonokelingammo.png)
}

class Projectile {
  final ProjectileType type;
  final int lane;
  double x;
  double y;
  final double speed;
  final double damage;
  bool isDead = false;
  double spinAngle = 0.0;

  Projectile({
    required this.type,
    required this.lane,
    required this.x,
    required this.y,
    this.speed = 340.0,
    required this.damage,
  });

  Rect get hitBox => Rect.fromCenter(
        center: Offset(x, y),
        width: 18,
        height: 18,
      );

  void update(double dt) {
    x += speed * dt; // Moves right towards enemies
    spinAngle += dt * 8.0;
    if (x > 1050) {
      isDead = true;
    }
  }
}
