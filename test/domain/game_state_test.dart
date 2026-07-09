import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/game_state.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/team.dart';

void main() {
  GameState state({
    List<Player>? frame,
    List<String>? playableIds,
    List<String>? remaining,
    String? lastTemplateId = 'c0',
    Map<String, int>? appearanceCounts,
    Set<String>? previousParticipants,
    Team? lastWholeTeam,
  }) {
    return GameState(
      frame: frame ?? const [Player(name: 'A', team: Team.first)],
      playableIds: playableIds ?? const ['c0', 'c1'],
      remaining: remaining ?? const ['c1'],
      lastTemplateId: lastTemplateId,
      appearanceCounts: appearanceCounts ?? const {'A': 2},
      previousParticipants: previousParticipants ?? const {'A'},
      lastWholeTeam: lastWholeTeam,
    );
  }

  group('GameState.copyWith', () {
    test('csak a megadott mezőt cseréli', () {
      final base = state();
      final next = base.copyWith(remaining: const ['c0']);
      expect(next.remaining, ['c0']);
      expect(next.playableIds, base.playableIds);
      expect(next.frame, base.frame);
      expect(next.lastTemplateId, base.lastTemplateId);
    });

    test('a fairness-mezőket cseréli', () {
      final base = state();
      final next = base.copyWith(
        appearanceCounts: const {'X': 9},
        previousParticipants: const {'X'},
        lastWholeTeam: Team.second,
      );
      expect(next.appearanceCounts, {'X': 9});
      expect(next.previousParticipants, {'X'});
      expect(next.lastWholeTeam, Team.second);
    });

    test('argumentum nélkül azonos másolat', () {
      final base = state();
      expect(base.copyWith(), base);
    });
  });

  group('GameState egyenlőség', () {
    test('minden mező azonos → egyenlő, hashCode is', () {
      expect(state(), state());
      expect(state().hashCode, state().hashCode);
    });

    test('eltérő remaining nem egyenlő', () {
      expect(state(remaining: const ['c0']), isNot(state()));
    });

    test('eltérő lastTemplateId nem egyenlő', () {
      expect(state(lastTemplateId: 'c1'), isNot(state()));
    });

    test('eltérő appearanceCounts nem egyenlő', () {
      expect(state(appearanceCounts: const {'A': 3}), isNot(state()));
    });

    test('eltérő previousParticipants nem egyenlő', () {
      expect(state(previousParticipants: const {'B'}), isNot(state()));
    });

    test('eltérő lastWholeTeam nem egyenlő', () {
      expect(state(lastWholeTeam: Team.first), isNot(state()));
    });

    test('appearanceCounts sorrendfüggetlen', () {
      final a = state(appearanceCounts: const {'A': 1, 'B': 2});
      final b = state(appearanceCounts: const {'B': 2, 'A': 1});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('previousParticipants sorrendfüggetlen', () {
      final a = state(previousParticipants: const {'A', 'B'});
      final b = state(previousParticipants: const {'B', 'A'});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('GameState.toString', () {
    test('tartalmazza a méreteket és a wholeTeam-csapatot', () {
      final text = state(lastWholeTeam: Team.first).toString();
      expect(text, contains('remaining: 1'));
      expect(text, contains('last: c0'));
      expect(text, contains('lastWholeTeam: Team.first'));
    });
  });
}
