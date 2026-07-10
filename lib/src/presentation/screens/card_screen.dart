import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igyal2/src/application/game_providers.dart';
import 'package:igyal2/src/application/game_session.dart';
import 'package:igyal2/src/domain/task_type.dart';
import 'package:igyal2/src/presentation/card_text.dart';
import 'package:igyal2/src/presentation/l10n/app_strings.dart';
import 'package:igyal2/src/presentation/theme/app_colors.dart';
import 'package:igyal2/src/presentation/theme/app_theme.dart';

/// A kártya-képernyő (fekvő): egy feloldott feladatkártya, teljes képernyőn.
///
/// A típuscímet a kártya [TaskType]-ja adja (csak a `virus` accent-zöld, a többi
/// fehér); a szövegben a csapatcímkék ([teamLabelsProvider]) accent-zölddel
/// kiemelve jelennek meg. Bárhová koppintva a [GameSessionNotifier.next] lépteti
/// a paklit (nincs visszalépés a kártyák közt); az OS-vissza gomb megerősítő
/// párbeszéd után a [GameSessionNotifier.quit]-tel az áttekintőbe tér vissza. A
/// képernyő fekvő orientációt kényszerít.
class CardScreen extends ConsumerStatefulWidget {
  /// Létrehoz egy [CardScreen] példányt.
  const CardScreen({super.key});

  @override
  ConsumerState<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends ConsumerState<CardScreen> {
  @override
  void initState() {
    super.initState();
    // A kártya fekvő módban jelenik meg.
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  /// Megerősítő párbeszéd a kilépéshez. „Kilépés" esetén a
  /// [GameSessionNotifier.quit] a keret megőrzésével az áttekintőbe tér vissza;
  /// „Mégse" esetén a kártyán marad.
  Future<void> _confirmQuit() async {
    final strings = AppStrings.of(context);
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.quitTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.quitCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.quitConfirm),
            ),
          ],
        );
      },
    );
    if (shouldQuit ?? false) {
      ref.read(gameSessionProvider.notifier).quit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final session = ref.watch(gameSessionProvider);
    // A router miatt itt mindig GamePlaying van; a guard csak védelem.
    if (session is! GamePlaying) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(gameSessionProvider.notifier);
    final card = session.card;
    final labels = ref.read(teamLabelsProvider).values;
    final isVirus = card.type == TaskType.virus;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_confirmQuit());
        }
      },
      child: Scaffold(
        body: GestureDetector(
          key: const Key('card_tap_area'),
          onTap: notifier.next,
          behavior: HitTestBehavior.opaque,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _typeLabel(card.type, strings),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      fontSize: 40,
                      letterSpacing: 1.5,
                      color: isVirus ? AppColors.accent : AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text.rich(
                    TextSpan(
                      children: teamHighlightSpans(
                        card.text,
                        labels,
                        AppColors.accent,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.3,
                      color: AppColors.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A [type] magyar címkéje az [strings] katalógusból (kimerítő leképezés).
String _typeLabel(TaskType type, AppStrings strings) {
  return switch (type) {
    TaskType.jatek => strings.typeJatek,
    TaskType.parbaj => strings.typeParbaj,
    TaskType.virus => strings.typeVirus,
    TaskType.feladat => strings.typeFeladat,
    TaskType.activity => strings.typeActivity,
    TaskType.egyeb => strings.typeEgyeb,
  };
}
