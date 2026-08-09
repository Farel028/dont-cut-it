import 'dart:math';
import 'dart:ui';

class SeedDrop {
  final String id;
  double x;
  double y;
  final double targetY;
  final int seedValue;
  double lifeTimer = 0.0;
  bool isCollected = false;
  double bouncePhase = 0.0;

  SeedDrop({
    required this.id,
    required this.x,
    required this.y,
    required this.targetY,
    this.seedValue = 25,
  }) : bouncePhase = Random().nextDouble() * pi * 2;

  Rect get touchBox => Rect.fromCenter(
        center: Offset(x, y),
        width: 48,
        height: 48,
      );

  void update(double dt) {
    lifeTimer += dt;
    // Slight downward arc then floating bounce
    if (y < targetY) {
      y = min(targetY, y + 120 * dt);
    }
    bouncePhase += dt * 3.5;
  }

  double get renderYOffset => sin(bouncePhase) * 6.0;
}
