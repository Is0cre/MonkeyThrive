import 'dart:async';

import '../storage/session_tracker.dart';
import '../storage/local_encrypted_store.dart';
import 'baseline_models.dart';

abstract class BaselineDecisionSource {
  Future<NotificationDecision?> shouldNotify();
}

class BaselineMonitor {
  BaselineMonitor({
    DateTime Function()? now,
    Duration? minimumPromptInterval,
    int quietStartHour = 22,
    int quietEndHour = 7,
  })  : _now = now ?? DateTime.now,
        _minimumPromptInterval =
            minimumPromptInterval ?? const Duration(hours: 4),
        _quietStartHour = quietStartHour,
        _quietEndHour = quietEndHour;

  static final instance = BaselineMonitor();

  final DateTime Function() _now;
  final Duration _minimumPromptInterval;
  final int _quietStartHour;
  final int _quietEndHour;
  DateTime? _lastPromptAt;
  bool _promptVisible = false;
  final Set<String> _closedSnapshotIds = {};
  bool _stateLoaded = false;

  static const _stateKey = 'baseline_prompt_state_v1';

  final _promptController = StreamController<NotificationDecision>.broadcast();

  Stream<NotificationDecision> get prompts => _promptController.stream;

  Future<bool> shouldNotify(NotificationDecision decision) async {
    await _loadState();
    if (!decision.shouldNotify) return false;
    if (_closedSnapshotIds.contains(decision.sensorSnapshotId)) return false;
    if (_promptVisible) return false;
    if (SessionActivity.isActive) return false;
    if (_isQuietHour(_now())) return false;
    final lastPromptAt = _lastPromptAt;
    if (lastPromptAt != null &&
        _now().difference(lastPromptAt) < _minimumPromptInterval) {
      return false;
    }
    return true;
  }

  Future<bool> submitDecision(NotificationDecision decision) async {
    if (!await shouldNotify(decision)) return false;
    _lastPromptAt = _now();
    _promptVisible = true;
    await _saveState();
    _promptController.add(decision);
    return true;
  }

  Future<bool> showManualPrompt(NotificationDecision decision) async {
    await _loadState();
    if (_promptVisible) return false;
    _promptVisible = true;
    await _saveState();
    _promptController.add(decision);
    return true;
  }

  Future<bool> evaluate(BaselineDecisionSource source) async {
    final decision = await source.shouldNotify();
    if (decision == null) return false;
    return submitDecision(decision);
  }

  Future<void> markPromptClosed([String? sensorSnapshotId]) async {
    await _loadState();
    if (sensorSnapshotId != null) {
      _closedSnapshotIds.add(sensorSnapshotId);
    }
    _promptVisible = false;
    await _saveState();
  }

  bool _isQuietHour(DateTime now) {
    final hour = now.hour;
    if (_quietStartHour == _quietEndHour) return false;
    if (_quietStartHour < _quietEndHour) {
      return hour >= _quietStartHour && hour < _quietEndHour;
    }
    return hour >= _quietStartHour || hour < _quietEndHour;
  }

  Future<void> _loadState() async {
    if (_stateLoaded) return;
    _stateLoaded = true;
    final raw = await LocalEncryptedStore.readJsonList(_stateKey);
    if (raw.isEmpty) return;
    final state = raw.first;
    final lastPrompt = state['last_prompt_at'] as String?;
    if (lastPrompt != null) {
      _lastPromptAt = DateTime.tryParse(lastPrompt);
    }
    final closedIds = state['closed_snapshot_ids'];
    if (closedIds is List) {
      _closedSnapshotIds
        ..clear()
        ..addAll(closedIds.whereType<String>());
    }
  }

  Future<void> _saveState() {
    return LocalEncryptedStore.writeJsonList(_stateKey, [
      {
        'last_prompt_at': _lastPromptAt?.toIso8601String(),
        'closed_snapshot_ids': _closedSnapshotIds.toList(),
      }
    ]);
  }
}
