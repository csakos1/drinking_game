import 'package:igyal2/src/domain/player.dart';
import 'package:meta/meta.dart';

/// A futó játék immutable pillanatképe (B2: pakli-állapot).
///
/// A [frame] a játék sérthetetlen kerete (`ARCHITECTURE.md` 8. fejezet): a
/// setup után nem változik. A [playableIds] a kerettel játszható sablonok
/// **fix** id-mestere, amelyből minden újrakeverés dolgozik; a [remaining] a
/// hátralévő húzási sor (kevert id-k, elölről húzunk). A [lastTemplateId] a
/// legutóbb húzott kártya id-je (a játék elején `null`), az újrakeverési
/// határon a kártyaismétlés tiltásához.
///
/// A fair játékosválasztás mezői (megjelenésszámok, előző kártya szereplői,
/// utolsó `wholeTeam`-csapat) szándékosan a B3 szeletben csatlakoznak, amikor
/// a logikájuk használja őket — most nem viszünk üres vázat előre.
///
/// A pakli-algoritmus nem itt, hanem a use case-ekben él (`StartGame`,
/// `DrawTemplate`): a [GameState] tiszta adat, egyetlen felelőssége az
/// állapot hordozása (SRP).
@immutable
class GameState {
  /// Létrehoz egy [GameState] pillanatképet.
  const GameState({
    required this.frame,
    required this.playableIds,
    required this.remaining,
    required this.lastTemplateId,
  });

  /// A játék kerete: a játékosok csapat-hovatartozásukkal. Játék közben nem
  /// változik.
  final List<Player> frame;

  /// A kerettel játszható sablonok fix id-mestere (az újrakeverés forrása).
  final List<String> playableIds;

  /// A hátralévő húzási sor: kevert id-k, elölről húzva. Kimerüléskor a
  /// [playableIds]-ből keveredik újra.
  final List<String> remaining;

  /// A legutóbb húzott kártya id-je, vagy `null`, ha még nem húztunk. Az
  /// újrakeverési határon ehhez képest tiltjuk a közvetlen ismétlést.
  final String? lastTemplateId;

  /// Módosított másolat: a meg nem adott mezők változatlanok maradnak.
  ///
  /// Figyelem: a [lastTemplateId]-t `null`-ra nem lehet visszaállítani ezzel
  /// (a `null` a „ne változzon" jelentést hordozza). A játékmenetnek erre
  /// nincs is szüksége: a `null` csak a kezdőállapotban fordul elő, húzás
  /// után az érték már mindig egy id.
  GameState copyWith({
    List<Player>? frame,
    List<String>? playableIds,
    List<String>? remaining,
    String? lastTemplateId,
  }) {
    return GameState(
      frame: frame ?? this.frame,
      playableIds: playableIds ?? this.playableIds,
      remaining: remaining ?? this.remaining,
      lastTemplateId: lastTemplateId ?? this.lastTemplateId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GameState &&
        other.lastTemplateId == lastTemplateId &&
        _listEquals(other.frame, frame) &&
        _listEquals(other.playableIds, playableIds) &&
        _listEquals(other.remaining, remaining);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(frame),
    Object.hashAll(playableIds),
    Object.hashAll(remaining),
    lastTemplateId,
  );

  @override
  String toString() =>
      'GameState(frame: ${frame.length}, playable: ${playableIds.length}, '
      'remaining: ${remaining.length}, last: $lastTemplateId)';
}

/// Elemenkénti, sorrendtartó listaegyenlőség (a domain nem függ külső
/// collection-csomagtól).
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
