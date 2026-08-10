import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dont_cut_tree/game/game_state.dart';
import 'package:dont_cut_tree/game/models/entity.dart';
import 'package:dont_cut_tree/game/models/plants.dart';
import 'package:dont_cut_tree/game/models/enemies.dart';
import 'package:dont_cut_tree/game/models/projectiles.dart';
import 'package:dont_cut_tree/services/storage_service.dart';
import 'package:dont_cut_tree/screens/home_screen.dart';
import 'package:dont_cut_tree/screens/game_screen.dart';

void main() {
  group("DON'T CUT IT - Flora Deck, Enemy Stats & Card Drop System Tests", () {
    late GameState state;

    setUp(() {
      StorageService().resetProgress();
      state = GameState(stageIndex: 0);
      state.startGame();
    });

    test(
        "Catalog contains exactly 8 Indonesian flora species including Damar (no Rafflesia in book)",
        () {
      expect(kPlantCatalog.length, 8);
      final plantTypes = kPlantCatalog.map((p) => p.type).toList();
      expect(plantTypes.contains(PlantType.damar), isTrue);
      expect(plantTypes.contains(PlantType.titanArum), isTrue);
      expect(plantTypes.contains(PlantType.kantongSemar), isTrue);
      expect(plantTypes.contains(PlantType.cendana), isTrue);
      expect(plantTypes.contains(PlantType.eboni), isTrue);
      expect(plantTypes.contains(PlantType.gaharu), isTrue);
      expect(plantTypes.contains(PlantType.meranti), isTrue);
      expect(plantTypes.contains(PlantType.sonokeling), isTrue);

      for (final plant in kPlantCatalog) {
        expect(plant.assetPath, isNotEmpty);
        expect(plant.maxHp, greaterThan(0));
        expect(plant.about, isNotEmpty);
        expect(plant.abilityName, isNotEmpty);
        expect(plant.abilityDescription, isNotEmpty);
        expect(plant.status, isNotEmpty);
      }
    });

    test("Initial state gives player cards for active deck (no sun currency)",
        () {
      expect(state.activeDeck.length, 5);
      for (final type in state.activeDeck) {
        expect(state.getCardCount(type), greaterThan(0));
      }
    });

    test("Planting consumes 1 card and applies cooldown", () {
      final initialCendanaCards = state.getCardCount(PlantType.cendana);
      state.selectPlant(PlantType.cendana);

      // Place Cendana on cell (col: 0, row: 1)
      state.onCellTapped(0, 1);
      final plant = state.getPlantAt(0, 1);

      expect(plant, isNotNull);
      expect(plant!.type, PlantType.cendana);
      expect(plant.lane, 1);
      expect(plant.gridCol, 0);
      expect(state.getCardCount(PlantType.cendana), initialCendanaCards - 1);
      expect(state.plantCooldowns[PlantType.cendana], greaterThan(0));

      // Cannot place again during active cooldown
      state.selectPlant(PlantType.cendana);
      state.onCellTapped(1, 1);
      expect(state.getPlantAt(1, 1), isNull);
    });

    test("Enemies have exact stats from deskripsi.md", () {
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

      // Traktor: Attack 2, HP 4
      expect(tractor.info.attackDamage, 2.0);
      expect(tractor.maxHealth, 4.0);

      // Truk: Attack 1, HP 5
      expect(truck.info.attackDamage, 1.0);
      expect(truck.maxHealth, 5.0);

      // Ekskavator: Attack 3, HP 3
      expect(excavator.info.attackDamage, 3.0);
      expect(excavator.maxHealth, 3.0);
    });

    test("Defeating enemies drops a random plant card from active deck", () {
      final enemy = EnemyEntity(
        type: EnemyType.tractor,
        lane: 1,
        x: 500.0,
        y: GameState.laneYPositions[1],
      );
      state.enemies.add(enemy);

      // Defeat enemy
      enemy.takeDamage(enemy.maxHealth);
      expect(enemy.isDead, isTrue);

      state.update(0.01);
      expect(state.enemies.contains(enemy), isFalse);

      // Dropped card exists and is in player's active deck
      if (state.droppedSeeds.isNotEmpty) {
        final drop = state.droppedSeeds.first;
        expect(state.activeDeck.contains(drop.plantType), isTrue);

        final initialCount = state.getCardCount(drop.plantType);
        state.collectSeed(drop);
        expect(state.getCardCount(drop.plantType), initialCount + 1);
      }
    });

    test(
        "Bunga Bangkai (Titan Arum) Corpse Cloud explodes on contact dealing damage",
        () {
      state.selectPlant(PlantType.titanArum);
      state.onCellTapped(2, 0);
      final plant = state.getPlantAt(2, 0)!;

      final enemy = EnemyEntity(
        type: EnemyType.tractor,
        lane: 0,
        x: plant.x + 30,
        y: GameState.laneYPositions[0],
      );
      state.enemies.add(enemy);

      final initialEnemyHp = enemy.health;
      state.update(0.01);

      // Plant exploded and enemy took damage
      expect(state.getPlantAt(2, 0), isNull);
      expect(enemy.health, initialEnemyHp - 1.0);
    });

    test("Kantong Semar Pitcher Trap traps enemy and deals damage on contact",
        () {
      state.selectPlant(PlantType.kantongSemar);
      state.onCellTapped(2, 1);
      final plant = state.getPlantAt(2, 1)!;

      final enemy = EnemyEntity(
        type: EnemyType.truck,
        lane: 1,
        x: plant.x + 20,
        y: GameState.laneYPositions[1],
      );
      state.enemies.add(enemy);

      final initialEnemyHp = enemy.health;
      state.update(0.01);

      expect(state.getPlantAt(2, 1), isNull); // Trap consumed
      expect(enemy.health, initialEnemyHp - 1.0);
      expect(enemy.isTrapped, isTrue);
      expect(enemy.trapTimer, greaterThan(0));
    });

    test("Cendana Scent Aura slows enemies in 3x3 grid area", () {
      state.selectPlant(PlantType.cendana);
      state.onCellTapped(2, 1);
      final plant = state.getPlantAt(2, 1)!;

      // Enemy in adjacent lane (lane 0) within horizontal radius
      final enemy = EnemyEntity(
        type: EnemyType.tractor,
        lane: 0,
        x: plant.x + 10,
        y: GameState.laneYPositions[0],
      );
      state.enemies.add(enemy);

      state.update(0.01);
      expect(enemy.slowEffectMultiplier, 0.5);
    });

    test("Damar shoots Resin Goo projectile that slows and damages enemy", () {
      state.selectPlant(PlantType.damar);
      state.onCellTapped(1, 0);
      final plant = state.getPlantAt(1, 0)!;

      final enemy = EnemyEntity(
        type: EnemyType.tractor,
        lane: 0,
        x: 600.0,
        y: GameState.laneYPositions[0],
      );
      state.enemies.add(enemy);

      plant.attackTimer = 2.5;
      state.update(0.01);

      expect(state.projectiles.any((p) => p.type == ProjectileType.damarResin),
          isTrue);

      final proj = state.projectiles
          .firstWhere((p) => p.type == ProjectileType.damarResin);
      proj.x = enemy.x; // Hit enemy
      state.update(0.01);

      expect(enemy.health, 3.0); // 4 - 1
      expect(enemy.slowEffectMultiplier, lessThan(1.0));
    });

    test("Sonokeling shoots Crimson Rosewood Shard projectiles", () {
      state.plantCards[PlantType.sonokeling] = 2;
      state.plantCooldowns[PlantType.sonokeling] = 0;
      state.selectPlant(PlantType.sonokeling);
      state.onCellTapped(0, 2);
      final plant = state.getPlantAt(0, 2)!;

      final enemy = EnemyEntity(
        type: EnemyType.truck,
        lane: 2,
        x: 600.0,
        y: GameState.laneYPositions[2],
      );
      state.enemies.add(enemy);

      plant.attackTimer = 2.0;
      state.update(0.01);

      expect(
          state.projectiles
              .any((p) => p.type == ProjectileType.sonokelingShard),
          isTrue);
    });

    test("All 8 plants can be planted across the 21 grid tiles (7x3)", () {
      int tileIndex = 0;

      for (final plantInfo in kPlantCatalog) {
        final col = tileIndex % kGridCols;
        final row = tileIndex ~/ kGridCols;

        state.plantCards[plantInfo.type] = 10;
        state.plantCooldowns[plantInfo.type] = 0;
        state.selectPlant(plantInfo.type);
        state.onCellTapped(col, row);

        final placed = state.getPlantAt(col, row);
        expect(placed, isNotNull);
        expect(placed!.type, plantInfo.type);

        tileIndex++;
      }
    });

    test("Deck selection persistence allows picking 5 of 8 plants", () {
      final storage = StorageService();
      storage.resetProgress();

      expect(storage.selectedDeckNames.length, 5);
      expect(storage.isPlantNameInDeck('damar'), isTrue);

      // Toggle out damar
      final removed = storage.togglePlantNameInDeck('damar');
      expect(removed, isTrue);
      expect(storage.selectedDeckNames.length, 4);

      // Toggle in sonokeling
      final added = storage.togglePlantNameInDeck('sonokeling');
      expect(added, isTrue);
      expect(storage.selectedDeckNames.length, 5);
    });
  });

  testWidgets("BOOK modal displays 8 plant slots, details, and deck toggle", (
    tester,
  ) async {
    String assetNameOf(Image image) {
      final provider = image.image;
      final asset = provider is ResizeImage ? provider.imageProvider : provider;
      return (asset as AssetImage).assetName;
    }

    StorageService().resetProgress();
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // How-to-play uses the supplied image and opens its mapped popup.
    expect(
      find.byKey(const Key('home_how_to_play_button')),
      findsOneWidget,
    );
    final howToPlayImage = tester.widget<Image>(
      find.byKey(const Key('home_how_to_play_image')),
    );
    expect(
      assetNameOf(howToPlayImage),
      'assets/images/how-to-play.png',
    );
    await tester.tap(find.byKey(const Key('home_how_to_play_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('how_to_play_modal')), findsOneWidget);
    final howToPlayPopup = tester.widget<Image>(
      find.byKey(const Key('how_to_play_popup_image')),
    );
    expect(
      assetNameOf(howToPlayPopup),
      'assets/images/popup-htp.png',
    );
    final howToPlayCloseImage = tester.widget<Image>(
      find.byKey(const Key('how_to_play_close_image')),
    );
    expect(
      assetNameOf(howToPlayCloseImage),
      'assets/images/close.png',
    );
    final howToPlayClosePosition = tester.widget<Positioned>(
      find.byKey(const Key('how_to_play_close_position')),
    );
    final testViewSize =
        tester.view.physicalSize / tester.view.devicePixelRatio;
    const playAspectRatio = 2752 / 1536;
    final playHeight = testViewSize.width / playAspectRatio;
    final playTop = (testViewSize.height - playHeight) / 2;
    expect(howToPlayClosePosition.right, 14);
    expect(howToPlayClosePosition.top, closeTo(playTop + 14, 0.1));
    expect(find.byKey(const Key('book_modal')), findsNothing);
    await tester.tap(find.byKey(const Key('how_to_play_close_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('how_to_play_modal')), findsNothing);

    // Open book
    await tester.tap(find.byKey(const Key('home_book_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('book_modal')), findsOneWidget);
    final bookTitle = tester.widget<Text>(
      find.byKey(const Key('book_title_text')),
    );
    expect(bookTitle.style?.fontFamily, 'LilitaOne');
    final deckCounter = tester.widget<Text>(
      find.byKey(const Key('book_deck_counter_text')),
    );
    expect(deckCounter.data, 'DECK 5/5');
    expect(deckCounter.style?.fontFamily, 'LilitaOne');

    // Verify slots exist (including Damar, no Rafflesia slot)
    expect(find.byKey(const Key('book_slot_titanArum')), findsOneWidget);
    expect(find.byKey(const Key('book_slot_kantongSemar')), findsOneWidget);
    expect(find.byKey(const Key('book_slot_cendana')), findsOneWidget);
    expect(find.byKey(const Key('book_slot_eboni')), findsOneWidget);
    expect(find.byKey(const Key('book_slot_gaharu')), findsOneWidget);
    expect(find.byKey(const Key('book_slot_meranti')), findsOneWidget);
    expect(find.byKey(const Key('book_slot_damar')), findsOneWidget);
    expect(find.byKey(const Key('book_slot_sonokeling')), findsOneWidget);

    // Tap Damar to view details
    await tester.tap(find.byKey(const Key('book_damar_item')));
    await tester.pump();
    expect(find.byKey(const Key('book_detail_panel')), findsOneWidget);
    expect(find.textContaining('DAMAR'), findsWidgets);
    final detailAbout = tester.widget<Text>(
      find.byKey(const Key('book_detail_about')),
    );
    expect(detailAbout.style?.fontFamily, 'BreeSerif');
    expect(find.byKey(const Key('book_bottom_deck_button')), findsOneWidget);
    Image deckButtonImage = tester.widget<Image>(
      find.byKey(const Key('book_bottom_deck_image')),
    );
    expect(
      assetNameOf(deckButtonImage),
      'assets/images/unequip.png',
    );

    // The image button toggles between Unequip and Equip assets.
    await tester.tap(find.byKey(const Key('book_bottom_deck_button')));
    await tester.pump();
    deckButtonImage = tester.widget<Image>(
      find.byKey(const Key('book_bottom_deck_image')),
    );
    expect(
      assetNameOf(deckButtonImage),
      'assets/images/equip.png',
    );

    await tester.tap(find.byKey(const Key('book_bottom_deck_button')));
    await tester.pump();
    deckButtonImage = tester.widget<Image>(
      find.byKey(const Key('book_bottom_deck_image')),
    );
    expect(
      assetNameOf(deckButtonImage),
      'assets/images/unequip.png',
    );

    // Return immediately closes the book, even while details are open.
    await tester.tap(find.byKey(const Key('book_return_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('book_modal')), findsNothing);
  });

  testWidgets("Home settings toggles audio and confirms progress reset", (
    tester,
  ) async {
    String assetNameOf(Image image) {
      final provider = image.image;
      final asset = provider is ResizeImage ? provider.imageProvider : provider;
      return (asset as AssetImage).assetName;
    }

    final storage = StorageService();
    storage
      ..resetProgress()
      ..setBgmEnabled(true)
      ..setSfxEnabled(true)
      ..saveStageResult(0, 3, 7, 4);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.byKey(const Key('home_settings_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('game_settings_modal')), findsOneWidget);
    final settingsImage = tester.widget<Image>(
      find.byKey(const Key('settings_background_image')),
    );
    expect(assetNameOf(settingsImage), 'assets/images/settings.png');
    final settingsCloseImage = tester.widget<Image>(
      find.byKey(const Key('settings_close_image')),
    );
    expect(assetNameOf(settingsCloseImage), 'assets/images/close.png');
    final settingsClosePosition = tester.widget<Positioned>(
      find.byKey(const Key('settings_close_position')),
    );
    final settingsViewSize =
        tester.view.physicalSize / tester.view.devicePixelRatio;
    const settingsPlayAspectRatio = 2752 / 1536;
    final settingsPlayHeight = settingsViewSize.width / settingsPlayAspectRatio;
    final settingsPlayTop = (settingsViewSize.height - settingsPlayHeight) / 2;
    expect(settingsClosePosition.right, 14);
    expect(
      settingsClosePosition.top,
      closeTo(settingsPlayTop + 14, 0.1),
    );

    await tester.tap(find.byKey(const Key('settings_bgm_toggle')));
    await tester.pump();
    expect(storage.bgmEnabled, isFalse);

    await tester.tap(find.byKey(const Key('settings_sfx_toggle')));
    await tester.pump();
    expect(storage.sfxEnabled, isFalse);

    await tester.tap(find.byKey(const Key('settings_reset_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('reset_progress_confirmation')),
      findsOneWidget,
    );
    final confirmationImage = tester.widget<Image>(
      find.byKey(const Key('reset_confirmation_image')),
    );
    expect(assetNameOf(confirmationImage), 'assets/images/confirm.png');

    // Clicking outside must not dismiss this destructive confirmation.
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('reset_progress_confirmation')),
      findsOneWidget,
    );
    expect(storage.completedStagesCount, 1);

    await tester.tap(find.byKey(const Key('reset_cancel_button')));
    await tester.pumpAndSettle();
    expect(storage.completedStagesCount, 1);
    expect(storage.totalSeedsCollected, 4);

    await tester.tap(find.byKey(const Key('settings_reset_button')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('reset_progress_confirmation')),
      findsNothing,
    );
    expect(storage.completedStagesCount, 1);

    await tester.tap(find.byKey(const Key('settings_reset_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset_confirm_button')));
    await tester.pumpAndSettle();
    expect(storage.completedStagesCount, 0);
    expect(storage.totalSeedsCollected, 0);
    expect(storage.highDeforestationPrevented, 0);
    expect(find.byKey(const Key('game_settings_modal')), findsOneWidget);

    storage
      ..setBgmEnabled(true)
      ..setSfxEnabled(true);
    await tester.tap(find.byKey(const Key('settings_close_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('game_settings_modal')), findsNothing);
  });

  testWidgets("Image pause menu maps resume, settings, and home", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('test_start_game'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const GameScreen()),
              ),
              child: const Text('START'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('test_start_game')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('game_pause_button')), findsOneWidget);
    expect(find.byKey(const Key('wave_hud')), findsOneWidget);
    expect(find.byKey(const Key('wave_background')), findsOneWidget);
    expect(find.byKey(const Key('wave_heart_status')), findsOneWidget);
    expect(find.byKey(const Key('wave_label')), findsOneWidget);
    expect(find.byKey(const Key('wave_progress')), findsOneWidget);
    expect(find.byKey(const Key('wave_tree_score')), findsOneWidget);
    expect(find.byKey(const Key('wave_heart_0')), findsOneWidget);
    expect(find.byKey(const Key('wave_heart_1')), findsOneWidget);
    expect(find.byKey(const Key('wave_heart_2')), findsOneWidget);
    final firstHeartSize = tester.getSize(
      find.byKey(const Key('wave_heart_0')),
    );
    expect(firstHeartSize.width, greaterThan(0));
    expect(firstHeartSize.height, greaterThan(0));
    expect(
      (firstHeartSize.width - firstHeartSize.height).abs(),
      lessThan(1.0),
    );
    final waveLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('wave_label')),
        matching: find.byType(Text),
      ),
    );
    expect(waveLabel.style?.fontFamily, 'LilitaOne');
    final treeIcon = tester.widget<Image>(
      find.byKey(const Key('wave_tree_icon')),
    );
    final resizedTreeIcon = treeIcon.image as ResizeImage;
    expect(
      (resizedTreeIcon.imageProvider as AssetImage).assetName,
      'assets/images/icon-tree.png',
    );
    final treeIconSize = tester.getSize(
      find.byKey(const Key('wave_tree_icon')),
    );
    expect((treeIconSize.width - firstHeartSize.width).abs(), lessThan(1.0));
    expect((treeIconSize.height - firstHeartSize.height).abs(), lessThan(1.0));
    expect(find.byKey(const Key('inventory_counter_0')), findsOneWidget);
    expect(find.byKey(const Key('right_foreground_overlay')), findsOneWidget);
    final foregroundImage = tester.widget<Image>(
      find.byKey(const Key('right_foreground_image')),
    );
    final foregroundOverlay = tester.widget<Positioned>(
      find.byKey(const Key('right_foreground_overlay')),
    );
    expect(foregroundOverlay.left, isNull);
    expect(foregroundOverlay.top, isNull);
    expect(foregroundOverlay.right, lessThan(0));
    expect(foregroundOverlay.bottom, lessThan(0));
    expect(foregroundOverlay.width, greaterThan(0));
    expect(foregroundOverlay.height, greaterThan(0));
    final resizedForeground = foregroundImage.image as ResizeImage;
    expect(
      (resizedForeground.imageProvider as AssetImage).assetName,
      'assets/images/rscreen-map.png',
    );
    final inventory = tester.widget<Positioned>(
      find.byKey(const Key('game_inventory')),
    );
    expect(inventory.top, isNull);
    expect(inventory.bottom, lessThan(0));
    expect(inventory.left, greaterThan(0));

    final firstInventoryCounter = tester.widget<Text>(
      find.byKey(const Key('inventory_counter_0')),
    );
    expect(firstInventoryCounter.style?.fontFamily, 'LilitaOne');

    final waveBackground = tester.widget<Image>(
      find.byKey(const Key('wave_background')),
    );
    final resizedWaveBackground = waveBackground.image as ResizeImage;
    expect(
      (resizedWaveBackground.imageProvider as AssetImage).assetName,
      'assets/images/waves.png',
    );

    await tester.tap(find.byKey(const Key('game_pause_button')));
    await tester.pump();
    expect(find.byKey(const Key('pause_modal')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pause_resume_button')));
    await tester.pump();
    expect(find.byKey(const Key('pause_modal')), findsNothing);

    await tester.tap(find.byKey(const Key('game_pause_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pause_settings_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('SETTINGS & CONTROLS'), findsOneWidget);

    Navigator.of(tester.element(find.text('SETTINGS & CONTROLS'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('SETTINGS & CONTROLS'), findsNothing);
    expect(find.byKey(const Key('pause_modal')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pause_home_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test_start_game')), findsOneWidget);
    expect(find.byKey(const Key('pause_modal')), findsNothing);
  });
}
