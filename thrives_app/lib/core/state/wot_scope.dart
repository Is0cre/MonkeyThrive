import 'package:flutter/material.dart';
import '../models/tolerance_state.dart';

/// Provides the current Window of Tolerance state to the widget tree.
///
/// Wrap the MaterialApp (or any subtree) with WoTScope to make the current
/// state available to all descendants without prop drilling.
///
/// Usage:
///   final state = WoTScope.stateOf(context);         // read once
///   final notifier = WoTScope.of(context);           // subscribe to changes
class WoTScope extends InheritedNotifier<ValueNotifier<ToleranceState?>> {
  const WoTScope({
    super.key,
    required ValueNotifier<ToleranceState?> notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Returns the [ValueNotifier] — subscribe to this to rebuild on state change.
  static ValueNotifier<ToleranceState?> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WoTScope>();
    assert(scope != null, 'WoTScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Returns the current state value without subscribing to changes.
  static ToleranceState? stateOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<WoTScope>()?.notifier?.value;
  }
}
