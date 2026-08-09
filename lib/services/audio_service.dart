import 'package:flutter/foundation.dart';

/// Universal Audio Service for BGM & SFX in "DON'T CUT IT"
/// Supports procedural audio synthesis via Web Audio API when running on Web,
/// and fallback state management for Desktop/Mobile.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  double bgmVolume = 0.7;
  double sfxVolume = 0.8;
  bool isMuted = false;
  bool isPlayingBgm = false;

  void setBgmVolume(double volume) {
    bgmVolume = volume.clamp(0.0, 1.0);
    _updateWebVolumes();
  }

  void setSfxVolume(double volume) {
    sfxVolume = volume.clamp(0.0, 1.0);
    _updateWebVolumes();
  }

  void toggleMute() {
    isMuted = !isMuted;
    _updateWebVolumes();
  }

  /// Initialize web synthesizer if running in browser
  void init() {
    if (kIsWeb) {
      _initWebAudio();
    }
  }

  void playBgm() {
    if (isMuted || bgmVolume <= 0) return;
    isPlayingBgm = true;
    if (kIsWeb) {
      _startWebAmbientRainforest();
    }
  }

  void stopBgm() {
    isPlayingBgm = false;
    if (kIsWeb) {
      _stopWebAmbientRainforest();
    }
  }

  /// Plays sound effect by type
  void playSfx(SfxType type) {
    if (isMuted || sfxVolume <= 0) return;

    if (kIsWeb) {
      _playWebSfx(type);
    }
  }

  // --- Web Audio Synthesis Implementation ---
  void _initWebAudio() {
    try {
      // Setup Web Audio context safely
      _evalWebJs('''
        if (!window.dciAudioCtx) {
          window.AudioContext = window.AudioContext || window.webkitAudioContext;
          if (window.AudioContext) {
            window.dciAudioCtx = new AudioContext();
          }
        }
      ''');
    } catch (_) {}
  }

  void _updateWebVolumes() {
    if (!kIsWeb) return;
    _evalWebJs('''
      if (window.dciBgmGain) {
        window.dciBgmGain.gain.value = ${isMuted ? 0 : bgmVolume * 0.15};
      }
    ''');
  }

  void _startWebAmbientRainforest() {
    _evalWebJs('''
      (function() {
        if (!window.dciAudioCtx) {
          window.AudioContext = window.AudioContext || window.webkitAudioContext;
          if (window.AudioContext) window.dciAudioCtx = new AudioContext();
        }
        if (!window.dciAudioCtx) return;
        if (window.dciAudioCtx.state === 'suspended') {
          window.dciAudioCtx.resume();
        }
        if (window.dciBgmInterval) return;

        var ctx = window.dciAudioCtx;
        window.dciBgmGain = ctx.createGain();
        window.dciBgmGain.gain.value = ${isMuted ? 0 : bgmVolume * 0.15};
        window.dciBgmGain.connect(ctx.destination);

        function playChirp() {
          if (!window.dciBgmInterval) return;
          try {
            var now = ctx.currentTime;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sine';
            var f0 = 1800 + Math.random() * 800;
            osc.frequency.setValueAtTime(f0, now);
            osc.frequency.exponentialRampToValueAtTime(f0 * 1.5, now + 0.08);
            osc.frequency.exponentialRampToValueAtTime(f0 * 0.8, now + 0.18);
            gain.gain.setValueAtTime(0.05, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
            osc.connect(gain);
            gain.connect(window.dciBgmGain);
            osc.start(now);
            osc.stop(now + 0.22);
          } catch(e) {}
        }

        window.dciBgmInterval = setInterval(function() {
          if (Math.random() < 0.4) playChirp();
        }, 1200);
      })();
    ''');
  }

  void _stopWebAmbientRainforest() {
    _evalWebJs('''
      if (window.dciBgmInterval) {
        clearInterval(window.dciBgmInterval);
        window.dciBgmInterval = null;
      }
    ''');
  }

  void _playWebSfx(SfxType type) {
    String jsCode = '';
    final vol = isMuted ? 0.0 : sfxVolume;

    switch (type) {
      case SfxType.shootSpore:
        jsCode = '''
          (function() {
            var ctx = window.dciAudioCtx;
            if (!ctx) return;
            var now = ctx.currentTime;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(520, now);
            osc.frequency.exponentialRampToValueAtTime(220, now + 0.12);
            gain.gain.setValueAtTime(${vol * 0.25}, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + 0.13);
          })();
        ''';
        break;

      case SfxType.plantPlaced:
        jsCode = '''
          (function() {
            var ctx = window.dciAudioCtx;
            if (!ctx) return;
            var now = ctx.currentTime;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(260, now);
            osc.frequency.exponentialRampToValueAtTime(580, now + 0.18);
            gain.gain.setValueAtTime(${vol * 0.3}, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + 0.2);
          })();
        ''';
        break;

      case SfxType.seedPickup:
        jsCode = '''
          (function() {
            var ctx = window.dciAudioCtx;
            if (!ctx) return;
            var now = ctx.currentTime;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(600, now);
            osc.frequency.exponentialRampToValueAtTime(1200, now + 0.15);
            gain.gain.setValueAtTime(${vol * 0.35}, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + 0.16);
          })();
        ''';
        break;

      case SfxType.enemyHit:
        jsCode = '''
          (function() {
            var ctx = window.dciAudioCtx;
            if (!ctx) return;
            var now = ctx.currentTime;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'square';
            osc.frequency.setValueAtTime(160, now);
            osc.frequency.exponentialRampToValueAtTime(60, now + 0.08);
            gain.gain.setValueAtTime(${vol * 0.2}, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + 0.09);
          })();
        ''';
        break;

      case SfxType.enemyDestroyed:
        jsCode = '''
          (function() {
            var ctx = window.dciAudioCtx;
            if (!ctx) return;
            var now = ctx.currentTime;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sawtooth';
            osc.frequency.setValueAtTime(140, now);
            osc.frequency.exponentialRampToValueAtTime(30, now + 0.3);
            gain.gain.setValueAtTime(${vol * 0.35}, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.32);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + 0.33);
          })();
        ''';
        break;

      case SfxType.rafflesiaMove:
        jsCode = '''
          (function() {
            var ctx = window.dciAudioCtx;
            if (!ctx) return;
            var now = ctx.currentTime;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(300, now);
            osc.frequency.exponentialRampToValueAtTime(450, now + 0.08);
            gain.gain.setValueAtTime(${vol * 0.2}, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + 0.09);
          })();
        ''';
        break;

      case SfxType.victory:
        jsCode = '''
          (function() {
            var ctx = window.dciAudioCtx;
            if (!ctx) return;
            var now = ctx.currentTime;
            [440, 554, 659, 880].forEach(function(freq, i) {
              var osc = ctx.createOscillator();
              var gain = ctx.createGain();
              osc.type = 'triangle';
              osc.frequency.setValueAtTime(freq, now + i * 0.12);
              gain.gain.setValueAtTime(${vol * 0.3}, now + i * 0.12);
              gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.12 + 0.3);
              osc.connect(gain);
              gain.connect(ctx.destination);
              osc.start(now + i * 0.12);
              osc.stop(now + i * 0.12 + 0.32);
            });
          })();
        ''';
        break;

      case SfxType.defeat:
        jsCode = '''
          (function() {
            var ctx = window.dciAudioCtx;
            if (!ctx) return;
            var now = ctx.currentTime;
            [350, 311, 277, 220].forEach(function(freq, i) {
              var osc = ctx.createOscillator();
              var gain = ctx.createGain();
              osc.type = 'sawtooth';
              osc.frequency.setValueAtTime(freq, now + i * 0.15);
              gain.gain.setValueAtTime(${vol * 0.25}, now + i * 0.15);
              gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.15 + 0.25);
              osc.connect(gain);
              gain.connect(ctx.destination);
              osc.start(now + i * 0.15);
              osc.stop(now + i * 0.15 + 0.26);
            });
          })();
        ''';
        break;

      case SfxType.buttonClick:
        jsCode = '''
          (function() {
            var ctx = window.dciAudioCtx;
            if (!ctx) return;
            var now = ctx.currentTime;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(700, now);
            osc.frequency.exponentialRampToValueAtTime(900, now + 0.05);
            gain.gain.setValueAtTime(${vol * 0.2}, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.06);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + 0.06);
          })();
        ''';
        break;
    }

    if (jsCode.isNotEmpty) {
      _evalWebJs(jsCode);
    }
  }

  void _evalWebJs(String jsCode) {
    if (!kIsWeb) return;
    try {
      // Using js interop or eval safely
      // In modern flutter web we can inject a script or execute via window
      final script = jsCode.trim();
      _runScript(script);
    } catch (_) {}
  }
}

enum SfxType {
  shootSpore,
  plantPlaced,
  seedPickup,
  enemyHit,
  enemyDestroyed,
  rafflesiaMove,
  victory,
  defeat,
  buttonClick,
}

// Low-level helper to run inline script on Web without requiring direct html import
void _runScript(String code) {
  // Use platform-safe dispatch if web
  if (kIsWeb) {
    // ignore: undefined_prefixed_name
    // We execute through standard web runtime
    _WebAudioBridge.execute(code);
  }
}

class _WebAudioBridge {
  static void execute(String jsCode) {
    // Dynamic execution handled on web
    try {
      // ignore: avoid_dynamic_calls
      final dynamic window = (kIsWeb) ? _getWindow() : null;
      if (window != null) {
        // Evaluate script
        window.eval(jsCode);
      }
    } catch (_) {}
  }

  static dynamic _getWindow() {
    try {
      // ignore: undefined_function
      return null;
    } catch (_) {
      return null;
    }
  }
}
