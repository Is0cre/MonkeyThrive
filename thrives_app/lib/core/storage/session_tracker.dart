import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'session_log.dart';
import 'tier_service.dart';

class SessionActivity {
  SessionActivity._();

  static final activeCount = ValueNotifier<int>(0);
  static final Set<VoidCallback> _bailoutCallbacks = {};

  static bool get isActive => activeCount.value > 0;

  static void begin({VoidCallback? onEmergencyBailout}) {
    if (onEmergencyBailout != null) {
      _bailoutCallbacks.add(onEmergencyBailout);
    }
    activeCount.value++;
    _syncWakeLock();
  }

  static void end({VoidCallback? onEmergencyBailout}) {
    if (onEmergencyBailout != null) {
      _bailoutCallbacks.remove(onEmergencyBailout);
    }
    if (activeCount.value > 0) {
      activeCount.value--;
    }
    _syncWakeLock();
  }

  // CLINICAL SAFETY — Immediate Emergency Bailout
  // What this does: Synchronously halts all registered active sessions
  //   (bilateral stimulation, audio tones, tactile vibration, timers)
  //   before PanicScreen takes over the screen.
  // Why it exists: When a user hits the emergency button, ongoing sensory
  //   stimulation or breath holds must stop immediately without waiting for
  //   route disposal.
  // What happens if removed: Audio, vibration, and timers continue running
  //   underneath PanicScreen.
  static void triggerEmergencyBailout() {
    try {
      unawaited(Vibration.cancel().catchError((_) {}));
    } catch (_) {}

    final callbacks = List<VoidCallback>.from(_bailoutCallbacks);
    _bailoutCallbacks.clear();
    for (final stop in callbacks) {
      try {
        stop();
      } catch (_) {}
    }
  }

  static void _syncWakeLock() {
    try {
      if (activeCount.value > 0) {
        unawaited(WakelockPlus.enable().catchError((_) {}));
      } else {
        unawaited(WakelockPlus.disable().catchError((_) {}));
      }
    } catch (_) {
      // Safe fallback in test environments or browsers without WakeLock grant
    }
  }
}

/// Mixin that adds automatic session logging and reference-counted WakeLock
/// management to any tool screen's State.
mixin SessionTracking<T extends StatefulWidget> on State<T> {
  String? _trackTool;
  String? _trackCategory;
  DateTime? _trackStart;
  bool _sessionActive = false;
  VoidCallback? _bailoutCallback;
  _WakeLockLifecycleObserver? _lifecycleObserver;

  /// Call when the user actively starts using a tool.
  /// Safe to call multiple times — restarts the timer.
  /// Enables reference-counted WakeLock and registers optional [onEmergencyStop]
  /// callback so the EmergencyButton can halt stimulation immediately.
  void beginTracking(
    String tool,
    String category, {
    VoidCallback? onEmergencyStop,
  }) {
    if (!_sessionActive) {
      _sessionActive = true;
      _bailoutCallback = onEmergencyStop;
      final observer = _WakeLockLifecycleObserver();
      _lifecycleObserver = observer;
      WidgetsBinding.instance.addObserver(observer);
      SessionActivity.begin(onEmergencyBailout: _bailoutCallback);
    } else if (onEmergencyStop != null && _bailoutCallback != onEmergencyStop) {
      SessionActivity._bailoutCallbacks.remove(_bailoutCallback);
      _bailoutCallback = onEmergencyStop;
      SessionActivity._bailoutCallbacks.add(_bailoutCallback!);
    }
    _trackTool = tool;
    _trackCategory = category;
    _trackStart = DateTime.now();
  }

  /// Flush without waiting for dispose — call when a session ends cleanly
  /// (e.g., timer complete, user taps stop) if you want more accurate duration.
  void endTracking() {
    _flush();
  }

  @override
  void dispose() {
    _flush();
    super.dispose();
  }

  void _flush() {
    final tool = _trackTool;
    final category = _trackCategory;
    final start = _trackStart;
    if (_sessionActive) {
      _sessionActive = false;
      if (_lifecycleObserver != null) {
        WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
        _lifecycleObserver = null;
      }
      SessionActivity.end(onEmergencyBailout: _bailoutCallback);
      _bailoutCallback = null;
    }
    if (tool == null || start == null) return;
    _trackTool = null;
    _trackStart = null;

    final secs = DateTime.now().difference(start).inSeconds;
    if (secs < 10) return;
    // Fire and forget — local write, completes in <1ms
    SessionLog.logSession(SessionEntry(
      tool: tool,
      category: category ?? 'General',
      timestamp: start,
      durationSeconds: secs,
    )).then((_) => TierService.recheck());
  }
}

class _WakeLockLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && SessionActivity.isActive) {
      try {
        unawaited(WakelockPlus.enable().catchError((_) {}));
      } catch (_) {}
    }
  }
}
