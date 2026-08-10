import 'package:flutter/material.dart';

import '../game/models/plants.dart';
import '../services/storage_service.dart';

class BookModal extends StatefulWidget {
  const BookModal({super.key});

  @override
  State<BookModal> createState() => _BookModalState();
}

class _BookModalState extends State<BookModal> {
  final StorageService _storage = StorageService();
  late List<PlantType> _deck;
  PlantType? _selectedPlant;

  @override
  void initState() {
    super.initState();
    _loadDeck();
    _selectedPlant = _deck.isNotEmpty ? _deck.first : PlantType.titanArum;
  }

  void _loadDeck() {
    final names = _storage.selectedDeckNames;
    final loaded = names
        .map((name) {
          try {
            return PlantType.values.firstWhere((p) => p.name == name);
          } catch (_) {
            return null;
          }
        })
        .whereType<PlantType>()
        .take(5)
        .toList();

    if (loaded.isEmpty) {
      _deck = kPlantCatalog.take(5).map((p) => p.type).toList();
    } else {
      _deck = loaded;
    }
  }

  void _saveDeck() {
    _storage.setSelectedDeckNames(_deck.map((p) => p.name).toList());
  }

  void _toggleDeck(PlantType type) {
    setState(() {
      if (_deck.contains(type)) {
        if (_deck.length > 1) {
          _deck.remove(type);
          _saveDeck();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Minimal harus membawa 1 kartu tanaman ke arena!'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (_deck.length < 5) {
          _deck.add(type);
          _saveDeck();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Deck penuh (5/5). Lepaskan salah satu tanaman terlebih dahulu.',
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  void _return() {
    _saveDeck();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('book_modal'),
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/book.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      cacheWidth: 1400,
                    ),
                  ),
                  _buildTitle(width, height),
                  _buildDeckCounter(width, height),
                  ..._buildAllPlantSlots(width, height),
                  if (_selectedPlant != null) ...[
                    _buildPlantPortrait(width, height, _selectedPlant!),
                    _buildPlantDescription(width, height, _selectedPlant!),
                  ],
                  _buildReturnHitbox(width, height),
                  _buildDeckToggleButton(width, height),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(double width, double height) {
    return Positioned(
      left: width * 0.125,
      top: height * 0.106,
      width: width * 0.350,
      height: height * 0.070,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'ENSIKLOPEDIA POHON',
          key: const Key('book_title_text'),
          style: TextStyle(
            color: const Color(0xFFFFD884),
            fontFamily: 'LilitaOne',
            fontSize: width * 0.026,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.6,
            shadows: const [
              Shadow(color: Color(0xFF2A1008), offset: Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCounter(double width, double height) {
    return Positioned(
      left: width * 0.105,
      top: height * 0.798,
      width: width * 0.220,
      height: height * 0.080,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'DECK ${_deck.length}/5',
          key: const Key('book_deck_counter_text'),
          style: TextStyle(
            color: const Color(0xFFFFE7B0),
            fontFamily: 'LilitaOne',
            fontWeight: FontWeight.w400,
            fontSize: width * 0.027,
            letterSpacing: 1.0,
            shadows: const [
              Shadow(color: Color(0xFF32160E), offset: Offset(-1.5, 0)),
              Shadow(color: Color(0xFF32160E), offset: Offset(1.5, 0)),
              Shadow(color: Color(0xFF32160E), offset: Offset(0, -1.5)),
              Shadow(color: Color(0xFF32160E), offset: Offset(0, 1.5)),
              Shadow(
                color: Color(0x99000000),
                offset: Offset(0, 3),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAllPlantSlots(double width, double height) {
    final slots = <Widget>[];

    // 8 slots mapped to 2 rows x 4 columns of book.png
    const leftPositions = [0.087, 0.219, 0.351, 0.483];
    const topPositions = [0.204, 0.486];
    const slotWidth = 0.120;
    const slotHeight = 0.265;

    for (int i = 0; i < kPlantCatalog.length && i < 8; i++) {
      final plant = kPlantCatalog[i];
      final col = i % 4;
      final row = i ~/ 4;
      final left = width * leftPositions[col];
      final top = height * topPositions[row];
      final w = width * slotWidth;
      final h = height * slotHeight;
      final isSelected = _selectedPlant == plant.type;
      final inDeck = _deck.contains(plant.type);
      final deckIndex = inDeck ? _deck.indexOf(plant.type) + 1 : 0;

      slots.add(
        Positioned(
          key: Key('book_slot_${plant.type.name}'),
          left: left,
          top: top,
          width: w,
          height: h,
          child: Semantics(
            button: true,
            selected: isSelected,
            label:
                '${plant.indonesianName} ${inDeck ? "(In Deck $deckIndex)" : ""}',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                key: Key('book_${plant.type.name}_item'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _selectedPlant = plant.type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: EdgeInsets.all(width * 0.006),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.008),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFD45C)
                          : (inDeck
                              ? const Color(0xFF66BB6A)
                              : Colors.transparent),
                      width: isSelected ? 3.5 : (inDeck ? 2.0 : 0),
                    ),
                    color: isSelected
                        ? const Color(0x33FFD54F)
                        : Colors.transparent,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          plant.assetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          cacheWidth: 220,
                        ),
                      ),
                      if (inDeck)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFFD54F),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              '#$deckIndex',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 2,
                        left: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xCC2B1A12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '\u2665 ${plant.maxHp.toInt()} HP',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFE082),
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return slots;
  }

  Widget _buildPlantPortrait(double width, double height, PlantType type) {
    final plant = kPlantCatalog.firstWhere((p) => p.type == type);

    return Positioned(
      left: width * 0.699,
      top: height * 0.207,
      width: width * 0.185,
      height: height * 0.265,
      child: Center(
        child: Image.asset(
          plant.assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          cacheWidth: 320,
        ),
      ),
    );
  }

  Widget _buildPlantDescription(double width, double height, PlantType type) {
    final plant = kPlantCatalog.firstWhere((p) => p.type == type);
    final baseFontSize = (width * 0.0115).clamp(8.5, 12.5).toDouble();

    return Positioned(
      key: const Key('book_detail_panel'),
      left: width * 0.655,
      top: height * 0.495,
      width: width * 0.267,
      height: height * 0.258,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.012),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'BreeSerif'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            plant.indonesianName.toUpperCase(),
                            key: const Key('book_detail_name'),
                            style: TextStyle(
                              color: const Color(0xFF4B2518),
                              fontFamily: 'LilitaOne',
                              fontSize: baseFontSize * 1.25,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.25,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        plant.scientificName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF70432C),
                          fontFamily: 'BreeSerif',
                          fontSize: baseFontSize * 0.88,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(plant.status),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFFFD54F), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4,
                                offset: Offset(0, 1)),
                          ],
                        ),
                        child: Text(
                          'STATUS: ● ${plant.status}',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'LilitaOne',
                            fontWeight: FontWeight.w400,
                            fontSize: baseFontSize * 0.72,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.008),
                      Text(
                        'TENTANG',
                        style: TextStyle(
                          color: const Color(0xFF3E2723),
                          fontFamily: 'LilitaOne',
                          fontSize: baseFontSize * 0.86,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.7,
                        ),
                      ),
                      Text(
                        plant.about,
                        key: const Key('book_detail_about'),
                        style: TextStyle(
                          color: const Color(0xFF4E342E),
                          fontFamily: 'BreeSerif',
                          fontSize: baseFontSize * 0.88,
                          height: 1.16,
                        ),
                      ),
                      SizedBox(height: height * 0.008),
                      Text(
                        'KEMAMPUAN',
                        style: TextStyle(
                          color: const Color(0xFF3E2723),
                          fontFamily: 'LilitaOne',
                          fontSize: baseFontSize * 0.86,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.7,
                        ),
                      ),
                      Text(
                        '✦ ${plant.abilityName}',
                        style: TextStyle(
                          color: const Color(0xFF880E4F),
                          fontFamily: 'BreeSerif',
                          fontSize: baseFontSize * 0.9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${plant.abilityDescription} (${plant.maxHp.toInt()} hp)',
                        style: TextStyle(
                          color: const Color(0xFF4E342E),
                          fontFamily: 'BreeSerif',
                          fontSize: baseFontSize * 0.86,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('CRITICALLY')) {
      return const Color(0xFFB71C1C); // Crimson
    } else if (s.contains('ENDANGERED')) {
      return const Color(0xFFE65100); // Deep orange
    } else if (s.contains('VULNERABLE')) {
      return const Color(0xFF33691E); // Forest green
    } else {
      return const Color(0xFF004D40); // Deep teal
    }
  }

  Widget _buildReturnHitbox(double width, double height) {
    return Positioned(
      left: width * 0.665,
      top: height * 0.798,
      width: width * 0.142,
      height: height * 0.080,
      child: Semantics(
        button: true,
        label: 'Return',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: const Key('book_return_button'),
            behavior: HitTestBehavior.opaque,
            onTap: _return,
          ),
        ),
      ),
    );
  }

  Widget _buildDeckToggleButton(double width, double height) {
    final selectedPlant = _selectedPlant;
    final isEnabled = selectedPlant != null;
    final isInDeck = selectedPlant != null && _deck.contains(selectedPlant);
    final assetPath =
        isInDeck ? 'assets/images/unequip.png' : 'assets/images/equip.png';

    return Positioned(
      left: width * 0.807,
      top: height * 0.798,
      width: width * 0.142,
      height: height * 0.080,
      child: Semantics(
        button: true,
        enabled: isEnabled,
        label: isInDeck ? 'Lepas tanaman dari deck' : 'Pilih tanaman ke deck',
        child: MouseRegion(
          cursor:
              isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Opacity(
            opacity: isEnabled ? 1 : 0.55,
            child: GestureDetector(
              key: const Key('book_bottom_deck_button'),
              behavior: HitTestBehavior.opaque,
              onTap: selectedPlant == null
                  ? null
                  : () => _toggleDeck(selectedPlant),
              child: ClipRect(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(1.25, 1.55, 1),
                  child: Image.asset(
                    assetPath,
                    key: const Key('book_bottom_deck_image'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.none,
                    cacheWidth: 560,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
