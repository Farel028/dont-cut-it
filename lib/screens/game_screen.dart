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
import 'settings_screen.dart';

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

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
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
                            ..._buildPlantingCells(arenaWidth, arenaHeight),
                            ..._buildPlantSprites(arenaWidth, arenaHeight),
                            ..._buildEnemySprites(arenaWidth, arenaHeight),
                            ..._buildProjectileSprites(
                              arenaWidth,
                              arenaHeight,
                            ),
                            ..._buildSeedDropSprites(arenaWidth, arenaHeight),
                            _buildRafflesiaSprite(arenaWidth, arenaHeight),
                            _buildRightForeground(arenaWidth, arenaHeight),
                            _buildImageWaveHud(arenaWidth, arenaHeight),
                            _buildInventory(arenaWidth),
                            _buildPauseButton(arenaWidth),
                            if (_gameState.status == GameStatus.paused)
                              _buildPauseOverlay(arenaWidth),
                            if (_gameState.status == GameStatus.victory)
                              _buildVictoryOverlay(arenaWidth),
                            if (_gameState.status == GameStatus.defeat)
                              _buildDefeatOverlay(arenaWidth),
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

  Widget _buildRightForeground(double arenaWidth, double arenaHeight) {
    return Positioned(
      key: const Key('right_foreground_overlay'),
      right: -arenaWidth * 0.003,
      bottom: -arenaHeight * 0.075,
      width: arenaWidth * 0.385,
      height: arenaHeight * 0.522,
      child: IgnorePointer(
        child: Image.asset(
          'assets/images/rscreen-map.png',
          key: const Key('right_foreground_image'),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
          cacheWidth: 1000,
          gaplessPlayback: true,
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
            // Cendana Scent Aura visual cloud around enemy when in 3x3 range
            if (enemy.hasCendanaAura)
              Positioned(
                left: -width * 0.35,
                top: -height * 0.55,
                width: width * 1.7,
                height: height * 1.7,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.85,
                    child: Image.asset(
                      'assets/images/trees/cendanaaura.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),

            // Main Enemy Sprite
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
    // 2x larger tree sizing to fill the tile ground and canopy
    final plantWidthNorm = GameState.gridCellWidth * 1.64;
    final plantHeightNorm = GameState.gridCellHeight * 1.32;

    return _gameState.gridPlants
        .whereType<PlantEntity>()
        .where((plant) => !plant.isDead)
        .map((plant) {
      // Cendana given an additional scale to stand tall and prominent
      final scale = (plant.type == PlantType.cendana) ? 1.38 : 1.0;
      final width =
          (plantWidthNorm * scale) / GameState.arenaWidth * arenaWidth;
      final height =
          (plantHeightNorm * scale) / GameState.arenaHeight * arenaHeight;
      final left = plant.x / GameState.arenaWidth * arenaWidth - width / 2;
      // Anchor base of tree to the soil tile
      final top = (plant.y + GameState.gridCellHeight * 0.36) /
              GameState.arenaHeight *
              arenaHeight -
          height;

      return Positioned(
        key: ObjectKey(plant),
        left: left,
        top: top,
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Plant Sprite
            Positioned.fill(
              child: Image.asset(
                plant.info.assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                cacheWidth: 420,
                gaplessPlayback: true,
              ),
            ),

            // Meranti Canopy Shield overlay
            if (plant.shieldAmount > 0)
              Positioned(
                left: width * 0.62,
                top: height * 0.15,
                width: width * 0.38,
                height: width * 0.38,
                child: Image.asset(
                  'assets/images/trees/meratishield.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                ),
              ),

            // Gaharu Healing Resin aura overlay
            if (plant.healEffectTimer > 0)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/trees/healgaharu.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                ),
              ),

            // Health bar if plant is damaged
            if (plant.health < plant.maxHealth)
              Positioned(
                left: width * 0.18,
                right: width * 0.18,
                top: -8,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(3),
                    border:
                        Border.all(color: const Color(0xFF3E2723), width: 1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        (plant.health / plant.maxHealth).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
        .where((projectile) => !projectile.isDead)
        .map((projectile) {
      final size =
          (projectile.type == ProjectileType.rafflesiaSpore ? 34.0 : 28.0) /
              GameState.arenaWidth *
              arenaWidth;
      final left = projectile.x / GameState.arenaWidth * arenaWidth - size / 2;
      final top = projectile.y / GameState.arenaHeight * arenaHeight - size / 2;

      Widget projectileWidget;
      if (projectile.type == ProjectileType.rafflesiaSpore) {
        projectileWidget = Image.asset(
          'assets/images/ammon.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          cacheWidth: 96,
          gaplessPlayback: true,
        );
      } else if (projectile.type == ProjectileType.damarResin) {
        projectileWidget = Image.asset(
          'assets/images/trees/damarammo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          cacheWidth: 96,
          gaplessPlayback: true,
        );
      } else {
        // sonokelingShard
        projectileWidget = Image.asset(
          'assets/images/trees/sonokelingammo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          cacheWidth: 96,
          gaplessPlayback: true,
        );
      }

      return Positioned(
        key: ObjectKey(projectile),
        left: left,
        top: top,
        width: size,
        height: size,
        child: projectileWidget,
      );
    }).toList();
  }

  List<Widget> _buildSeedDropSprites(
    double arenaWidth,
    double arenaHeight,
  ) {
    return _gameState.droppedSeeds
        .where((drop) => !drop.isCollected)
        .map((drop) {
      final size = (arenaWidth * 0.068).clamp(52.0, 72.0).toDouble();
      final left = drop.x / GameState.arenaWidth * arenaWidth - size / 2;
      final top =
          (drop.y + drop.renderYOffset) / GameState.arenaHeight * arenaHeight -
              size / 2;
      final plantInfo =
          kPlantCatalog.firstWhere((p) => p.type == drop.plantType);

      return Positioned(
        key: ObjectKey(drop),
        left: left,
        top: top,
        width: size,
        height: size,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _gameState.collectSeed(drop),
            onTapDown: (_) => _gameState.collectSeed(drop),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/dropped.png',
                    key: ObjectKey(('dropped_frame', drop)),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.none,
                    cacheWidth: 180,
                    gaplessPlayback: true,
                  ),
                ),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.46,
                    heightFactor: 0.46,
                    child: Image.asset(
                      plantInfo.assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      cacheWidth: 120,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                Positioned(
                  right: size * 0.12,
                  bottom: size * 0.12,
                  child: IgnorePointer(
                    child: Text(
                      '+1',
                      style: _itemCounterTextStyle(
                        fontSize: (size * 0.20).clamp(10.0, 14.0).toDouble(),
                        hasItems: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildVictoryOverlay(double arenaWidth) {
    final modalWidth = math.min(380.0, arenaWidth * 0.48);

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0000000),
        child: Center(
          child: Container(
            width: modalWidth,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B4332), Color(0xFF081C15)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD54F), width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x992D6A4F), blurRadius: 28, spreadRadius: 3),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded,
                        color: Color(0xFFFFD54F), size: 36),
                    Icon(Icons.star_rounded,
                        color: Color(0xFFFFD54F), size: 44),
                    Icon(Icons.star_rounded,
                        color: Color(0xFFFFD54F), size: 36),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'HUTAN TERSALAMATKAN!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kamu berhasil melindungi keanekaragaman hayati Indonesia dengan Skor ${_gameState.score}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD8F3DC),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _gameState.resetGame();
                      _gameState.startGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF74C69D)),
                      ),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text(
                      'MAIN LAGI',
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
                      foregroundColor: const Color(0xFFFFD54F),
                      side: const BorderSide(color: Color(0xFFFFD54F)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      'KEMBALI KE BERANDA',
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

  Widget _buildDefeatOverlay(double arenaWidth) {
    final modalWidth = math.min(380.0, arenaWidth * 0.48);

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0000000),
        child: Center(
          child: Container(
            width: modalWidth,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3E1F18), Color(0xFF1E0A06)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF7043), width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x99BF360C), blurRadius: 28, spreadRadius: 3),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF8A65),
                  size: 46,
                ),
                const SizedBox(height: 8),
                const Text(
                  'HUTAN TERANCAM!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFAB91),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mesin penebang berhasil menembus pertahanan. Coba lagi dan susun strategi pohon yang lebih kuat!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFCCBC),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _gameState.resetGame();
                      _gameState.startGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD84315),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'COBA LAGI',
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
                      foregroundColor: const Color(0xFFFFAB91),
                      side: const BorderSide(color: Color(0xFFFF7043)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      'KEMBALI KE BERANDA',
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

  Widget _buildImageWaveHud(double arenaWidth, double arenaHeight) {
    final hudWidth = (arenaWidth * 0.48).clamp(310.0, 560.0).toDouble();
    final hudHeight = hudWidth / 4.3;
    final heartSize = math.min(
      (hudWidth * 0.175 / 3) - (hudWidth * 0.008),
      hudHeight * 0.30,
    );
    final waveProgress = _gameState.waveProgress.clamp(0.0, 1.0);

    return Positioned(
      key: const Key('wave_hud'),
      top: arenaHeight * 0.004,
      left: (arenaWidth - hudWidth) / 2,
      width: hudWidth,
      height: hudHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/waves.png',
              key: const Key('wave_background'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.none,
              cacheWidth: 1500,
            ),
          ),
          Positioned(
            key: const Key('wave_heart_status'),
            left: hudWidth * 0.145,
            top: hudHeight * 0.29,
            width: hudWidth * 0.175,
            height: hudHeight * 0.30,
            child: Row(
              children: List.generate(3, (index) {
                final isAlive = index < _gameState.sanctumHealth;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hudWidth * 0.004),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _WaveHeart(
                          key: Key('wave_heart_$index'),
                          filled: isAlive,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Positioned(
            key: const Key('wave_label'),
            left: hudWidth * 0.345,
            top: hudHeight * 0.285,
            width: hudWidth * 0.335,
            height: hudHeight * 0.31,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'GELOMBANG ${_gameState.currentWave}/${_gameState.stageConfig.totalWaves}',
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFFFFE7A3),
                  fontFamily: 'LilitaOne',
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(color: Color(0xFF2A130B), offset: Offset(-2, 0)),
                    Shadow(color: Color(0xFF2A130B), offset: Offset(2, 0)),
                    Shadow(color: Color(0xFF2A130B), offset: Offset(0, -2)),
                    Shadow(color: Color(0xFF2A130B), offset: Offset(0, 2)),
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 3),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            key: const Key('wave_progress'),
            left: hudWidth * 0.318,
            top: hudHeight * 0.615,
            width: hudWidth * 0.365,
            height: hudHeight * 0.13,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF32170D),
                borderRadius: BorderRadius.circular(hudHeight * 0.055),
                border: Border.all(
                  color: const Color(0xFF8C4A25),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    offset: Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(hudHeight * 0.025),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(hudHeight * 0.03),
                  child: ColoredBox(
                    color: const Color(0xFF130D09),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: waveProgress,
                        heightFactor: 1,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFB9F257), Color(0xFF58A92C)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            key: const Key('wave_tree_score'),
            left: hudWidth * 0.705,
            top: hudHeight * 0.25,
            width: hudWidth * 0.18,
            height: hudHeight * 0.38,
            child: Row(
              children: [
                SizedBox(
                  width: heartSize,
                  height: heartSize,
                  child: ClipRect(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(2.75, 1.70, 1),
                      child: Image.asset(
                        'assets/images/icon-tree.png',
                        key: const Key('wave_tree_icon'),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.none,
                        cacheWidth: 220,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: hudWidth * 0.008),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_gameState.score}',
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFFFFD76A),
                        fontFamily: 'LilitaOne',
                        fontSize: 25,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Color(0xFF2A130B),
                            offset: Offset(-2, 0),
                          ),
                          Shadow(
                            color: Color(0xFF2A130B),
                            offset: Offset(2, 0),
                          ),
                          Shadow(
                            color: Color(0xFF2A130B),
                            offset: Offset(0, -2),
                          ),
                          Shadow(
                            color: Color(0xFF2A130B),
                            offset: Offset(0, 2),
                          ),
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(0, 3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    final inventoryWidth = math.min(390.0, arenaWidth * 0.36);
    final inventoryHeight = inventoryWidth * 373 / 669;

    // Slot layout offsets mapped to the 5 frames in inventory.png
    const slotXPositions = [88.0, 191.0, 294.0, 396.0, 499.0];
    const hitboxXPositions = [76.0, 179.0, 282.0, 384.0, 487.0];

    final deck = _gameState.activeDeck;

    return Positioned(
      key: const Key('game_inventory'),
      left: (arenaWidth - inventoryWidth) / 2,
      bottom: -inventoryHeight * 0.28,
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
          for (int i = 0; i < deck.length && i < 5; i++) ...[
            _buildInventorySlot(
              i,
              deck[i],
              inventoryWidth,
              inventoryHeight,
              slotXPositions[i],
              hitboxXPositions[i],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventorySlot(
    int index,
    PlantType type,
    double inventoryWidth,
    double inventoryHeight,
    double slotX,
    double hitboxX,
  ) {
    final info = kPlantCatalog.firstWhere((p) => p.type == type);
    final count = _gameState.getCardCount(type);
    final canSelect = _gameState.canAfford(type);
    final isSelected = _gameState.selectedPlantType == type;
    final cooldownRemaining = _gameState.plantCooldowns[type] ?? 0.0;

    return Stack(
      key: Key('inventory_slot_$index'),
      children: [
        Positioned(
          left: inventoryWidth * slotX / 669,
          top: inventoryHeight * 90 / 373,
          width: inventoryWidth * 82 / 669,
          height: inventoryHeight * 122 / 373,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: count > 0 ? (canSelect ? 1.0 : 0.6) : 0.28,
            child: Stack(
              children: [
                Center(
                  child: Image.asset(
                    info.assetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    cacheWidth: 180,
                    gaplessPlayback: true,
                  ),
                ),
                if (cooldownRemaining > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x88000000),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${cooldownRemaining.toStringAsFixed(1)}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          left: inventoryWidth * hitboxX / 669,
          top: inventoryHeight * 80 / 373,
          width: inventoryWidth * 104 / 669,
          height: inventoryHeight * 144 / 373,
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
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    button: true,
                    label: '${info.indonesianName}, Jumlah: $count',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _gameState.selectPlant(type),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: inventoryWidth * 7 / 669,
                  bottom: inventoryHeight * 9 / 373,
                  child: IgnorePointer(
                    child: Text(
                      'x$count',
                      key: Key('inventory_counter_$index'),
                      style: _itemCounterTextStyle(
                        fontSize: (inventoryWidth * 0.035)
                            .clamp(11.0, 15.0)
                            .toDouble(),
                        hasItems: count > 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _itemCounterTextStyle({
    required double fontSize,
    required bool hasItems,
  }) {
    return TextStyle(
      color: hasItems ? const Color(0xFFFFE3A0) : const Color(0xFFAA9581),
      fontFamily: 'LilitaOne',
      fontSize: fontSize,
      letterSpacing: 0.2,
      shadows: const [
        Shadow(color: Color(0xFF2A130B), offset: Offset(-1, -1)),
        Shadow(color: Color(0xFF2A130B), offset: Offset(1, -1)),
        Shadow(color: Color(0xFF2A130B), offset: Offset(-1, 1)),
        Shadow(color: Color(0xFF2A130B), offset: Offset(1, 1)),
        Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 2),
      ],
    );
  }

  Widget _buildPauseButton(double arenaWidth) {
    final size = (arenaWidth * 0.068).clamp(48.0, 76.0).toDouble();

    return Positioned(
      top: arenaWidth * 0.006,
      right: arenaWidth * 0.008,
      width: size,
      height: size,
      child: Semantics(
        button: true,
        label: 'Pause',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: const Key('game_pause_button'),
            behavior: HitTestBehavior.opaque,
            onTap: _gameState.pauseGame,
            child: Image.asset(
              'assets/images/pause.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.none,
              cacheWidth: 220,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(double arenaWidth) {
    final modalWidth = math.min(760.0, arenaWidth * 0.78);
    final modalHeight = modalWidth * 1024 / 1536;

    return Positioned.fill(
      key: const Key('pause_modal'),
      child: ColoredBox(
        color: const Color(0x99000000),
        child: Center(
          child: SizedBox(
            width: modalWidth,
            height: modalHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/paused.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    cacheWidth: 1200,
                  ),
                ),
                _buildPauseMenuHitbox(
                  key: const Key('pause_resume_button'),
                  label: 'Resume',
                  top: 0.296,
                  modalWidth: modalWidth,
                  modalHeight: modalHeight,
                  onTap: _gameState.resumeGame,
                ),
                _buildPauseMenuHitbox(
                  key: const Key('pause_settings_button'),
                  label: 'Settings',
                  top: 0.478,
                  modalWidth: modalWidth,
                  modalHeight: modalHeight,
                  onTap: _openSettings,
                ),
                _buildPauseMenuHitbox(
                  key: const Key('pause_home_button'),
                  label: 'Home',
                  top: 0.661,
                  modalWidth: modalWidth,
                  modalHeight: modalHeight,
                  onTap: _goHome,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseMenuHitbox({
    required Key key,
    required String label,
    required double top,
    required double modalWidth,
    required double modalHeight,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: modalWidth * 0.294,
      top: modalHeight * top,
      width: modalWidth * 0.414,
      height: modalHeight * 0.148,
      child: Semantics(
        button: true,
        label: label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: key,
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _WaveHeart extends StatelessWidget {
  const _WaveHeart({super.key, required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _WaveHeartPainter(filled)),
    );
  }
}

class _WaveHeartPainter extends CustomPainter {
  const _WaveHeartPainter(this.filled);

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.50, size.height * 0.94)
      ..lineTo(size.width * 0.10, size.height * 0.55)
      ..lineTo(size.width * 0.10, size.height * 0.31)
      ..lineTo(size.width * 0.22, size.height * 0.16)
      ..lineTo(size.width * 0.38, size.height * 0.16)
      ..lineTo(size.width * 0.50, size.height * 0.29)
      ..lineTo(size.width * 0.62, size.height * 0.16)
      ..lineTo(size.width * 0.78, size.height * 0.16)
      ..lineTo(size.width * 0.90, size.height * 0.31)
      ..lineTo(size.width * 0.90, size.height * 0.55)
      ..close();

    canvas.drawShadow(path, const Color(0xCC000000), 2.5, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = filled ? const Color(0xFFFF425B) : const Color(0xFF183A2A)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A2417)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.shortestSide * 0.10).clamp(2.0, 4.0)
        ..strokeJoin = StrokeJoin.round,
    );

    if (filled) {
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * 0.24,
          size.height * 0.25,
          size.width * 0.14,
          size.height * 0.16,
        ),
        Paint()..color = const Color(0xFFFFA5AF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveHeartPainter oldDelegate) {
    return oldDelegate.filled != filled;
  }
}
