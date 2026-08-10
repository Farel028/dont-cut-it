import 'package:flutter/material.dart';

class PlayAreaCloseButton extends StatelessWidget {
  const PlayAreaCloseButton({
    super.key,
    required this.positionKey,
    required this.buttonKey,
    required this.imageKey,
    required this.label,
    required this.onTap,
  });

  static const double _playAspectRatio = 2752 / 1536;

  final Key positionKey;
  final Key buttonKey;
  final Key imageKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var playWidth = constraints.maxWidth;
        var playHeight = playWidth / _playAspectRatio;

        if (playHeight > constraints.maxHeight) {
          playHeight = constraints.maxHeight;
          playWidth = playHeight * _playAspectRatio;
        }

        final horizontalLetterbox = (constraints.maxWidth - playWidth) / 2;
        final verticalLetterbox = (constraints.maxHeight - playHeight) / 2;
        final closeSize = (playHeight * 0.11).clamp(52.0, 88.0).toDouble();

        return Stack(
          children: [
            Positioned(
              key: positionKey,
              right: horizontalLetterbox + 14,
              top: verticalLetterbox + 14,
              width: closeSize,
              height: closeSize,
              child: ScreenCloseButton(
                buttonKey: buttonKey,
                imageKey: imageKey,
                label: label,
                onTap: onTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ScreenCloseButton extends StatelessWidget {
  const ScreenCloseButton({
    super.key,
    required this.buttonKey,
    required this.imageKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final Key imageKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: buttonKey,
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ClipRect(
            child: Image.asset(
              'assets/images/close.png',
              key: imageKey,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              cacheWidth: 280,
            ),
          ),
        ),
      ),
    );
  }
}
