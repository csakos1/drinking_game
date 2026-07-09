import 'package:igyal2/src/domain/team.dart';
import 'package:meta/meta.dart';

/// Egy játékos: név és csapat-hovatartozás.
///
/// Immutable értékobjektum. A [name] a setup-képernyőn trimmelt, nem üres
/// és a játékoslistán belül egyedi — ezt a beviteli validáció garantálja,
/// nem ez az osztály. A [copyWith] és a szerkezeti egyenlőség kézzel
/// készült, hogy a domain külső csomagtól (pl. equatable) mentes maradjon.
@immutable
class Player {
  /// Létrehoz egy [Player] példányt a megadott [name] névvel és [team]
  /// csapattal.
  const Player({required this.name, required this.team});

  /// A játékos megjelenített neve.
  final String name;

  /// A csapat, amelybe a játékos tartozik.
  final Team team;

  /// Módosított másolat: a meg nem adott mezők változatlanok maradnak.
  Player copyWith({String? name, Team? team}) {
    return Player(name: name ?? this.name, team: team ?? this.team);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Player && other.name == name && other.team == team;
  }

  @override
  int get hashCode => Object.hash(name, team);

  @override
  String toString() => 'Player(name: $name, team: $team)';
}
