import 'dart:math';

import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/roster.dart';
import 'package:igyal2/src/domain/team.dart';

/// A játékosok két csapatba sorsolása.
///
/// Tiszta use case: a véletlen az injektált [Random]-ból jön (élesben
/// `Random()`, tesztben seedelt), így a sorsolás determinisztikusan
/// tesztelhető. A felosztás kiegyensúlyozott: az egyik csapat ⌈n/2⌉, a másik
/// ⌊n/2⌋ tagot kap; páratlan létszámnál véletlen dönti el, melyik csapaté a
/// nagyobbik fél.
///
/// Az újrasorsolás egyszerűen a [call] ismételt meghívása (a [Random]
/// állapota közben tovább lép); a kézi korrekció nem itt, hanem a
/// [Roster.moveToOtherTeam]-ben történik.
class DrawTeams {
  /// Létrehoz egy [DrawTeams] use case-t.
  const DrawTeams();

  /// A [names] neveket két csapatba sorsolja a [random] segítségével.
  ///
  /// Előfeltétel (a setup-validáció garantálja, ezért itt csak [assert]):
  /// legalább két név, mindegyik nem üres és egyedi. A visszaadott [Roster]
  /// minden nevet pontosan egyszer tartalmaz, csapathoz rendelve.
  Roster call(List<String> names, Random random) {
    assert(
      names.length >= 2,
      'A sorsoláshoz legalább két játékos kell; a setup ezt garantálja.',
    );
    assert(
      names.every((name) => name.trim().isNotEmpty),
      'A nevek nem lehetnek üresek; a setup-validáció garantálja.',
    );
    assert(
      names.toSet().length == names.length,
      'A neveknek egyedieknek kell lenniük; a setup-validáció garantálja.',
    );

    final shuffled = [...names]..shuffle(random);
    final count = shuffled.length;
    final smallerHalf = count ~/ 2; // ⌊n/2⌋

    // Páros létszámnál a két fél egyenlő (⌈n/2⌉ == ⌊n/2⌋), ilyenkor nem
    // sorsolunk irányt. Páratlannál a nagyobbik (⌈n/2⌉-es) fél véletlen
    // döntéssel kerül az első vagy a második csapathoz.
    final firstSize = count.isOdd && random.nextBool() ? smallerHalf + 1 : smallerHalf;

    final players = <Player>[
      for (var index = 0; index < count; index++)
        Player(
          name: shuffled[index],
          team: index < firstSize ? Team.first : Team.second,
        ),
    ];
    return Roster(players);
  }
}
