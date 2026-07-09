import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/team.dart';
import 'package:meta/meta.dart';

/// A futó játék immutable pillanatképe.
///
/// A [frame] a játék sérthetetlen kerete (`ARCHITECTURE.md` 8. fejezet): a
/// setup után nem változik. A [playableIds] a kerettel játszható sablonok
/// **fix** id-mestere, amelyből minden újrakeverés dolgozik; a [remaining] a
/// hátralévő húzási sor (kevert id-k, elölről húzunk). A [lastTemplateId] a
/// legutóbb húzott kártya id-je (a játék elején `null`), az újrakeverési
/// határon a kártyaismétlés tiltásához.
///
/// A fair játékosválasztás állapota (5. fejezet): az [appearanceCounts] a
/// név→megjelenésszám a súlyozáshoz; a [previousParticipants] az előző kártya
/// név szerinti szereplői (a közvetlen ismétlés kizárásához); a
/// [lastWholeTeam] a legutóbbi `wholeTeam`-kártya csapata, ami a közbeeső, nem
/// `wholeTeam` kártyákon átível (a váltakozáshoz), vagy `null`, ha még nem
/// volt ilyen.
///
/// A pakli- és választási algoritmus nem itt, hanem a use case-ekben él
/// (`StartGame`, `DrawTemplate`, `SelectSlot`, `DrawNext`): a [GameState]
/// tiszta adat, egyetlen felelőssége az állapot hordozása (SRP). Csak a
/// `StartGame`/`DrawNext` gyárt [GameState]-et, ezek tartják konzisztensen a
/// mezőket; a fairness-mezők alapértelmezései épp a kezdőállapot értékei.
@immutable
class GameState {
  /// Létrehoz egy [GameState] pillanatképet. A fairness-mezők alapértelmezése
  /// a kezdőállapot (üres történet).
  const GameState({
    required this.frame,
    required this.playableIds,
    required this.remaining,
    required this.lastTemplateId,
    this.appearanceCounts = const {},
    this.previousParticipants = const {},
    this.lastWholeTeam,
  });

  /// A játék kerete: a játékosok csapat-hovatartozásukkal. Játék közben nem
  /// változik.
  final List<Player> frame;

  /// A kerettel játszható sablonok fix id-mestere (az újrakeverés forrása).
  final List<String> playableIds;

  /// A hátralévő húzási sor: kevert id-k, elölről húzva. Kimerüléskor a
  /// [playableIds]-ből keveredik újra.
  final List<String> remaining;

  /// A legutóbb húzott kártya id-je, vagy `null`, ha még nem húztunk.
  final String? lastTemplateId;

  /// Név→megjelenésszám a súlyozott játékosválasztáshoz. Csak a névre
  /// feloldódó kártyák (`anyone`, `sameTeam`, `oppositeTeams`) növelik.
  final Map<String, int> appearanceCounts;

  /// Az előző kártya név szerinti szereplői (a közvetlen ismétlés kizárásához).
  /// `wholeTeam`/`everyone` kártya után üres.
  final Set<String> previousParticipants;

  /// A legutóbbi `wholeTeam`-kártya csapata (a váltakozáshoz), vagy `null`.
  /// Csak `wholeTeam`-kártyán frissül, egyébként átível a közbeeső kártyákon.
  final Team? lastWholeTeam;

  /// Módosított másolat: a meg nem adott mezők változatlanok maradnak.
  ///
  /// Figyelem: a `null`-t felvevő mezőket ([lastTemplateId], [lastWholeTeam])
  /// ezzel nem lehet `null`-ra visszaállítani (a `null` a „ne változzon"
  /// jelentést hordozza). A játékmenetnek erre nincs szüksége: e mezők a
  /// kezdőállapotban `null`-ok, utána már mindig értéket hordoznak.
  GameState copyWith({
    List<Player>? frame,
    List<String>? playableIds,
    List<String>? remaining,
    String? lastTemplateId,
    Map<String, int>? appearanceCounts,
    Set<String>? previousParticipants,
    Team? lastWholeTeam,
  }) {
    return GameState(
      frame: frame ?? this.frame,
      playableIds: playableIds ?? this.playableIds,
      remaining: remaining ?? this.remaining,
      lastTemplateId: lastTemplateId ?? this.lastTemplateId,
      appearanceCounts: appearanceCounts ?? this.appearanceCounts,
      previousParticipants: previousParticipants ?? this.previousParticipants,
      lastWholeTeam: lastWholeTeam ?? this.lastWholeTeam,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GameState &&
        other.lastTemplateId == lastTemplateId &&
        other.lastWholeTeam == lastWholeTeam &&
        _listEquals(other.frame, frame) &&
        _listEquals(other.playableIds, playableIds) &&
        _listEquals(other.remaining, remaining) &&
        _setEquals(other.previousParticipants, previousParticipants) &&
        _mapEquals(other.appearanceCounts, appearanceCounts);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(frame),
    Object.hashAll(playableIds),
    Object.hashAll(remaining),
    lastTemplateId,
    Object.hashAllUnordered(
      appearanceCounts.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(previousParticipants),
    lastWholeTeam,
  );

  @override
  String toString() =>
      'GameState(frame: ${frame.length}, playable: ${playableIds.length}, '
      'remaining: ${remaining.length}, last: $lastTemplateId, '
      'lastWholeTeam: $lastWholeTeam)';
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

/// Sorrendfüggetlen halmazegyenlőség.
bool _setEquals<T>(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);

/// Kulcs-érték párokon alapuló, sorrendfüggetlen térképegyenlőség.
bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
