import 'dart:math';

import 'package:igyal2/src/domain/game_state.dart';

/// Egyetlen kártya-id húzása a pakliból (B2: még feloldás nélkül).
///
/// Tiszta use case, a véletlen az injektált [Random]-ból jön. A húzás a
/// [GameState.remaining] elejéről történik, ismétlés nélkül; a pakli
/// kimerülésekor a [GameState.playableIds] mesterből keveredik újra. Az
/// újrakeverési határon nincs kártyaismétlés: ha a mesterben egynél több
/// sablon van, az új sor első lapja nem egyezhet a legutóbb húzottal
/// ([GameState.lastTemplateId]).
///
/// A húzott id-ből a szöveg feloldása (`ResolvedCard`, fair játékosválasztás,
/// `teamLabels`) a B3 szelet feladata; ez a lépés csak az id-t és a
/// következő állapotot adja vissza.
class DrawTemplate {
  /// Létrehoz egy [DrawTemplate] use case-t.
  const DrawTemplate();

  /// A [state] pakliból húz egy kártya-id-t a [random] segítségével.
  ///
  /// Visszaadja a húzott `templateId`-t és a léptetett `state`-et (a húzott
  /// lap lekerül a sorról, a [GameState.lastTemplateId] frissül).
  ({String templateId, GameState state}) call(GameState state, Random random) {
    final queue = state.remaining.isNotEmpty
        ? state.remaining
        : _reshuffle(state.playableIds, state.lastTemplateId, random);

    final templateId = queue.first;
    final next = state.copyWith(
      remaining: queue.sublist(1),
      lastTemplateId: templateId,
    );
    return (templateId: templateId, state: next);
  }

  /// A [master]-t megkeveri új húzási sorrá.
  ///
  /// Ha egynél több lap van és az új első lap a [avoidFirst]-tel egyezik, egy
  /// másik pozícióval megcseréli — így a határon nem ismétlődik kártya. Az
  /// id-k egyediek (validált tartalom), ezért egyetlen csere garantáltan
  /// eltérő első lapot ad. Egyetlen lapos mesternél a szabály nem
  /// alkalmazható (nincs alternatíva), ilyenkor az ismétlés megengedett.
  List<String> _reshuffle(
    List<String> master,
    String? avoidFirst,
    Random random,
  ) {
    final deck = [...master]..shuffle(random);
    if (master.length > 1 && avoidFirst != null && deck.first == avoidFirst) {
      final swapIndex = 1 + random.nextInt(master.length - 1);
      final displaced = deck[swapIndex];
      deck[swapIndex] = deck.first;
      deck[0] = displaced;
    }
    return deck;
  }
}
