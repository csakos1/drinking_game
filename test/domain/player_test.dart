import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/team.dart';

void main() {
  group('Player egyenlőség', () {
    test('azonos név és csapat egyenlő', () {
      const a = Player(name: 'Anna', team: Team.first);
      const b = Player(name: 'Anna', team: Team.first);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('eltérő név nem egyenlő', () {
      const a = Player(name: 'Anna', team: Team.first);
      const b = Player(name: 'Béla', team: Team.first);
      expect(a, isNot(b));
    });

    test('eltérő csapat nem egyenlő', () {
      const a = Player(name: 'Anna', team: Team.first);
      const b = Player(name: 'Anna', team: Team.second);
      expect(a, isNot(b));
    });

    test('önmagával azonos (identikus)', () {
      const a = Player(name: 'Anna', team: Team.first);
      expect(a, a);
    });
  });

  group('Player.copyWith', () {
    const base = Player(name: 'Anna', team: Team.first);

    test('csak a nevet cseréli', () {
      expect(
        base.copyWith(name: 'Csaba'),
        const Player(name: 'Csaba', team: Team.first),
      );
    });

    test('csak a csapatot cseréli', () {
      expect(
        base.copyWith(team: Team.second),
        const Player(name: 'Anna', team: Team.second),
      );
    });

    test('argumentum nélkül azonos másolat', () {
      expect(base.copyWith(), base);
    });
  });
}
