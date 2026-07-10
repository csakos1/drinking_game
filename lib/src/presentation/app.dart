import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igyal2/src/application/game_providers.dart';
import 'package:igyal2/src/application/game_session.dart';
import 'package:igyal2/src/presentation/theme/app_colors.dart';
import 'package:igyal2/src/presentation/theme/app_theme.dart';

/// Az Igyál 2 gyökérwidgetje: téma + az állapotvezérelt képernyőváltás.
class IgyalApp extends StatelessWidget {
  /// Létrehoz egy [IgyalApp] példányt.
  const IgyalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Igyál 2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _SessionRouter(),
    );
  }
}

/// A `GameSession`-re kapcsoló képernyő-router.
///
/// A fő folyamot az állapotgép vezérli (nincs explicit Navigator): a sealed
/// [GameSession] konkrét típusa dönti el, melyik képernyő látszik. P1-ben még
/// témázott placeholderek állnak a valós képernyők helyén (P2–P4).
class _SessionRouter extends ConsumerWidget {
  const _SessionRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    return switch (session) {
      GameSetup() => const _Placeholder(label: 'Setup', portrait: true),
      GameTeams() => const _Placeholder(label: 'Csapatok', portrait: false),
      GamePlaying() => const _Placeholder(label: 'Kártya', portrait: false),
    };
  }
}

/// Ideiglenes, témázott placeholder egy állapothoz; a valós képernyőt a
/// megfelelő presentation-szelet cseréli be. Az orientációt az állapothoz
/// igazítja (setup álló, a többi fekvő).
class _Placeholder extends StatefulWidget {
  const _Placeholder({required this.label, required this.portrait});

  final String label;
  final bool portrait;

  @override
  State<_Placeholder> createState() => _PlaceholderState();
}

class _PlaceholderState extends State<_Placeholder> {
  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations(
        widget.portrait
            ? const [DeviceOrientation.portraitUp]
            : const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          widget.label,
          style: const TextStyle(
            fontFamily: AppTheme.displayFontFamily,
            fontSize: 44,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
