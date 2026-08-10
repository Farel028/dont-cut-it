import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_service.dart';
import '../services/storage_service.dart';
import 'screen_close_button.dart';

class GameSettingsModal extends StatefulWidget {
  const GameSettingsModal({super.key});

  @override
  State<GameSettingsModal> createState() => _GameSettingsModalState();
}

class _GameSettingsModalState extends State<GameSettingsModal> {
  static const double _settingsAspectRatio = 1122 / 1402;

  final AudioService _audio = AudioService();
  final StorageService _storage = StorageService();

  void _setBgmEnabled(bool enabled) {
    setState(() {
      _storage.setBgmEnabled(enabled);
      _audio.setBgmVolume(enabled ? _storage.bgmVolume : 0);
    });
  }

  void _setSfxEnabled(bool enabled) {
    setState(() {
      _storage.setSfxEnabled(enabled);
      _audio.setSfxVolume(enabled ? _storage.sfxVolume : 0);
    });
  }

  void _openResetConfirmation() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xD9000000),
      builder: (_) => ResetProgressConfirmation(
        onConfirm: () {
          _storage.resetProgress();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Dialog(
          key: const Key('game_settings_modal'),
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          backgroundColor: Colors.transparent,
          child: Semantics(
            label: 'Pengaturan permainan',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: AspectRatio(
                aspectRatio: _settingsAspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/settings.png',
                            key: const Key('settings_background_image'),
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                            cacheWidth: 1122,
                          ),
                        ),
                        _buildToggle(
                          key: const Key('settings_bgm_toggle'),
                          label: 'Backsound',
                          enabled: _storage.bgmEnabled,
                          onChanged: _setBgmEnabled,
                          left: width * 0.635,
                          top: height * 0.365,
                          width: width * 0.115,
                          height: height * 0.042,
                        ),
                        _buildToggle(
                          key: const Key('settings_sfx_toggle'),
                          label: 'SFX',
                          enabled: _storage.sfxEnabled,
                          onChanged: _setSfxEnabled,
                          left: width * 0.635,
                          top: height * 0.510,
                          width: width * 0.115,
                          height: height * 0.042,
                        ),
                        Positioned(
                          left: width * 0.668,
                          top: height * 0.628,
                          width: width * 0.122,
                          height: height * 0.092,
                          child: Semantics(
                            button: true,
                            label: 'Reset progress',
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                key: const Key('settings_reset_button'),
                                behavior: HitTestBehavior.opaque,
                                onTap: _openResetConfirmation,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: PlayAreaCloseButton(
            positionKey: const Key('settings_close_position'),
            buttonKey: const Key('settings_close_button'),
            imageKey: const Key('settings_close_image'),
            label: 'Tutup pengaturan',
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required Key key,
    required String label,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        toggled: enabled,
        label: label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: key,
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.all(height * 0.10),
              decoration: BoxDecoration(
                color:
                    enabled ? const Color(0xFF4F8F32) : const Color(0xFF3A271D),
                borderRadius: BorderRadius.circular(height * 0.30),
                border: Border.all(
                  color: enabled
                      ? const Color(0xFFB9E85A)
                      : const Color(0xFF805336),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment:
                    enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: enabled
                          ? const Color(0xFFFFE7A0)
                          : const Color(0xFFB59B82),
                      borderRadius: BorderRadius.circular(height),
                      border: Border.all(
                        color: const Color(0xFF3B2015),
                        width: 1.5,
                      ),
                    ),
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

class ResetProgressConfirmation extends StatelessWidget {
  const ResetProgressConfirmation({super.key, required this.onConfirm});

  static const double _confirmAspectRatio = 2 / 3;

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop();
        },
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          key: const Key('reset_progress_confirmation'),
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AspectRatio(
              aspectRatio: _confirmAspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/confirm.png',
                          key: const Key('reset_confirmation_image'),
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.none,
                          cacheWidth: 1024,
                        ),
                      ),
                      _buildButton(
                        context: context,
                        key: const Key('reset_cancel_button'),
                        label: 'Cancel',
                        left: width * 0.145,
                        top: height * 0.705,
                        width: width * 0.345,
                        height: height * 0.112,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      _buildButton(
                        context: context,
                        key: const Key('reset_confirm_button'),
                        label: 'Confirm',
                        left: width * 0.510,
                        top: height * 0.705,
                        width: width * 0.345,
                        height: height * 0.112,
                        onTap: onConfirm,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required Key key,
    required String label,
    required double left,
    required double top,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
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
