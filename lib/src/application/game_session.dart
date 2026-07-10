import 'package:igyal2/src/domain/game_state.dart';
import 'package:igyal2/src/domain/resolved_card.dart';
import 'package:igyal2/src/domain/roster.dart';
import 'package:meta/meta.dart';

/// A játék-session állapota: a setup és a futó játék közti egyetlen, sealed
/// állapottípus.
///
/// Két konkrét állapota van: [GameSetup] (nevek + csapatok összeállítása) és
/// [GamePlaying] (futó kártyafolyam). A sealed jelleg a `switch`-ek
/// kimerítőségét garantálja. Az állapotok immutable pillanatképek; minden
/// művelet új példányt állít elő, amelyre a `Notifier` átvált. Szándékosan
/// nincs érték-egyenlőség: minden kártyaléptetés új kártyát jelent, amiről a
/// UI-t értesíteni kell, ezért az identitás-alapú különbözőség a kívánt.
@immutable
sealed class GameSession {
  const GameSession();
}

/// A setup-fázis: a beírt nevek és — sorsolás után — az aktuális csapatbeosztás.
///
/// A [names] a nevek forrása (trimmelt, nem üres, egyedi elemek). A [roster] a
/// legutóbbi sorsolás vagy kézi korrekció eredménye, vagy `null`, ha még nem
/// sorsoltunk. Ha a névlista változik, a [roster] `null`-ra ürül (újrasorsolás
/// kell), így a két szerkezet sosem kerül inkonzisztens állapotba.
final class GameSetup extends GameSession {
  /// Létrehoz egy [GameSetup] állapotot a [names] névlistával és opcionális
  /// [roster] csapatbeosztással.
  const GameSetup({required this.names, this.roster});

  /// A beírt nevek (trimmelt, nem üres, egyedi elemek).
  final List<String> names;

  /// Az aktuális csapatbeosztás, vagy `null`, ha még nem sorsoltunk.
  final Roster? roster;

  /// Igaz, ha van elég név a sorsoláshoz (legalább kettő).
  bool get canDraw => names.length >= 2;

  /// Igaz, ha a játék indítható: van sorsolt keret, és mindkét csapatban van
  /// legalább egy fő.
  bool get canStart => roster?.isStartable ?? false;
}

/// A futó játék: a pakli aktuális állapota és az épp látható, feloldott kártya.
///
/// A pakli- és fairness-állapotot a [state] hordozza, a megjeleníthető kártyát a
/// [card]. A [roster] a kilépéskori visszatéréshez (a setup-ba) őrződik meg.
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

  /// A játékhoz tartozó keret (a kilépéskor a setup-ba visszatéréshez).
  final Roster roster;
}
