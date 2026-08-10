import 'package:flutter/material.dart';

import 'book_modal.dart';
import 'game_screen.dart';
import 'game_settings_modal.dart';
import 'how_to_play_modal.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _sourceWidth = 2752;
  static const double _sourceHeight = 1536;
  static const double _aspectRatio = _sourceWidth / _sourceHeight;

  // Button bounds mapped directly from assets/images/play.png.
  static const Rect _playButton = Rect.fromLTWH(
    0.392,
    0.367,
    0.207,
    0.111,
  );

  static const Rect _bookButton = Rect.fromLTWH(
    0.398,
    0.505,
    0.199,
    0.105,
  );

  static const Rect _settingsButton = Rect.fromLTWH(
    0.398,
    0.635,
    0.201,
    0.105,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          var screenWidth = constraints.maxWidth;
          var screenHeight = screenWidth / _aspectRatio;

          if (screenHeight > constraints.maxHeight) {
            screenHeight = constraints.maxHeight;
            screenWidth = screenHeight * _aspectRatio;
          }

          return Center(
            child: SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/play.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      cacheWidth: 1600,
                    ),
                  ),
                  _buildPlayHitbox(context, screenWidth, screenHeight),
                  _buildBookHitbox(context, screenWidth, screenHeight),
                  _buildSettingsHitbox(context, screenWidth, screenHeight),
                  _buildHowToPlayButton(
                    context,
                    screenWidth,
                    screenHeight,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsHitbox(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Positioned(
      left: _settingsButton.left * screenWidth,
      top: _settingsButton.top * screenHeight,
      width: _settingsButton.width * screenWidth,
      height: _settingsButton.height * screenHeight,
      child: Semantics(
        button: true,
        label: 'Settings',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: const Key('home_settings_button'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showDialog<void>(
                context: context,
                barrierColor: const Color(0xD9000000),
                builder: (_) => const GameSettingsModal(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHowToPlayButton(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    final buttonSize = screenWidth * 0.10;

    return Positioned(
      right: screenWidth * 0.018,
      top: screenHeight * 0.025,
      width: buttonSize,
      height: buttonSize,
      child: Semantics(
        button: true,
        label: 'How to Play',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: const Key('home_how_to_play_button'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showDialog<void>(
                context: context,
                barrierColor: const Color(0xD9000000),
                builder: (_) => const HowToPlayModal(),
              );
            },
            child: ClipRect(
              child: Image.asset(
                'assets/images/how-to-play.png',
                key: const Key('home_how_to_play_image'),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                cacheWidth: 360,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookHitbox(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Positioned(
      left: _bookButton.left * screenWidth,
      top: _bookButton.top * screenHeight,
      width: _bookButton.width * screenWidth,
      height: _bookButton.height * screenHeight,
      child: Semantics(
        button: true,
        label: 'Book',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: const Key('home_book_button'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showDialog<void>(
                context: context,
                barrierColor: const Color(0xB3000000),
                builder: (_) => const BookModal(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlayHitbox(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Positioned(
      left: _playButton.left * screenWidth,
      top: _playButton.top * screenHeight,
      width: _playButton.width * screenWidth,
      height: _playButton.height * screenHeight,
      child: Semantics(
        button: true,
        label: 'Play',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GameScreen(stageIndex: 0),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
