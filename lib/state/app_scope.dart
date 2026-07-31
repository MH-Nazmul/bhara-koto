import 'package:flutter/widgets.dart';

import 'app_state.dart';
import 'trip_state.dart';

/// Hands the two long-lived controllers to the widget tree.
///
/// Both are [ChangeNotifier]s, so widgets subscribe with [ListenableBuilder]
/// exactly where they need to rebuild. That keeps repaints scoped to the one
/// number that changed instead of the whole screen — which matters when the
/// meter ticks once a second for an hour.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.app,
    required this.trip,
    required super.child,
  });

  final AppState app;
  final TripState trip;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      app != oldWidget.app || trip != oldWidget.trip;
}
