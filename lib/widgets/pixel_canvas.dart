import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../game/models/entity.dart';
import '../game/models/plants.dart';
import '../game/models/enemies.dart';
import '../game/models/projectiles.dart';
import '../game/models/particle.dart';

/// 16:9 2D Arena Canvas Painter for "DON'T CUT IT"
/// Renders Indonesian tropical rainforest, 3 lanes, left Rafflesia vertical rail,
/// center 7x3 planting grid, right deforestation path, and combat effects.
class ArenaPainter extends CustomPainter {
  final GameState state;
  final double animationTick;
  final ui.Image? mapImage;
  final ui.Image? rafflesiaSprite;
  final ui.Image? titanArumSprite;
  final ui.Image? tractorSprite;
  final ui.Image? truckSprite;
  final ui.Image? excavatorSprite;

  ArenaPainter({
    required this.state,
    required this.animationTick,
    this.mapImage,
    this.rafflesiaSprite,
    this.titanArumSprite,
    this.tractorSprite,
    this.truckSprite,
    this.excavatorSprite,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Arena is mapped to normalized 1000 x 562.5 (16:9) coordinate space
    final scaleX = size.width / 1000.0;
    final scaleY = size.height / 562.5;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Draw Indonesian Tropical Rainforest Background & Ambient Atmosphere
    _drawRainforestBackground(canvas);

    if (mapImage == null) {
      // Legacy code-drawn arena remains as a loading/error fallback.
      _drawLanesAndForestFloor(canvas);
      _drawLeftTrack(canvas);
    }

    // Draw selection/occupancy feedback over the 7x3 board in map.png.
    _drawCenterPlantingGrid(canvas);

    if (mapImage == null) {
      _drawRightDeforestationPath(canvas);
    }

    // Draw plants on the 7x3 grid.
    _drawPlants(canvas);

    // 7. Draw Deforestation Machinery Enemies on Lanes
    _drawEnemies(canvas);

    // 8. Draw Rafflesia Defender on Left Track
    _drawRafflesia(canvas);

    // 9. Draw Projectiles (Spores, Acid Blasts)
    _drawProjectiles(canvas);

    // 10. Draw Dropped Eco-Seed Pods (20% Drop Chance)
    _drawDroppedSeeds(canvas);

    // 11. Draw Particle Effects (Smoke, Spores, Leaves, Sparks)
    _drawParticles(canvas);

    if (mapImage == null) {
      _drawLushCanopyFraming(canvas);
    }

    canvas.restore();
  }

  void _drawRainforestBackground(Canvas canvas) {
    const rect = Rect.fromLTWH(0, 0, 1000, 562.5);

    if (mapImage != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: mapImage!,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      );
      return;
    }

    // Background gradient: Dense misty tropical canopy
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D2818), // Deep jungle canopy top
          Color(0xFF163E24), // Mid canopy mist
          Color(0xFF225032), // Forest understory
          Color(0xFF2D3A20), // Humus soil layer
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Sunbeams / God rays filtering through tropical canopy
    final sunbeamPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -1.0),
        radius: 1.4,
        colors: [Color(0x33FFE082), Color(0x1181C784), Colors.transparent],
      ).createShader(rect);
    canvas.drawRect(rect, sunbeamPaint);

    // Distant ancient ironwood & banyan silhouettes
    final treeSilhouettePaint = Paint()..color = const Color(0x2A051B11);
    final treePath = Path();
    for (int i = 0; i < 9; i++) {
      final tx = i * 120.0 + 30;
      final ty = 60.0 + sin(i * 1.5 + animationTick * 0.5) * 6;
      treePath.addOval(
        Rect.fromCenter(center: Offset(tx, ty), width: 140, height: 110),
      );
    }
    canvas.drawPath(treePath, treeSilhouettePaint);
  }

  void _drawLanesAndForestFloor(Canvas canvas) {
    for (int lane = 0; lane < kLaneCount; lane++) {
      final laneY = GameState.laneYPositions[lane];
      final laneRect = Rect.fromLTWH(0, laneY - 55, 1000, 110);

      // Lane base layer - Indonesian fertile volcanic humus soil
      final laneBgPaint = Paint()
        ..color = (lane % 2 == 0)
            ? const Color(0xFF1E3A27)
            : const Color(0xFF193220);
      canvas.drawRect(laneRect, laneBgPaint);

      // Lane divider subtle mossy border
      final dividerPaint = Paint()
        ..color = const Color(0x334CAF50)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, laneY - 55),
        Offset(1000, laneY - 55),
        dividerPaint,
      );
      canvas.drawLine(
        Offset(0, laneY + 55),
        Offset(1000, laneY + 55),
        dividerPaint,
      );

      // Rainforest floor texture: moss patches, fallen broadleaves, roots
      final mossPaint = Paint()..color = const Color(0x22388E3C);
      for (int m = 0; m < 6; m++) {
        final mx = (m * 170.0 + lane * 45.0) % 950 + 25;
        final my = laneY + sin(m * 2.3) * 30;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(mx, my), width: 45, height: 20),
          mossPaint,
        );
      }
    }
  }

  void _drawLeftTrack(Canvas canvas) {
    // Left vertical rail bounds
    const trackRect = Rect.fromLTWH(20, 85, 130, 430);

    // Ancient Ironwood / Stone rail background
    final railBgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF3E2723), // Dark aged ironwood
          Color(0xFF5D4037), // Weathered timber rail
          Color(0xFF4E342E),
        ],
      ).createShader(trackRect);

    final rrect = RRect.fromRectAndRadius(trackRect, const Radius.circular(16));
    canvas.drawRRect(rrect, railBgPaint);

    // Track border
    final railBorderPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, railBorderPaint);

    // Vertical metal/wood rail guides where Rafflesia slides
    final guidePaint = Paint()
      ..color = const Color(0xFF271915)
      ..strokeWidth = 6.0;
    canvas.drawLine(const Offset(65, 100), const Offset(65, 500), guidePaint);
    canvas.drawLine(const Offset(105, 100), const Offset(105, 500), guidePaint);

    // Track ties (wooden sleepers)
    final tiePaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 4.0;
    for (double y = 115; y <= 485; y += 38) {
      canvas.drawLine(Offset(45, y), Offset(125, y), tiePaint);
    }

    // Lane stops / junction markers on the left track
    for (int l = 0; l < kLaneCount; l++) {
      final ly = GameState.laneYPositions[l];
      final isCurrent = (state.rafflesiaLane == l);

      final markerPaint = Paint()
        ..color = isCurrent ? const Color(0xFFE91E63) : const Color(0x66FFC107);
      canvas.drawCircle(Offset(85, ly), isCurrent ? 8.0 : 5.0, markerPaint);

      if (isCurrent) {
        final glowPaint = Paint()
          ..color = const Color(0x44FF4081)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(
          Offset(85, ly),
          14.0 + sin(animationTick * 6) * 3,
          glowPaint,
        );
      }
    }
  }

  void _drawCenterPlantingGrid(Canvas canvas) {
    for (int col = 0; col < kGridCols; col++) {
      for (int row = 0; row < kGridRows; row++) {
        final cellLeft = GameState.gridStartX + (col * GameState.gridCellWidth);
        final cellCenterY = GameState.laneYPositions[row];
        final cellRect = Rect.fromCenter(
          center: Offset(cellLeft + GameState.gridCellWidth / 2, cellCenterY),
          width: GameState.gridCellWidth - 6,
          height: GameState.gridCellHeight - 12,
        );

        final plant = state.getPlantAt(col, row);

        // Grid Cell fertile soil tile
        final soilPaint = Paint()
          ..color = (plant != null)
              ? const Color(0x332E7D32)
              : const Color(0x1F1B5E20);
        final rrect = RRect.fromRectAndRadius(
          cellRect,
          const Radius.circular(10),
        );
        canvas.drawRRect(rrect, soilPaint);

        // Cell border
        final borderPaint = Paint()
          ..color = (state.selectedPlantType != null && plant == null)
              ? const Color(0x6681C784)
              : const Color(0x22FFFFFF)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawRRect(rrect, borderPaint);

        // Little green sprout marker if cell is empty
        if (plant == null) {
          final sproutPaint = Paint()..color = const Color(0x444CAF50);
          canvas.drawCircle(
            Offset(cellRect.center.dx, cellRect.bottom - 12),
            3.0,
            sproutPaint,
          );
        }
      }
    }
  }

  void _drawRightDeforestationPath(Canvas canvas) {
    const roadRect = Rect.fromLTWH(765, 85, 235, 430);

    // Deforested scarred earth / logging road gradient
    final roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF2E2419), // Transition zone
          Color(0xFF422E1B), // Clearcut muddy logging track
          Color(0xFF5A381E), // Stolen forest earth
        ],
      ).createShader(roadRect);

    canvas.drawRect(roadRect, roadPaint);

    // Mud tire tracks across all 3 lanes on the right
    final trackPaint = Paint()
      ..color = const Color(0x441F160E)
      ..strokeWidth = 5.0;
    for (int l = 0; l < kLaneCount; l++) {
      final ly = GameState.laneYPositions[l];
      canvas.drawLine(Offset(775, ly - 22), Offset(1000, ly - 22), trackPaint);
      canvas.drawLine(Offset(775, ly + 22), Offset(1000, ly + 22), trackPaint);
    }

    // Cut tree stumps & logging debris on the right edge
    final stumpPaint = Paint()..color = const Color(0xFF6D4C41);
    for (int s = 0; s < 5; s++) {
      final sx = 820.0 + (s * 35.0) % 150;
      final sy = 120.0 + s * 80.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(sx, sy), width: 18, height: 10),
        stumpPaint,
      );
    }
  }

  void _drawPlants(Canvas canvas) {
    for (final plant in state.gridPlants) {
      if (plant == null || plant.isDead) continue;

      canvas.save();
      canvas.translate(plant.x, plant.y);

      // Plant breathing bounce
      final bounce = sin(plant.animationPhase) * 2.5;

      switch (plant.type) {
        case PlantType.pakisSprout:
          _drawPakisSprout(canvas, bounce);
          break;
        case PlantType.ulinRoot:
          _drawUlinRoot(canvas, bounce, plant.health / plant.maxHealth);
          break;
        case PlantType.titanArum:
          _drawTitanArum(canvas, bounce);
          break;
        case PlantType.kantongSemar:
          _drawKantongSemar(canvas, bounce);
          break;
        case PlantType.anggrekHutan:
          _drawAnggrekHutan(canvas, bounce);
          break;
      }

      // Health bar if plant is damaged
      if (plant.health < plant.maxHealth) {
        _drawHealthBar(canvas, plant.health / plant.maxHealth, -28);
      }

      canvas.restore();
    }
  }

  void _drawPakisSprout(Canvas canvas, double bounce) {
    // Ancient fern sprout with green fronds
    final frondPaint = Paint()..color = const Color(0xFF2E7D32);
    final centerPaint = Paint()..color = const Color(0xFF66BB6A);

    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (i - 2) * 0.45;
      final fx = cos(angle) * (20 + bounce);
      final fy = sin(angle) * (20 + bounce);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, fy), width: 14, height: 26),
        frondPaint,
      );
    }
    canvas.drawCircle(Offset(0, bounce), 10, centerPaint);

    // Spore core
    final corePaint = Paint()..color = const Color(0xFFE8F5E9);
    canvas.drawCircle(Offset(0, bounce), 4, corePaint);
  }

  void _drawUlinRoot(Canvas canvas, double bounce, double hpRatio) {
    // Massive ironwood barrier block
    final woodPaint = Paint()..color = const Color(0xFF4E342E);

    final woodRect = Rect.fromCenter(
      center: Offset(0, bounce),
      width: 38,
      height: 48,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(woodRect, const Radius.circular(8)),
      woodPaint,
    );

    // Moss on root
    final mossPaint = Paint()..color = const Color(0xFF388E3C);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, bounce - 18), width: 34, height: 10),
      mossPaint,
    );

    // Cracks if damaged
    if (hpRatio < 0.6) {
      final crackPaint = Paint()
        ..color = const Color(0xFF211512)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(-10, bounce - 10),
        Offset(5, bounce + 12),
        crackPaint,
      );
    }
  }

  void _drawTitanArum(Canvas canvas, double bounce) {
    // Titan Arum with purple spadix and green spathe
    final spathePaint = Paint()..color = const Color(0xFF880E4F);
    final spadixPaint = Paint()..color = const Color(0xFFFFD54F);

    // Spathe outer petals
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, bounce + 4), width: 44, height: 32),
      spathePaint,
    );

    // Tall towering yellow spadix
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, bounce - 14), width: 14, height: 38),
        const Radius.circular(6),
      ),
      spadixPaint,
    );

    // Stench particle rings
    final stenchRingPaint = Paint()
      ..color = Color.fromRGBO(
        171,
        71,
        188,
        0.35 + sin(animationTick * 4) * 0.15,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(
      Offset(0, bounce - 14),
      26.0 + sin(animationTick * 3) * 4,
      stenchRingPaint,
    );
  }

  void _drawKantongSemar(Canvas canvas, double bounce) {
    // Tropical pitcher plant
    final bodyPaint = Paint()..color = const Color(0xFF00695C);
    final rimPaint = Paint()..color = const Color(0xFF26A69A);
    final lidPaint = Paint()..color = const Color(0xFF80CBC4);

    // Pitcher pouch
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, bounce + 4), width: 26, height: 38),
      bodyPaint,
    );
    // Rim
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, bounce - 12), width: 22, height: 8),
      rimPaint,
    );
    // Lid
    canvas.drawOval(
      Rect.fromCenter(center: Offset(4, bounce - 20), width: 18, height: 6),
      lidPaint,
    );
  }

  void _drawAnggrekHutan(Canvas canvas, double bounce) {
    // Indonesian Moon Orchid
    final petalPaint = Paint()..color = const Color(0xFFFCE4EC);
    final lipPaint = Paint()..color = const Color(0xFFE91E63);

    for (int i = 0; i < 5; i++) {
      final angle = i * (pi * 2 / 5);
      final px = cos(angle) * (14 + bounce * 0.5);
      final py = sin(angle) * (14 + bounce * 0.5);
      canvas.drawCircle(Offset(px, py), 9, petalPaint);
    }
    canvas.drawCircle(Offset(0, bounce * 0.5), 7, lipPaint);
  }

  void _drawEnemies(Canvas canvas) {
    for (final enemy in state.enemies) {
      if (enemy.isDead) continue;

      canvas.save();
      canvas.translate(enemy.x, enemy.y);

      // Hit flash white color
      final isFlashing = enemy.hitFlashTimer > 0;
      final flashColor = isFlashing
          ? const Color(0xCCFFFFFF)
          : Colors.transparent;

      ui.Image? sprite;
      double spriteWidth;

      switch (enemy.type) {
        case EnemyType.tractor:
          sprite = tractorSprite;
          spriteWidth = 112;
          break;
        case EnemyType.truck:
          sprite = truckSprite;
          spriteWidth = 122;
          break;
        case EnemyType.excavator:
          sprite = excavatorSprite;
          spriteWidth = 108;
          break;
      }

      double healthBarY = -36;
      if (sprite != null) {
        final spriteHeight = spriteWidth * sprite.height / sprite.width;
        healthBarY = -spriteHeight / 2 - 7;
        paintImage(
          canvas: canvas,
          rect: Rect.fromCenter(
            center: Offset.zero,
            width: spriteWidth,
            height: spriteHeight,
          ),
          image: sprite,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        );
        if (isFlashing) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: spriteWidth,
                height: spriteHeight,
              ),
              const Radius.circular(8),
            ),
            Paint()..color = const Color(0x55FFFFFF),
          );
        }
      } else {
        switch (enemy.type) {
          case EnemyType.tractor:
            _drawTractor(canvas, enemy.animationWheelAngle, flashColor);
            break;
          case EnemyType.truck:
            _drawTruck(canvas, enemy.animationWheelAngle, flashColor);
            break;
          case EnemyType.excavator:
            _drawExcavator(canvas, enemy.animationWheelAngle, flashColor);
            break;
        }
      }

      // Enemy HP Bar
      _drawHealthBar(
        canvas,
        enemy.health / enemy.maxHealth,
        healthBarY,
        isEnemy: true,
      );

      canvas.restore();
    }
  }

  void _drawTractor(Canvas canvas, double wheelAngle, Color flashColor) {
    final bodyPaint = Paint()..color = const Color(0xFFFFB300);
    final darkPaint = Paint()..color = const Color(0xFF263238);
    final wheelPaint = Paint()..color = const Color(0xFF212121);
    final rimPaint = Paint()..color = const Color(0xFF757575);

    // Chassis & Hood
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-32, -18, 64, 28),
        const Radius.circular(6),
      ),
      bodyPaint,
    );
    // Cabin glass
    canvas.drawRect(const Rect.fromLTWH(6, -32, 22, 16), darkPaint);

    // Exhaust pipe with smoke
    canvas.drawRect(const Rect.fromLTWH(-18, -32, 5, 16), darkPaint);

    // Large rear wheel
    canvas.drawCircle(const Offset(16, 12), 16, wheelPaint);
    canvas.drawCircle(const Offset(16, 12), 7, rimPaint);

    // Small front wheel
    canvas.drawCircle(const Offset(-22, 14), 10, wheelPaint);
    canvas.drawCircle(const Offset(-22, 14), 4, rimPaint);

    // Sawblade cutter attachment on front left
    final sawPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(const Offset(-38, 8), 12, sawPaint);

    if (flashColor != Colors.transparent) {
      canvas.drawCircle(Offset.zero, 34, Paint()..color = flashColor);
    }
  }

  void _drawTruck(Canvas canvas, double wheelAngle, Color flashColor) {
    final cabPaint = Paint()..color = const Color(0xFFD32F2F);
    final bedPaint = Paint()..color = const Color(0xFF546E7A);
    final logPaint = Paint()..color = const Color(0xFF5D4037);
    final wheelPaint = Paint()..color = const Color(0xFF212121);

    // Truck bed carrying stolen logs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -22, 52, 32),
        const Radius.circular(4),
      ),
      bedPaint,
    );
    // Stolen logs stacked
    canvas.drawOval(const Rect.fromLTWH(-6, -34, 44, 14), logPaint);
    canvas.drawOval(const Rect.fromLTWH(-2, -26, 40, 12), logPaint);

    // Cab (front facing left)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-40, -18, 30, 28),
        const Radius.circular(5),
      ),
      cabPaint,
    );

    // Wheels (3 axles)
    canvas.drawCircle(const Offset(-28, 14), 10, wheelPaint);
    canvas.drawCircle(const Offset(10, 14), 10, wheelPaint);
    canvas.drawCircle(const Offset(30, 14), 10, wheelPaint);

    if (flashColor != Colors.transparent) {
      canvas.drawCircle(Offset.zero, 38, Paint()..color = flashColor);
    }
  }

  void _drawExcavator(Canvas canvas, double wheelAngle, Color flashColor) {
    final bodyPaint = Paint()..color = const Color(0xFFF57F17);
    final armPaint = Paint()..color = const Color(0xFFFBC02D);
    final trackPaint = Paint()..color = const Color(0xFF263238);
    final bucketPaint = Paint()..color = const Color(0xFF37474F);

    // Heavy Caterpillar Tracks
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-36, 6, 72, 18),
        const Radius.circular(8),
      ),
      trackPaint,
    );

    // Turret Cabin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -26, 42, 32),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Hydraulic Boom Arm stretching left
    final armPath = Path()
      ..moveTo(0, -14)
      ..lineTo(-32, -38)
      ..lineTo(-46, -10);
    canvas.drawPath(
      armPath,
      Paint()
        ..color = armPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );

    // Heavy Dredging Bucket
    final bucketPath = Path()
      ..moveTo(-46, -10)
      ..lineTo(-56, 4)
      ..lineTo(-42, 12)
      ..close();
    canvas.drawPath(bucketPath, bucketPaint);

    if (flashColor != Colors.transparent) {
      canvas.drawCircle(Offset.zero, 42, Paint()..color = flashColor);
    }
  }

  void _drawRafflesia(Canvas canvas) {
    // Smooth visual sliding along left vertical track
    final slide = state.rafflesiaVisualY.clamp(0.0, 2.0);
    final ry = slide <= 1
        ? ui.lerpDouble(
            GameState.laneYPositions[0],
            GameState.laneYPositions[1],
            slide,
          )!
        : ui.lerpDouble(
            GameState.laneYPositions[1],
            GameState.laneYPositions[2],
            slide - 1,
          )!;

    canvas.save();
    canvas.translate(GameState.trackX, ry);

    // Idle breathing & petal wobble
    final pulse = sin(animationTick * 5) * 2.0;
    final isMouthOpen = state.rafflesiaMouthOpenTimer > 0;

    if (rafflesiaSprite != null) {
      final width = 82.0 + pulse;
      final height = width * rafflesiaSprite!.height / rafflesiaSprite!.width;
      paintImage(
        canvas: canvas,
        rect: Rect.fromCenter(
          center: Offset.zero,
          width: width,
          height: height,
        ),
        image: rafflesiaSprite!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );

      final haloPaint = Paint()
        ..color = const Color(0x99FFF176)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMouthOpen ? 5 : 3;
      canvas.drawCircle(
        Offset.zero,
        width * .52 + sin(animationTick * 8) * 2,
        haloPaint,
      );
      canvas.restore();
      return;
    }

    // 5 Giant Spotted Red/Pink Petals
    final petalPaint = Paint()..color = const Color(0xFFE91E63);
    final spotPaint = Paint()..color = const Color(0xFFFFEB3B);

    for (int i = 0; i < 5; i++) {
      final angle = i * (pi * 2 / 5) + animationTick * 0.4;
      final px = cos(angle) * (26 + pulse);
      final py = sin(angle) * (26 + pulse);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: 34, height: 26),
        petalPaint,
      );
      // Yellow toxin spots
      canvas.drawCircle(Offset(px * 0.9, py * 0.9), 4.5, spotPaint);
      canvas.drawCircle(Offset(px * 1.2, py * 1.1), 2.5, spotPaint);
    }

    // Golden fleshy central core bowl
    final coreBowlPaint = Paint()..color = const Color(0xFFFFB300);
    canvas.drawCircle(Offset.zero, 20 + pulse * 0.5, coreBowlPaint);

    // Dark Spore Cannon Mouth (opens wide when firing!)
    final mouthRadius = isMouthOpen ? 14.0 : 8.0;
    final mouthPaint = Paint()..color = const Color(0xFF004D40);
    canvas.drawCircle(Offset.zero, mouthRadius, mouthPaint);

    // Glowing bio-spore charge ready to launch
    final chargePaint = Paint()..color = const Color(0xFF00E676);
    canvas.drawCircle(Offset.zero, isMouthOpen ? 8.0 : 3.5, chargePaint);

    // Selector halo indicator around current lane defender
    final haloPaint = Paint()
      ..color = const Color(0x66FF4081)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset.zero, 38 + sin(animationTick * 8) * 3, haloPaint);

    canvas.restore();
  }

  void _drawProjectiles(Canvas canvas) {
    for (final proj in state.projectiles) {
      if (proj.isDead) continue;

      canvas.save();
      canvas.translate(proj.x, proj.y);

      if (proj.type == ProjectileType.rafflesiaSpore) {
        // Heavy bio-explosive Rafflesia spore
        final sporePaint = Paint()..color = const Color(0xFFFF4081);
        final glowPaint = Paint()..color = const Color(0x66E91E63);

        canvas.drawCircle(Offset.zero, 12, glowPaint);
        canvas.drawCircle(Offset.zero, 7, sporePaint);

        // Core toxic particle
        canvas.drawCircle(
          Offset.zero,
          3,
          Paint()..color = const Color(0xFFFFF9C4),
        );
      } else if (proj.type == ProjectileType.fernSpore) {
        // Green rapid eco-seed
        final seedPaint = Paint()..color = const Color(0xFF4CAF50);
        canvas.drawCircle(Offset.zero, 5, seedPaint);
      } else if (proj.type == ProjectileType.pitcherAcid) {
        // Corrosive green venom drop
        final acidPaint = Paint()..color = const Color(0xFF00E676);
        canvas.drawOval(const Rect.fromLTWH(-8, -5, 16, 10), acidPaint);
      }

      canvas.restore();
    }
  }

  void _drawDroppedSeeds(Canvas canvas) {
    for (final drop in state.droppedSeeds) {
      if (drop.isCollected) continue;

      final renderY = drop.y + drop.renderYOffset;

      canvas.save();
      canvas.translate(drop.x, renderY);

      // Glowing aura around dropped seed
      final auraPaint = Paint()
        ..color = Color.fromRGBO(
          255,
          235,
          59,
          0.4 + sin(drop.bouncePhase) * 0.2,
        );
      canvas.drawCircle(Offset.zero, 16, auraPaint);

      // Golden Eco-Seed Pod
      final podPaint = Paint()..color = const Color(0xFFFFD600);
      canvas.drawCircle(Offset.zero, 9, podPaint);

      // Green sprout emerging from seed
      final leafPaint = Paint()..color = const Color(0xFF2E7D32);
      canvas.drawOval(const Rect.fromLTWH(-3, -12, 6, 8), leafPaint);

      canvas.restore();
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final p in state.particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final pColor = p.color.withValues(alpha: alpha * p.color.a);

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final paint = Paint()..color = pColor;

      if (p.type == ParticleType.leaf) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 1.8,
            height: p.size,
          ),
          paint,
        );
      } else if (p.type == ParticleType.dieselSmoke) {
        canvas.drawCircle(Offset.zero, p.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint,
        );
      }

      canvas.restore();
    }
  }

  void _drawLushCanopyFraming(Canvas canvas) {
    // Top canopy border: lush hanging vines, Indonesian tropical broadleaves
    final topFramePaint = Paint()..color = const Color(0xEE0A1E12);
    final vinePaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 3.0;

    // Layered top foliage
    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(1000, 0)
      ..lineTo(1000, 45)
      ..quadraticBezierTo(800, 75, 600, 40)
      ..quadraticBezierTo(400, 80, 200, 45)
      ..quadraticBezierTo(100, 65, 0, 45)
      ..close();
    canvas.drawPath(topPath, topFramePaint);

    // Hanging vines
    for (int v = 0; v < 8; v++) {
      final vx = 80.0 + v * 120.0;
      final vy = 40.0 + sin(v * 1.7 + animationTick) * 8;
      canvas.drawLine(Offset(vx, 0), Offset(vx, vy + 25), vinePaint);
      canvas.drawCircle(
        Offset(vx, vy + 25),
        4,
        Paint()..color = const Color(0xFF4CAF50),
      );
    }

    // Bottom lush foliage trim
    final botFramePaint = Paint()..color = const Color(0xEE08190E);
    final botPath = Path()
      ..moveTo(0, 562.5)
      ..lineTo(1000, 562.5)
      ..lineTo(1000, 520)
      ..quadraticBezierTo(750, 495, 500, 525)
      ..quadraticBezierTo(250, 490, 0, 520)
      ..close();
    canvas.drawPath(botPath, botFramePaint);
  }

  void _drawHealthBar(
    Canvas canvas,
    double ratio,
    double yOffset, {
    bool isEnemy = false,
  }) {
    const width = 36.0;
    const height = 4.5;
    final r = ratio.clamp(0.0, 1.0);

    // Background track
    final bgPaint = Paint()..color = const Color(0xAA000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, yOffset),
          width: width,
          height: height,
        ),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // Fill bar
    final fillColor = isEnemy
        ? (r > 0.5 ? const Color(0xFFEF5350) : const Color(0xFFB71C1C))
        : (r > 0.5 ? const Color(0xFF66BB6A) : const Color(0xFFFFB74D));

    final fillPaint = Paint()..color = fillColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-width / 2, yOffset - height / 2, width * r, height),
        const Radius.circular(2),
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ArenaPainter oldDelegate) => true;
}
