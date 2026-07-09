import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/team.dart';
import 'package:meta/meta.dart';

/// A setup-fázis csapatbeosztása: a játékosok és aktuális csapatuk.
///
/// Immutable value object. A csapat-hovatartozás egyetlen forrása a
/// [Player.team]; a [Roster] nem duplikálja külön csapatlistákba, hanem a
/// [players] lapos listájából származtatja a csapatnézeteket ([first],
/// [second]). Így nincs két, egymással szinkronban tartandó szerkezet, és a
/// kézi korrekció ([moveToOtherTeam]) egyetlen mezőt billent.
///
/// A [Roster] a setup és a játék közti átadás egysége; a sablonmotor a
/// belőle kinyert `List<Player>` kereten dolgozik, magát a [Roster]-t nem
/// ismeri (a domain így a setup-fogalmat nem szivárogtatja a játékmenetbe).
@immutable
class Roster {
  /// Létrehoz egy [Roster]-t a [players] játékoslistával.
  ///
  /// A hívó felel azért, hogy a nevek trimmeltek, nem üresek és egyediek
  /// legyenek (a setup-validáció garantálja); a [Roster] ezt nem ellenőrzi.
  const Roster(this.players);

  /// A keret összes játékosa, csapat-hovatartozásukkal együtt.
  final List<Player> players;

  /// Az első csapat tagjai, a [players]-beli sorrendben.
  List<Player> get first => players.where((player) => player.team == Team.first).toList();

  /// A második csapat tagjai, a [players]-beli sorrendben.
  List<Player> get second => players.where((player) => player.team == Team.second).toList();

  /// Az első csapat létszáma.
  int get firstCount => players.where((player) => player.team == Team.first).length;

  /// A második csapat létszáma.
  int get secondCount => players.where((player) => player.team == Team.second).length;

  /// Igaz, ha a játék elindítható: mindkét csapatban van legalább egy fő.
  ///
  /// Ez az egyetlen indítási feltétel (`ARCHITECTURE.md` 6. fejezet). A kézi
  /// korrekció felboríthatja az egyensúlyt, de amíg egyik csapat sem üres, a
  /// „Kezdés" aktív.
  bool get isStartable => firstCount >= 1 && secondCount >= 1;

  /// A [player] átmozgatása a másik csapatba (kézi korrekció).
  ///
  /// A játékost név szerint azonosítja: a nevek a kereten belül egyediek, így
  /// a név a stabil identitás, miközben a csapat épp változik. A megtalált
  /// játékos csapata a [Team.opposite]-ra billen, a többi érintetlen marad, a
  /// [players] sorrendje megőrződik. Ismeretlen nevet debugban [assert]
  /// jelez; élesben ilyenkor a [Roster] változatlan marad (a UI úgyis csak a
  /// keretben lévő játékost tud átmozgatni).
  Roster moveToOtherTeam(Player player) {
    assert(
      players.any((candidate) => candidate.name == player.name),
      'A(z) "${player.name}" nevű játékos nincs a keretben.',
    );
    final updated = [
      for (final candidate in players)
        if (candidate.name == player.name)
          candidate.copyWith(team: candidate.team.opposite)
        else
          candidate,
    ];
    return Roster(updated);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Roster || other.players.length != players.length) {
      return false;
    }
    for (var i = 0; i < players.length; i++) {
      if (other.players[i] != players[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(players);

  @override
  String toString() => 'Roster(first: $firstCount, second: $secondCount)';
}
