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
  }) {
    return GameState(
      frame: frame ?? const [Player(name: 'A', team: Team.first)],
      playableIds: playableIds ?? const ['c0', 'c1'],
      remaining: remaining ?? const ['c1'],
      lastTemplateId: lastTemplateId,
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

    test('eltérő playableIds nem egyenlő', () {
      expect(state(playableIds: const ['c0']), isNot(state()));
    });

    test('eltérő frame nem egyenlő', () {
      expect(
        state(
          frame: const [Player(name: 'Z', team: Team.first)],
        ),
        isNot(state()),
      );
    });

    test('null lastTemplateId a kezdőállapotban megkülönböztethető', () {
      expect(state(lastTemplateId: null), isNot(state()));
    });
  });

  group('GameState.toString', () {
    test('tartalmazza a méreteket', () {
      final text = state().toString();
      expect(text, contains('remaining: 1'));
      expect(text, contains('last: c0'));
    });
  });
}
