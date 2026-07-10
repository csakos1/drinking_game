import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igyal2/src/application/game_providers.dart';
import 'package:igyal2/src/application/game_session.dart';
import 'package:igyal2/src/domain/team.dart';
import 'package:igyal2/src/presentation/l10n/app_strings.dart';
import 'package:igyal2/src/presentation/theme/app_colors.dart';
import 'package:igyal2/src/presentation/theme/app_theme.dart';

/// A setup-képernyő (álló): a két csapatba történő névbevitel, majd az IGYUNK
/// gombbal a feltételes csapatalkotás (lásd ADR-0003).
///
/// A nevek a [GameSessionNotifier.add]/[GameSessionNotifier.remove] metódusokon
/// keresztül kerülnek a session-be; az IGYUNK a [GameSessionNotifier.proceed]-et
/// hívja, és csak akkor aktív, ha a [GameSetup.canProceed] igaz. A képernyő álló
/// orientációt kényszerít; a fogaskerék v1-ben szándékosan funkció nélküli.
class SetupScreen extends ConsumerStatefulWidget {
  /// Létrehoz egy [SetupScreen] példányt.
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // A setup álló módban jelenik meg (a csapat-áttekintő és a kártya fekvő).
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]),
    );
  }

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  /// A [controller] aktuális nevét felveszi a [team] csapatba, és üríti a mezőt.
  /// A trimmelést és a duplikátumszűrést a notifier végzi; üres bevitelnél nincs
  /// teendő.
  void _submit(TextEditingController controller, Team team) {
    final name = controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    ref.read(gameSessionProvider.notifier).add(name, team);
    controller.clear();
  }

  /// A beállítások gomb v1-ben szándékosan nem csinál semmit (a fogaskerék helye
  /// megvan, a valódi képernyő későbbi slice). Külön metódus, hogy a szándék
  /// dokumentált és később bővíthető legyen (OCP).
  void _onSettingsTap() {}

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final session = ref.watch(gameSessionProvider);
    // A router miatt itt mindig GameSetup van; a proceed pillanatában a state
    // átvált, ekkor a képernyő már kikerül — a guard csak védelem.
    if (session is! GameSetup) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(gameSessionProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  strings.appTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    fontSize: 40,
                    letterSpacing: 1.5,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TeamCard(
                        title: strings.firstTeam,
                        names: session.firstNames,
                        isActive: true,
                        controller: _firstController,
                        inputKey: const Key('first_team_input'),
                        addTooltip: strings.addPlayer,
                        onSubmit: () => _submit(_firstController, Team.first),
                        onRemove: (name) => notifier.remove(name, Team.first),
                      ),
                      const SizedBox(height: 14),
                      _TeamCard(
                        title: strings.secondTeam,
                        names: session.secondNames,
                        isActive: session.secondNames.isNotEmpty,
                        controller: _secondController,
                        inputKey: const Key('second_team_input'),
                        addTooltip: strings.addPlayer,
                        hint: session.secondNames.isEmpty ? strings.autoSplitTip : null,
                        onSubmit: () => _submit(_secondController, Team.second),
                        onRemove: (name) => notifier.remove(name, Team.second),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CheersButton(
                      label: strings.cheers,
                      onPressed: session.canProceed ? notifier.proceed : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _onSettingsTap,
                    icon: const Icon(Icons.settings),
                    color: AppColors.neutral,
                    iconSize: 30,
                    tooltip: strings.settings,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Egy csapat setup-kártyája: fejléc, a felvett nevek (törölhetők) és egy
/// névbeviteli sor.
///
/// Aktív állapotban ([isActive]) mély zöld, inaktívban (üres második csapat)
/// semleges szürke; ilyenkor a [hint] tippszöveg is megjelenik. A fejléc a
/// comic display-fonttal, accent-zölddel jelenik meg.
class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.title,
    required this.names,
    required this.isActive,
    required this.controller,
    required this.inputKey,
    required this.addTooltip,
    required this.onSubmit,
    required this.onRemove,
    this.hint,
  });

  final String title;
  final List<String> names;
  final bool isActive;
  final TextEditingController controller;
  final Key inputKey;
  final String addTooltip;
  final String? hint;
  final VoidCallback onSubmit;
  final void Function(String name) onRemove;

  @override
  Widget build(BuildContext context) {
    final tip = hint;
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.deep : AppColors.neutral,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 26,
              letterSpacing: 1,
              color: AppColors.accent,
            ),
          ),
          if (tip != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tip,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.onBackground,
                ),
              ),
            ),
          for (final name in names) _PlayerRow(name: name, onRemove: () => onRemove(name)),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              key: inputKey,
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.onBackground,
              ),
              decoration: InputDecoration(
                hintText: addTooltip,
                hintStyle: TextStyle(
                  color: AppColors.onBackground.withValues(alpha: 0.5),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent, width: 2),
                ),
                suffixIcon: IconButton(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.add_circle),
                  color: AppColors.onBackground,
                  tooltip: addTooltip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Egy felvett játékos sora a csapat-kártyán: a név és egy törlés-ikon.
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.onBackground,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            color: AppColors.onBackground,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Az IGYUNK gomb: CTA-zöld kitöltés, comic betűtípus.
///
/// Az [onPressed] `null` értéke letiltja a gombot (amíg a [GameSetup.canProceed]
/// hamis); ilyenkor semleges szürke háttérrel, halvány felirattal jelenik meg.
class _CheersButton extends StatelessWidget {
  const _CheersButton({required this.label, required this.onPressed});

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
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_bar),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 28,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
