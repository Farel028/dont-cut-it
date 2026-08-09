import 'package:flutter/material.dart';

import '../game/models/plants.dart';

class BookModal extends StatefulWidget {
  const BookModal({super.key});

  @override
  State<BookModal> createState() => _BookModalState();
}

class _BookModalState extends State<BookModal> {
  PlantType? _selectedPlant;

  PlantInfo get _titanArum => kPlantCatalog.firstWhere(
        (plant) => plant.type == PlantType.titanArum,
      );

  void _return() {
    if (_selectedPlant != null) {
      setState(() => _selectedPlant = null);
      return;
    }
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
          aspectRatio: 669 / 373,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final isTitanSelected = _selectedPlant == PlantType.titanArum;

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
                  _buildTitanSlot(width, height, isTitanSelected),
                  if (isTitanSelected) ...[
                    _buildTitanPortrait(width, height),
                    _buildTitanDescription(width, height),
                  ],
                  _buildReturnHitbox(width, height),
                  _buildDismissHitbox(width, height),
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
      left: width * 0.105,
      top: height * 0.052,
      width: width * 0.44,
      height: height * 0.078,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'ENSIKLOPEDIA FLORA',
          style: TextStyle(
            color: const Color(0xFF4B2518),
            fontSize: width * 0.027,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTitanSlot(double width, double height, bool isSelected) {
    return Positioned(
      left: width * 0.091,
      top: height * 0.168,
      width: width * 0.118,
      height: height * 0.304,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Titan Arum',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: const Key('book_titan_arum_item'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _selectedPlant = PlantType.titanArum),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: EdgeInsets.all(width * 0.008),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.008),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFFFFD45C) : Colors.transparent,
                  width: isSelected ? 3 : 0,
                ),
              ),
              child: Image.asset(
                'assets/images/titan_arum.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                cacheWidth: 220,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitanPortrait(double width, double height) {
    return Positioned(
      left: width * 0.714,
      top: height * 0.178,
      width: width * 0.156,
      height: height * 0.294,
      child: Image.asset(
        'assets/images/titan_arum.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        cacheWidth: 300,
      ),
    );
  }

  Widget _buildTitanDescription(double width, double height) {
    final plant = _titanArum;
    final baseFontSize = (width * 0.013).clamp(9.0, 14.0).toDouble();

    return Positioned(
      key: const Key('book_detail_panel'),
      left: width * 0.665,
      top: height * 0.515,
      width: width * 0.255,
      height: height * 0.285,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TITAN ARUM',
              style: TextStyle(
                color: const Color(0xFF4B2518),
                fontSize: baseFontSize * 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              plant.scientificName,
              style: TextStyle(
                color: const Color(0xFF70432C),
                fontSize: baseFontSize * 0.82,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              'Bunga bangkai raksasa endemik hutan hujan Sumatra. '
              'Perbungaannya dapat tumbuh lebih dari 3 meter dan mengeluarkan '
              'aroma kuat untuk menarik kumbang serta lalat penyerbuk.',
              style: TextStyle(
                color: const Color(0xFF4A2A1C),
                fontSize: baseFontSize,
                height: 1.18,
              ),
            ),
            SizedBox(height: height * 0.012),
            Text(
              'EFEK GAME: jebakan sekali pakai. Titan Arum dan alat berat yang '
              'menabraknya akan sama-sama hancur.',
              style: TextStyle(
                color: const Color(0xFF7B291F),
                fontSize: baseFontSize * 0.9,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnHitbox(double width, double height) {
    return Positioned(
      left: width * 0.663,
      top: height * 0.855,
      width: width * 0.142,
      height: height * 0.105,
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

  Widget _buildDismissHitbox(double width, double height) {
    return Positioned(
      left: width * 0.808,
      top: height * 0.855,
      width: width * 0.151,
      height: height * 0.105,
      child: Semantics(
        button: true,
        label: 'Dismiss',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: const Key('book_dismiss_button'),
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
