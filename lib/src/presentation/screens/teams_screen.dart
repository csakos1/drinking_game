import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igyal2/src/application/game_providers.dart';
import 'package:igyal2/src/application/game_session.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/presentation/l10n/app_strings.dart';
import 'package:igyal2/src/presentation/theme/app_colors.dart';
import 'package:igyal2/src/presentation/theme/app_theme.dart';

/// A csapat-áttekintő képernyő (fekvő): a kész keret két oszlopban, KEZDÉS-sel.
///
/// A két oszlop a [GameTeams.roster] `first`/`second` tagjait sorolja fel. A
/// KEZDÉS a [GameSessionNotifier.start]-ot hívja (és a betöltés idejére letiltja
/// magát, hogy egy dupla koppintás ne indítson két paklit); az ÚJRASORSOLÁS csak
/// auto-splitből származó keretnél ([GameTeams.wasAutoSplit]) jelenik meg és a
/// [GameSessionNotifier.redraw]-t hívja; a VISSZA a
/// [GameSessionNotifier.backToSetup]-pal a névbevitelhez tér vissza. A képernyő
/// fekvő orientációt kényszerít.
class TeamsScreen extends ConsumerStatefulWidget {
  /// Létrehoz egy [TeamsScreen] példányt.
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  var _isStarting = false;

  @override
  void initState() {
    super.initState();
    // A csapat-áttekintő (mint a kártya) fekvő módban jelenik meg.
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  /// Elindítja a játékot, és a betöltés idejére letiltja a KEZDÉS gombot. A
  /// sikeres indítás [GamePlaying]-re vált, ekkor a képernyő kikerül; ha az
  /// indítás mégsem vált (pl. nem indítható keret), a gomb visszaáll.
  Future<void> _start() async {
    setState(() => _isStarting = true);
    try {
      await ref.read(gameSessionProvider.notifier).start();
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final session = ref.watch(gameSessionProvider);
    // A router miatt itt mindig GameTeams van; a guard csak védelem az átmenet
    // pillanatára.
    if (session is! GameTeams) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(gameSessionProvider.notifier);
    final roster = session.roster;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: notifier.backToSetup,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(strings.back),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onBackground,
                    ),
                  ),
                  const Spacer(),
                  if (session.wasAutoSplit)
                    OutlinedButton.icon(
                      onPressed: notifier.redraw,
                      icon: const Icon(Icons.refresh),
                      label: Text(strings.redraw),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TeamColumn(
                        title: strings.firstTeam,
                        players: roster.first,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _TeamColumn(
                        title: strings.secondTeam,
                        players: roster.second,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: _StartButton(
                  label: strings.start,
                  onPressed: _isStarting ? null : () => unawaited(_start()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Egy csapat oszlopa: comic fejléc (accent-zöld) és a görgethető névsor.
class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.title, required this.players});

  final String title;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTheme.displayFontFamily,
            fontSize: 30,
            letterSpacing: 1,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final player in players)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      player.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A KEZDÉS gomb: CTA-zöld kitöltés, comic betűtípus, a felirat köré szabott
/// (kompakt) szélességgel.
///
/// Az [onPressed] `null` értéke letiltja a gombot (a betöltés idejére), ekkor
/// semleges szürke háttérrel, halvány felirattal jelenik meg.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.cta,
        foregroundColor: AppColors.deep,
        disabledBackgroundColor: AppColors.neutral,
        disabledForegroundColor: AppColors.onBackground.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.displayFontFamily,
          fontSize: 28,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
