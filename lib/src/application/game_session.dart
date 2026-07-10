import 'package:igyal2/src/domain/game_state.dart';
import 'package:igyal2/src/domain/resolved_card.dart';
import 'package:igyal2/src/domain/roster.dart';
import 'package:meta/meta.dart';

/// A játék-session állapota: a setup, a csapat-áttekintő és a futó játék közti
/// egyetlen, sealed állapottípus.
///
/// Három konkrét állapota van: [GameSetup] (nevek bevitele két csapatba),
/// [GameTeams] (a kész csapatok áttekintése), [GamePlaying] (futó kártyafolyam).
/// A sealed jelleg a `switch`-ek kimerítőségét garantálja. Az állapotok
/// immutable pillanatképek; minden művelet új példányt állít elő, amelyre a
/// `Notifier` átvált. Szándékosan nincs érték-egyenlőség: minden kártyaléptetés
/// új kártyát jelent, amiről a UI-t értesíteni kell.
@immutable
sealed class GameSession {
  const GameSession();
}

/// A setup-fázis: a két csapatba közvetlenül bevitt nevek (lásd ADR-0003).
///
/// A [firstNames] és [secondNames] a két csapat nevei; trimmeltek, nem üresek,
/// és a két listán keresztül is egyediek (egy név csak egy csapatban lehet). A
/// csapatalkotás módját az IGYUNK-nál a lista-állapot dönti el ([canProceed]).
final class GameSetup extends GameSession {
  /// Létrehoz egy [GameSetup] állapotot a két (alapból üres) névlistával.
  const GameSetup({this.firstNames = const [], this.secondNames = const []});

  /// Az első csapat nevei.
  final List<String> firstNames;

  /// A második csapat nevei.
  final List<String> secondNames;

  /// Igaz, ha az IGYUNK gomb aktív: vagy csak az első csapat van kitöltve
  /// legalább két névvel (véletlen auto-split), vagy mindkét csapatban van
  /// legalább egy név (kézi csapatok).
  bool get canProceed =>
      (secondNames.isEmpty && firstNames.length >= 2) ||
      (firstNames.isNotEmpty && secondNames.isNotEmpty);
}

/// A csapat-áttekintő fázis: a kész [Roster], indításra készen.
///
/// A [wasAutoSplit] igaz, ha a keret véletlen felosztásból jött — ilyenkor van
/// értelme az újrasorsolásnak. Kézi csapatoknál hamis.
final class GameTeams extends GameSession {
  /// Létrehoz egy [GameTeams] állapotot a [roster] kerettel.
  const GameTeams({required this.roster, required this.wasAutoSplit});

  /// A kész csapatbeosztás.
  final Roster roster;

  /// Igaz, ha a keret véletlen auto-splitből származik.
  final bool wasAutoSplit;
}

/// A futó játék: a pakli aktuális állapota és az épp látható, feloldott kártya.
///
/// A pakli- és fairness-állapotot a [state] hordozza, a megjeleníthető kártyát a
/// [card]. A [roster] a kilépéskori visszatéréshez (az áttekintőbe) őrződik meg.
final class GamePlaying extends GameSession {
  /// Létrehoz egy [GamePlaying] állapotot.
  const GamePlaying({
    required this.state,
    required this.card,
    required this.roster,
  });

  /// A pakli és a fair választás aktuális állapota.
  final GameState state;

  /// Az épp látható, feloldott kártya.
  final ResolvedCard card;

  /// A játékhoz tartozó keret (kilépéskor az áttekintőbe visszatéréshez).
  final Roster roster;
}
