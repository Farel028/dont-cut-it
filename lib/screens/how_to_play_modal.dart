import 'package:flutter/material.dart';

import 'screen_close_button.dart';

class HowToPlayModal extends StatelessWidget {
  const HowToPlayModal({super.key});

  static const double _imageAspectRatio = 1122 / 1402;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Dialog(
          key: const Key('how_to_play_modal'),
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          backgroundColor: Colors.transparent,
          child: Semantics(
            label: 'Panduan cara bermain',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: AspectRatio(
                aspectRatio: _imageAspectRatio,
                child: Image.asset(
                  'assets/images/popup-htp.png',
                  key: const Key('how_to_play_popup_image'),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  cacheWidth: 1122,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: PlayAreaCloseButton(
            positionKey: const Key('how_to_play_close_position'),
            buttonKey: const Key('how_to_play_close_button'),
            imageKey: const Key('how_to_play_close_image'),
            label: 'Tutup panduan',
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
