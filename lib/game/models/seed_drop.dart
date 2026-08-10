import 'dart:math';
import 'dart:ui';
import 'plants.dart';

class PlantCardDrop {
  final String id;
  final PlantType plantType;
  double x;
  double y;
  final double targetY;
  double lifeTimer = 0.0;
  bool isCollected = false;
  double bouncePhase = 0.0;

  PlantCardDrop({
    required this.id,
    required this.plantType,
    required this.x,
    required this.y,
    required this.targetY,
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

// Typedef for backwards compatibility
typedef SeedDrop = PlantCardDrop;

