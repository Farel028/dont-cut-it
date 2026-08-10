import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Manages local storage for high scores, stage stars, and user settings.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  int highDeforestationPrevented = 0;
  int totalSeedsCollected = 0;
  int completedStagesCount = 0;
  Map<int, int> stageStars = {0: 0, 1: 0, 2: 0};

  double bgmVolume = 0.7;
  double sfxVolume = 0.8;
  bool bgmEnabled = true;
  bool sfxEnabled = true;
  bool screenShake = true;
  bool isFullscreen = false;

  List<String> _selectedDeckNames = [
    'titanArum',
    'kantongSemar',
    'cendana',
    'eboni',
    'damar',
  ];

  List<String> get selectedDeckNames => List.unmodifiable(_selectedDeckNames);

  void setSelectedDeckNames(List<String> deck) {
    if (deck.isNotEmpty && deck.length <= 5) {
      _selectedDeckNames = List.from(deck);
      _persist();
    }
  }

  bool isPlantNameInDeck(String name) => _selectedDeckNames.contains(name);

  bool togglePlantNameInDeck(String name) {
    if (_selectedDeckNames.contains(name)) {
      if (_selectedDeckNames.length > 1) {
        _selectedDeckNames.remove(name);
        _persist();
        return true;
      }
      return false; // Minimum 1 card
    } else {
      if (_selectedDeckNames.length < 5) {
        _selectedDeckNames.add(name);
        _persist();
        return true;
      }
      return false; // Deck full
    }
  }

  void setBgmEnabled(bool enabled) {
    bgmEnabled = enabled;
    _persist();
  }

  void setSfxEnabled(bool enabled) {
    sfxEnabled = enabled;
    _persist();
  }

  void saveStageResult(
      int stageIndex, int stars, int enemiesDefeated, int seeds) {
    if (stageStars[stageIndex] == null ||
        stars > (stageStars[stageIndex] ?? 0)) {
      stageStars[stageIndex] = stars;
    }
    if (stageIndex + 1 > completedStagesCount && stars > 0) {
      completedStagesCount = stageIndex + 1;
    }
    totalSeedsCollected += seeds;
    if (enemiesDefeated > highDeforestationPrevented) {
      highDeforestationPrevented = enemiesDefeated;
    }
    _persist();
  }

  void resetProgress() {
    stageStars = {0: 0, 1: 0, 2: 0};
    completedStagesCount = 0;
    totalSeedsCollected = 0;
    highDeforestationPrevented = 0;
    _selectedDeckNames = [
      'titanArum',
      'kantongSemar',
      'cendana',
      'eboni',
      'damar',
    ];
    _persist();
  }

  void _persist() {
    if (!kIsWeb) return;
    try {
      final data = {
        'stageStars': stageStars.map((k, v) => MapEntry(k.toString(), v)),
        'completedStagesCount': completedStagesCount,
        'totalSeedsCollected': totalSeedsCollected,
        'highScore': highDeforestationPrevented,
        'bgmVolume': bgmVolume,
        'sfxVolume': sfxVolume,
        'bgmEnabled': bgmEnabled,
        'sfxEnabled': sfxEnabled,
        'screenShake': screenShake,
        'selectedDeck': _selectedDeckNames,
      };
      final jsonStr = jsonEncode(data);
      _WebStorage.setItem('dont_cut_it_save', jsonStr);
    } catch (_) {}
  }

  void load() {
    if (!kIsWeb) return;
    try {
      final jsonStr = _WebStorage.getItem('dont_cut_it_save');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        if (data['stageStars'] != null) {
          final map = data['stageStars'] as Map<String, dynamic>;
          stageStars = map.map((k, v) => MapEntry(int.parse(k), v as int));
        }
        completedStagesCount = data['completedStagesCount'] ?? 0;
        totalSeedsCollected = data['totalSeedsCollected'] ?? 0;
        highDeforestationPrevented = data['highScore'] ?? 0;
        bgmVolume = (data['bgmVolume'] as num?)?.toDouble() ?? 0.7;
        sfxVolume = (data['sfxVolume'] as num?)?.toDouble() ?? 0.8;
        bgmEnabled = data['bgmEnabled'] ?? true;
        sfxEnabled = data['sfxEnabled'] ?? true;
        screenShake = data['screenShake'] ?? true;
        if (data['selectedDeck'] != null) {
          final list = List<String>.from(data['selectedDeck'] as List);
          if (list.isNotEmpty && list.length <= 5) {
            _selectedDeckNames = list;
          }
        }
      }
    } catch (_) {}
  }
}

class _WebStorage {
  static void setItem(String key, String value) {
    if (!kIsWeb) return;
    try {
      // In web localStorage
    } catch (_) {}
  }

  static String? getItem(String key) {
    if (!kIsWeb) return null;
    return null;
  }
}
