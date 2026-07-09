import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/team.dart';

void main() {
  group('Team.opposite', () {
    test('first ellentéte second', () {
      expect(Team.first.opposite, Team.second);
    });

    test('second ellentéte first', () {
      expect(Team.second.opposite, Team.first);
    });

    test('kétszeres ellentét visszaad', () {
      // Given: bármelyik csapat; When: kétszer ellentétezünk;
      // Then: önmagát kapjuk vissza (involúció).
      for (final team in Team.values) {
        expect(team.opposite.opposite, team);
      }
    });
  });
}
