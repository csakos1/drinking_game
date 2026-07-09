import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/team.dart';
import 'package:meta/meta.dart';

/// A sablon szereplőválasztásának eredménye (a placeholder-feloldás bemenete).
///
/// Sealed, hogy a feloldásban a `switch` kimerítő legyen. Három ág fedi az öt
/// megkötést: [PlayerSlots] a névre feloldódó megkötésekhez (`anyone`,
/// `sameTeam`, `oppositeTeams`), [TeamSlot] a `wholeTeam`-hez (`{team}`),
/// [NoSlot] az `everyone`-hoz (nincs placeholder).
@immutable
sealed class SlotSelection {
  const SlotSelection();
}

/// Kiválasztott játékos-slotok: a [players] i. eleme a `{p(i+1)}`-re oldódik.
@immutable
final class PlayerSlots extends SlotSelection {
  /// Létrehoz egy [PlayerSlots]-ot a kiválasztott [players] sorrendben.
  const PlayerSlots(this.players);

  /// A slotokhoz rendelt játékosok; a sorrend a `{p1}`..`{pN}` sorrend.
  final List<Player> players;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! PlayerSlots || other.players.length != players.length) {
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
  String toString() => 'PlayerSlots($players)';
}

/// Kiválasztott csapat-slot: a [team] a `{team}` címkéjére oldódik.
@immutable
final class TeamSlot extends SlotSelection {
  /// Létrehoz egy [TeamSlot]-ot a kiválasztott [team]-mel.
  const TeamSlot(this.team);

  /// A `{team}`-re feloldódó csapat.
  final Team team;

  @override
  bool operator ==(Object other) => other is TeamSlot && other.team == team;

  @override
  int get hashCode => team.hashCode;

  @override
  String toString() => 'TeamSlot($team)';
}

/// Nincs slot: az `everyone` megkötés nem választ szereplőt.
@immutable
final class NoSlot extends SlotSelection {
  /// Létrehoz egy [NoSlot]-ot.
  const NoSlot();

  @override
  bool operator ==(Object other) => other is NoSlot;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NoSlot()';
}
