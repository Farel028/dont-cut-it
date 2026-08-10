import 'dart:ui';

/// Number of horizontal lanes in the centered arena
const int kLaneCount = 3;

/// Center planting grid dimensions
const int kGridCols = 7;
const int kGridRows = 3;

/// Base lane entity
abstract class LaneEntity {
  int lane; // 0, 1, 2
  double
  x; // Horizontal position along the lane (0.0 to 1000.0 normalized coordinate)
  double y; // Vertical center of the lane
  double width;
  double height;
  double health;
  double maxHealth;
  bool isDead = false;

  LaneEntity({
    required this.lane,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.health,
    required this.maxHealth,
  });

  Rect get boundingBox =>
      Rect.fromCenter(center: Offset(x, y), width: width, height: height);

  void takeDamage(double damage) {
    health -= damage;
    if (health <= 0) {
      health = 0;
      isDead = true;
    }
  }

  void update(double dt);
}
