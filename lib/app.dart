import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/l10n.dart';
import 'core/tokens.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

class SanjibaniApp extends StatelessWidget {
  const SanjibaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'Battar Sanjibani',
      onGenerateTitle: (context) => L10n.of(context).isEn
          ? 'Battar Sanjibani Polyclinic'
          : 'बट्टार सञ्जीवनी पॉलीक्लिनिक',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(state.palette, state.fonts),
      darkTheme: AppTheme.dark(state.palette, state.fonts),
      themeMode: state.themeMode,
      locale: Locale(state.language.code),
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeAnimationDuration: AppTokens.motionTheme,
      themeAnimationCurve: AppTokens.ease,
      home: const SplashGate(),
    );
  }
}
