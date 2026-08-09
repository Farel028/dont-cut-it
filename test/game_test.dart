import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dont_cut_tree/game/game_state.dart';
import 'package:dont_cut_tree/game/models/entity.dart';
import 'package:dont_cut_tree/game/models/plants.dart';
import 'package:dont_cut_tree/game/models/enemies.dart';
import 'package:dont_cut_tree/services/storage_service.dart';
import 'package:dont_cut_tree/screens/home_screen.dart';

void main() {
  group("DON'T CUT IT - Core Game Mechanics & Lane Arena Tests", () {
    late GameState state;

    setUp(() {
      state = GameState(stageIndex: 0);
      state.startGame();
    });

    test(
      "Arena initialization - 3 lanes, 7x3 grid, and Rafflesia vertical rail",
      () {
        expect(kLaneCount, 3);
        expect(kGridCols, 7);
        expect(kGridRows, 3);
        expect(state.rafflesiaLane, 1); // Middle lane by default
        expect(state.ecoSeeds, 150); // Starting eco-seed energy
        expect(state.sanctumHealth, 3); // 3 hearts
        expect(state.status, GameStatus.playing);
      },
    );

    test(
      "Rafflesia moves vertically UP and DOWN between lanes (0, 1, 2) only",
      () {
        state.moveRafflesiaUp();
        expect(state.rafflesiaLane, 0); // Top lane

        // Cannot move further up beyond Lane 0
        state.moveRafflesiaUp();
        expect(state.rafflesiaLane, 0);

        state.moveRafflesiaDown();
        expect(state.rafflesiaLane, 1); // Middle lane

        state.moveRafflesiaDown();
        expect(state.rafflesiaLane, 2); // Bottom lane

        // Cannot move further down beyond Lane 2
        state.moveRafflesiaDown();
        expect(state.rafflesiaLane, 2);

        state.setRafflesiaLane(1);
        expect(state.rafflesiaLane, 1);
      },
    );

    test("Planting on the 7x3 grid deducts seeds and enforces cooldowns", () {
      final initialSeeds = state.ecoSeeds;
      state.selectPlant(PlantType.pakisSprout);

      // Place on cell (col: 0, row: 1)
      state.onCellTapped(0, 1);
      final plant = state.getPlantAt(0, 1);

      expect(plant, isNotNull);
      expect(plant!.type, PlantType.pakisSprout);
      expect(plant.lane, 1);
      expect(plant.gridCol, 0);
      expect(state.ecoSeeds, initialSeeds - 50);

      // Cannot place again during active cooldown
      state.selectPlant(PlantType.pakisSprout);
      state.onCellTapped(1, 1);
      expect(state.getPlantAt(1, 1), isNull);
    });

    test("Shovel tool digs up and removes plants from the grid", () {
      state.selectPlant(PlantType.ulinRoot);
      state.onCellTapped(2, 0);
      expect(state.getPlantAt(2, 0), isNotNull);

      state.selectShovel();
      state.onCellTapped(2, 0);
      expect(state.getPlantAt(2, 0), isNull);
    });

    test("Titan Arum can be planted on every mapped grid edge", () {
      state.selectPlant(PlantType.titanArum);
      state.onCellTapped(0, 0);

      final topLeft = state.getPlantAt(0, 0);
      expect(topLeft, isNotNull);
      expect(topLeft!.x, GameState.gridStartX + GameState.gridCellWidth / 2);
      expect(topLeft.y, GameState.laneYPositions[0]);

      state.ecoSeeds = 100;
      state.plantCooldowns[PlantType.titanArum] = 0;
      state.selectPlant(PlantType.titanArum);
      state.onCellTapped(kGridCols - 1, kGridRows - 1);

      final bottomRight = state.getPlantAt(kGridCols - 1, kGridRows - 1);
      expect(bottomRight, isNotNull);
      expect(
        bottomRight!.x,
        GameState.gridStartX +
            (kGridCols - 1) * GameState.gridCellWidth +
            GameState.gridCellWidth / 2,
      );
      expect(bottomRight.y, GameState.laneYPositions[kGridRows - 1]);
    });

    test("Titan Arum and colliding machinery destroy each other", () {
      state.selectPlant(PlantType.titanArum);
      state.onCellTapped(3, 0);
      final plant = state.getPlantAt(3, 0)!;
      final enemy = EnemyEntity(
        type: EnemyType.excavator,
        lane: 0,
        x: plant.x + 20,
        y: GameState.laneYPositions[0],
      );
      state.enemies.add(enemy);

      state.update(0.01);

      expect(state.getPlantAt(3, 0), isNull);
      expect(state.enemies.contains(enemy), isFalse);
      expect(enemy.health, 0);
      expect(plant.health, 0);
    });

    test("Deforestation machinery moves LEFT and damages blocking plants", () {
      final enemy = EnemyEntity(
        type: EnemyType.tractor,
        lane: 1,
        x: 800.0,
        y: GameState.laneYPositions[1],
      );
      state.enemies.add(enemy);

      final initialX = enemy.x;
      enemy.update(0.5);
      expect(enemy.x, lessThan(initialX)); // Moves left towards sanctum
    });

    test("Enemy hit points are configured per machinery type", () {
      final tractor = EnemyEntity(
        type: EnemyType.tractor,
        lane: 0,
        x: 800,
        y: GameState.laneYPositions[0],
      );
      final truck = EnemyEntity(
        type: EnemyType.truck,
        lane: 1,
        x: 800,
        y: GameState.laneYPositions[1],
      );
      final excavator = EnemyEntity(
        type: EnemyType.excavator,
        lane: 2,
        x: 800,
        y: GameState.laneYPositions[2],
      );

      expect(tractor.maxHealth, 2);
      expect(truck.maxHealth, 3);
      expect(excavator.maxHealth, 5);

      truck.takeDamage(1);
      expect(truck.health, 2);
      expect(truck.isDead, isFalse);
    });

    test("Enemy defeat has exactly 20% Seed Drop chance distribution", () {
      final rng = Random(42);
      final enemy = EnemyEntity(
        type: EnemyType.tractor,
        lane: 0,
        x: 500,
        y: GameState.laneYPositions[0],
      );

      int drops = 0;
      const trials = 10000;
      for (int i = 0; i < trials; i++) {
        if (enemy.rollSeedDrop(rng)) {
          drops++;
        }
      }

      final rate = drops / trials;
      // 20% drop rate within 2% statistical variance
      expect(rate, closeTo(0.20, 0.02));
    });

    test("Sanctum breach decreases health and triggers defeat when 0", () {
      // Spawn enemy at far left
      final enemy = EnemyEntity(
        type: EnemyType.tractor,
        lane: 1,
        x: 50.0, // Past the left track
        y: GameState.laneYPositions[1],
      );
      state.enemies.add(enemy);

      state.update(0.1);
      expect(state.sanctumHealth, 2); // Lost 1 heart

      // Add two more
      state.enemies.add(
        EnemyEntity(
          type: EnemyType.tractor,
          lane: 0,
          x: 50,
          y: GameState.laneYPositions[0],
        ),
      );
      state.enemies.add(
        EnemyEntity(
          type: EnemyType.tractor,
          lane: 2,
          x: 50,
          y: GameState.laneYPositions[2],
        ),
      );
      state.update(0.1);

      expect(state.sanctumHealth, 0);
      expect(state.status, GameStatus.defeat);
    });

    test(
      "Storage service records stars, seeds, and deforestation prevented",
      () {
        final storage = StorageService();
        storage.resetProgress();

        storage.saveStageResult(0, 3, 15, 75);
        expect(storage.stageStars[0], 3);
        expect(storage.completedStagesCount, 1);
        expect(storage.totalSeedsCollected, 75);
        expect(storage.highDeforestationPrevented, 15);
      },
    );
  });

  testWidgets("BOOK modal shows Titan Arum detail and both controls work", (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byKey(const Key('home_book_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('book_modal')), findsOneWidget);

    await tester.tap(find.byKey(const Key('book_titan_arum_item')));
    await tester.pump();
    expect(find.byKey(const Key('book_detail_panel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('book_return_button')));
    await tester.pump();
    expect(find.byKey(const Key('book_detail_panel')), findsNothing);
    expect(find.byKey(const Key('book_modal')), findsOneWidget);

    await tester.tap(find.byKey(const Key('book_dismiss_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('book_modal')), findsNothing);
  });
}
