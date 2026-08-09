import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_state.dart';
import '../game/models/entity.dart';
import '../game/models/enemies.dart';
import '../game/models/plants.dart';
import '../game/models/projectiles.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';

/// Image-only gameplay arena.
///
/// The arena renders image assets only, with a lightweight pause control.
class GameScreen extends StatefulWidget {
  final int stageIndex;

  const GameScreen({super.key, this.stageIndex = 0});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameState _gameState;
  final StorageService _storage = StorageService();

  Timer? _gameLoopTimer;
  double _dragY = GameState.lane1Y;
  bool _gameEndHandled = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameState(stageIndex: widget.stageIndex)..startGame();

    // 30 FPS is enough for the pixel-art scene and is considerably lighter
    // than repainting at 60 FPS on Flutter Web.
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted) return;
      _gameState.update(0.033);

      if (!_gameEndHandled &&
          (_gameState.status == GameStatus.victory ||
              _gameState.status == GameStatus.defeat)) {
        _gameEndHandled = true;
        _gameLoopTimer?.cancel();
        _handleGameEnd();
      }
    });
  }

  void _handleGameEnd() {
    final isVictory = _gameState.status == GameStatus.victory;
    final stars = isVictory
        ? (_gameState.sanctumHealth == 3
            ? 3
            : (_gameState.sanctumHealth == 2 ? 2 : 1))
        : 0;

    _storage.saveStageResult(
      widget.stageIndex,
      stars,
      _gameState.enemiesDefeated,
      _gameState.seedsCollectedThisMatch,
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            isVictory: isVictory,
            stageIndex: widget.stageIndex,
            enemiesDefeated: _gameState.enemiesDefeated,
            deforestationPreventedHa: _gameState.deforestationPreventedHa,
            seedsCollected: _gameState.seedsCollectedThisMatch,
            sanctumHealthRemaining: _gameState.sanctumHealth,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    super.dispose();
  }

  double get _rafflesiaY {
    final value = _gameState.rafflesiaVisualY.clamp(0.0, 2.0);
    if (value <= 1) {
      return GameState.lane0Y + (GameState.lane1Y - GameState.lane0Y) * value;
    }
    return GameState.lane1Y +
        (GameState.lane2Y - GameState.lane1Y) * (value - 1);
  }

  void _startRafflesiaDrag() {
    _dragY = GameState.laneYPositions[_gameState.rafflesiaLane];
  }

  void _updateRafflesiaDrag(DragUpdateDetails details, double arenaHeight) {
    _dragY += details.delta.dy / arenaHeight * GameState.arenaHeight;
    _dragY = _dragY.clamp(GameState.lane0Y, GameState.lane2Y);

    var nearestLane = 0;
    var nearestDistance = double.infinity;
    for (var lane = 0; lane < GameState.laneYPositions.length; lane++) {
      final distance = (_dragY - GameState.laneYPositions[lane]).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestLane = lane;
      }
    }
    _gameState.setRafflesiaLane(nearestLane);
  }

  void _togglePause() {
    if (_gameState.status == GameStatus.playing) {
      _gameState.pauseGame();
    } else if (_gameState.status == GameStatus.paused) {
      _gameState.resumeGame();
    }
  }

  void _goHome() {
    _gameLoopTimer?.cancel();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            _gameState.moveRafflesiaUp,
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            _gameState.moveRafflesiaDown,
        const SingleActivator(LogicalKeyboardKey.keyW):
            _gameState.moveRafflesiaUp,
        const SingleActivator(LogicalKeyboardKey.keyS):
            _gameState.moveRafflesiaDown,
        const SingleActivator(LogicalKeyboardKey.escape): _togglePause,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: AnimatedBuilder(
            animation: _gameState,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  var arenaWidth = constraints.maxWidth;
                  var arenaHeight =
                      arenaWidth * GameState.arenaHeight / GameState.arenaWidth;
                  if (arenaHeight > constraints.maxHeight) {
                    arenaHeight = constraints.maxHeight;
                    arenaWidth = arenaHeight *
                        GameState.arenaWidth /
                        GameState.arenaHeight;
                  }

                  return Center(
                    child: SizedBox(
                      width: arenaWidth,
                      height: arenaHeight,
                      child: ClipRect(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/map.png',
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.none,
                                cacheWidth: 1600,
                              ),
                            ),
                            ..._buildPlantSprites(arenaWidth, arenaHeight),
                            ..._buildEnemySprites(arenaWidth, arenaHeight),
                            ..._buildProjectileSprites(
                              arenaWidth,
                              arenaHeight,
                            ),
                            ..._buildPlantingCells(arenaWidth, arenaHeight),
                            _buildRafflesiaSprite(arenaWidth, arenaHeight),
                            _buildInventory(arenaWidth),
                            _buildPauseButton(arenaWidth),
                            if (_gameState.status == GameStatus.paused)
                              _buildPauseOverlay(arenaWidth),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRafflesiaSprite(double arenaWidth, double arenaHeight) {
    final width = arenaWidth * 0.082;
    final height = width;
    final left =
        GameState.trackX / GameState.arenaWidth * arenaWidth - width / 2;
    final top = _rafflesiaY / GameState.arenaHeight * arenaHeight - height / 2;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _startRafflesiaDrag(),
        onVerticalDragUpdate: (details) =>
            _updateRafflesiaDrag(details, arenaHeight),
        child: Image.asset(
          'assets/images/rafflesia.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          cacheWidth: 240,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  List<Widget> _buildEnemySprites(double arenaWidth, double arenaHeight) {
    return _gameState.enemies.where((enemy) => !enemy.isDead).map((enemy) {
      final dimensions = _enemyDimensions(enemy.type);
      final width = dimensions.$1 / GameState.arenaWidth * arenaWidth;
      final height = dimensions.$2 / GameState.arenaHeight * arenaHeight;
      final left = enemy.x / GameState.arenaWidth * arenaWidth - width / 2;
      final top = enemy.y / GameState.arenaHeight * arenaHeight - height / 2;

      return Positioned(
        key: ObjectKey(enemy),
        left: left,
        top: top,
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(
                enemy.info.assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                cacheWidth: 360,
                gaplessPlayback: true,
              ),
            ),
            _buildEnemyHealthBar(enemy, width),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPlantSprites(double arenaWidth, double arenaHeight) {
    final plantSize = GameState.gridCellWidth * 0.78;

    return _gameState.gridPlants
        .whereType<PlantEntity>()
        .where(
          (plant) => !plant.isDead && plant.type == PlantType.titanArum,
        )
        .map((plant) {
      final width = plantSize / GameState.arenaWidth * arenaWidth;
      final height = plantSize / GameState.arenaHeight * arenaHeight;
      final left = plant.x / GameState.arenaWidth * arenaWidth - width / 2;
      final top = plant.y / GameState.arenaHeight * arenaHeight - height / 2;

      return Positioned(
        key: ObjectKey(plant),
        left: left,
        top: top,
        width: width,
        height: height,
        child: Image.asset(
          'assets/images/titan_arum.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          cacheWidth: 180,
          gaplessPlayback: true,
        ),
      );
    }).toList();
  }

  List<Widget> _buildPlantingCells(double arenaWidth, double arenaHeight) {
    final cellWidth =
        GameState.gridCellWidth / GameState.arenaWidth * arenaWidth;
    final cellHeight =
        GameState.gridCellHeight / GameState.arenaHeight * arenaHeight;

    return [
      for (var row = 0; row < kGridRows; row++)
        for (var col = 0; col < kGridCols; col++)
          Positioned(
            left: (GameState.gridStartX + col * GameState.gridCellWidth) /
                GameState.arenaWidth *
                arenaWidth,
            top:
                (GameState.laneYPositions[row] - GameState.gridCellHeight / 2) /
                    GameState.arenaHeight *
                    arenaHeight,
            width: cellWidth,
            height: cellHeight,
            child: Semantics(
              button: true,
              label: 'Tile tanaman baris ${row + 1}, kolom ${col + 1}',
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _gameState.onCellTapped(col, row),
              ),
            ),
          ),
    ];
  }

  List<Widget> _buildProjectileSprites(
    double arenaWidth,
    double arenaHeight,
  ) {
    return _gameState.projectiles
        .where(
      (projectile) =>
          !projectile.isDead &&
          projectile.type == ProjectileType.rafflesiaSpore,
    )
        .map((projectile) {
      final size = 34 / GameState.arenaWidth * arenaWidth;
      final left = projectile.x / GameState.arenaWidth * arenaWidth - size / 2;
      final top = projectile.y / GameState.arenaHeight * arenaHeight - size / 2;

      return Positioned(
        key: ObjectKey(projectile),
        left: left,
        top: top,
        width: size,
        height: size,
        child: Image.asset(
          'assets/images/ammon.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          cacheWidth: 96,
          gaplessPlayback: true,
        ),
      );
    }).toList();
  }

  (double, double) _enemyDimensions(EnemyType type) {
    return switch (type) {
      EnemyType.tractor => (118, 81),
      EnemyType.truck => (132, 68),
      EnemyType.excavator => (86, 86),
    };
  }

  Widget _buildEnemyHealthBar(EnemyEntity enemy, double spriteWidth) {
    final maxHealth = enemy.maxHealth.round();
    final currentHealth = enemy.health.ceil().clamp(0, maxHealth);
    final ratio = maxHealth == 0 ? 0.0 : currentHealth / maxHealth;
    final fillColor = ratio > 0.6
        ? const Color(0xFF7CB342)
        : (ratio > 0.3 ? const Color(0xFFFFB300) : const Color(0xFFE53935));
    final barWidth = math.min(spriteWidth * 0.82, 92.0);

    return Positioned(
      left: (spriteWidth - barWidth) / 2,
      top: -9,
      width: barWidth,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2B1A12),
          border: Border.all(color: const Color(0xFF6D4026), width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Row(
            children: List.generate(maxHealth, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: index == 0 ? 0 : 1),
                  color: index < currentHealth
                      ? fillColor
                      : const Color(0xFF4A3025),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildInventory(double arenaWidth) {
    final inventoryWidth = math.min(360.0, arenaWidth * 0.33);
    final inventoryHeight = inventoryWidth * 373 / 669;
    final canSelect = _gameState.canAfford(PlantType.titanArum);
    final isSelected = _gameState.selectedPlantType == PlantType.titanArum;

    return Positioned(
      top: -arenaWidth * 0.004,
      left: arenaWidth * 0.008,
      width: inventoryWidth,
      height: inventoryHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/inventory.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              cacheWidth: 700,
            ),
          ),
          Positioned(
            left: inventoryWidth * 89 / 669,
            top: inventoryHeight * 94 / 373,
            width: inventoryWidth * 80 / 669,
            height: inventoryHeight * 118 / 373,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: canSelect ? 1 : 0.32,
              child: Image.asset(
                'assets/images/titan_arum.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                cacheWidth: 180,
                gaplessPlayback: true,
              ),
            ),
          ),
          Positioned(
            left: inventoryWidth * 77 / 669,
            top: inventoryHeight * 83 / 373,
            width: inventoryWidth * 105 / 669,
            height: inventoryHeight * 140 / 373,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFFFFD54F) : Colors.transparent,
                  width: isSelected ? 3 : 0,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0xAAFFD54F),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: Semantics(
                button: true,
                enabled: canSelect,
                selected: isSelected,
                label: 'Titan Arum seed',
                child: MouseRegion(
                  cursor: canSelect
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: canSelect
                        ? () => _gameState.selectPlant(PlantType.titanArum)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton(double arenaWidth) {
    final size = (arenaWidth * 0.045).clamp(38.0, 54.0).toDouble();

    return Positioned(
      top: arenaWidth * 0.014,
      right: arenaWidth * 0.014,
      width: size,
      height: size,
      child: IconButton.filled(
        onPressed: _gameState.pauseGame,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xDD4E2F1B),
          foregroundColor: const Color(0xFFFFE0A3),
          side: const BorderSide(color: Color(0xFFFFB85C), width: 2),
        ),
        icon: const Icon(Icons.pause_rounded),
        tooltip: 'Pause',
      ),
    );
  }

  Widget _buildPauseOverlay(double arenaWidth) {
    final modalWidth = math.min(330.0, arenaWidth * 0.42);

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xB3000000),
        child: Center(
          child: Container(
            width: modalWidth,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF2B1A12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFB85C), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 20),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_circle_filled_rounded,
                  color: Color(0xFFFFD180),
                  size: 46,
                ),
                const SizedBox(height: 8),
                const Text(
                  'GAME PAUSED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _gameState.resumeGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'LANJUTKAN',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _goHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD180),
                      side: const BorderSide(color: Color(0xFFFFB85C)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      'KEMBALI KE HOME',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
