import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/app_state.dart';

void main() {
  runZonedGuarded<Future<void>>(_bootstrap, reportUncaught);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reportUncaught(details.exception, details.stack);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    reportUncaught(error, stack);
    return true;
  };

  final state = await AppState.load();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const SanjibaniApp(),
    ),
  );
}

/// Without a crash SDK this is the only record a field problem leaves, so
/// anything that escapes the widget tree has to reach logcat.
void reportUncaught(Object error, StackTrace? stack) {
  debugPrint('Uncaught error: $error');
  if (stack != null) debugPrint(stack.toString());
}
