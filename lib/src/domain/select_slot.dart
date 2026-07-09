import 'dart:math';

import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/slot_constraint.dart';
import 'package:igyal2/src/domain/slot_selection.dart';
import 'package:igyal2/src/domain/team.dart';

/// A sablon megkötéséhez a szereplők fair kiválasztása.
///
/// Tiszta use case; a véletlen az injektált [Random]-ból jön. Az
/// `ARCHITECTURE.md` 5. fejezetének invariánsait valósítja meg: csak a
/// megkötésnek megfelelő játékosok jöhetnek szóba; a választás a
/// megjelenésszámmal fordítottan súlyozott (súly ∝ 1/(1+szám)), minden
/// jogosult pozitív valószínűséggel; a közvetlen ismétlést mindent-vagy-semmit
/// módon zárja ki (a kizárás feloldódik, ha a megkötés a maradékból nem
/// elégíthető ki); a `sameTeam` a kielégítő csapatok közül sorsol; a
/// `wholeTeam` váltakozik.
///
/// A bemenet szándékosan explicit (nem `GameState`), hogy az algoritmus
/// izoláltan, kimerítően tesztelhető legyen. A megjelenésszámok léptetését és
/// a kizárt nevek karbantartását a hívó (a `drawNext` orchestráció, B3b)
/// végzi, nem ez az osztály.
class SelectSlot {
  /// Létrehoz egy [SelectSlot] use case-t.
  const SelectSlot();

  /// Kiválasztja a [constraint] szereplőit a [frame] keretből.
  ///
  /// A [playerCount] a slotok száma; az [appearanceCounts] a név→megjelenés
  /// térkép a súlyozáshoz; az [excludedNames] az előző kártya szereplői (a
  /// közvetlen ismétlés ellen); a [lastWholeTeam] a legutóbbi `wholeTeam`
  /// csapata a váltakozáshoz, vagy `null`. Előfeltétel (a játszhatósági szűrő
  /// garantálja): a [constraint] a teljes kerettel kielégíthető.
  SlotSelection call({
    required List<Player> frame,
    required SlotConstraint constraint,
    required int playerCount,
    required Map<String, int> appearanceCounts,
    required Set<String> excludedNames,
    required Team? lastWholeTeam,
    required Random random,
  }) {
    return switch (constraint) {
      SlotConstraint.everyone => const NoSlot(),
      SlotConstraint.wholeTeam => TeamSlot(
        _pickWholeTeam(lastWholeTeam, random),
      ),
      SlotConstraint.anyone => PlayerSlots(
        _pickWeighted(
          pool: _withExclusion(frame, excludedNames, playerCount),
          count: playerCount,
          appearanceCounts: appearanceCounts,
          random: random,
        ),
      ),
      SlotConstraint.sameTeam => PlayerSlots(
        _pickSameTeam(
          frame: frame,
          playerCount: playerCount,
          appearanceCounts: appearanceCounts,
          excludedNames: excludedNames,
          random: random,
        ),
      ),
      SlotConstraint.oppositeTeams => PlayerSlots(
        _pickOppositeTeams(
          frame: frame,
          appearanceCounts: appearanceCounts,
          excludedNames: excludedNames,
          random: random,
        ),
      ),
    };
  }

  Team _pickWholeTeam(Team? lastWholeTeam, Random random) {
    // Két csapat: ha volt előző wholeTeam, a másikra esik (a 6. invariáns
    // szerint nincs ismétlés); különben egyenletes sorsolás.
    if (lastWholeTeam != null) {
      return lastWholeTeam.opposite;
    }
    return random.nextBool() ? Team.first : Team.second;
  }

  List<Player> _pickSameTeam({
    required List<Player> frame,
    required int playerCount,
    required Map<String, int> appearanceCounts,
    required Set<String> excludedNames,
    required Random random,
  }) {
    // Jogosult csapatok: legalább playerCount taggal. A játszhatósági szűrő
    // garantálja, hogy van ilyen.
    final qualifying = [
      for (final team in Team.values)
        if (_membersOf(frame, team).length >= playerCount) team,
    ];
    assert(qualifying.isNotEmpty, 'Nincs playerCount-ot kielégítő csapat.');
    final chosenTeam = qualifying[random.nextInt(qualifying.length)];
    return _pickWeighted(
      pool: _withExclusion(
        _membersOf(frame, chosenTeam),
        excludedNames,
        playerCount,
      ),
      count: playerCount,
      appearanceCounts: appearanceCounts,
      random: random,
    );
  }

  List<Player> _pickOppositeTeams({
    required List<Player> frame,
    required Map<String, int> appearanceCounts,
    required Set<String> excludedNames,
    required Random random,
  }) {
    // {p1} csapata véletlen, {p2} az ellentétesből; csapatonként egy fő.
    final firstTeam = random.nextBool() ? Team.first : Team.second;
    final p1 = _pickWeighted(
      pool: _withExclusion(_membersOf(frame, firstTeam), excludedNames, 1),
      count: 1,
      appearanceCounts: appearanceCounts,
      random: random,
    );
    final p2 = _pickWeighted(
      pool: _withExclusion(
        _membersOf(frame, firstTeam.opposite),
        excludedNames,
        1,
      ),
      count: 1,
      appearanceCounts: appearanceCounts,
      random: random,
    );
    return [...p1, ...p2];
  }

  /// A [team] tagjai a [frame]-beli sorrendben (a determinizmushoz stabil).
  List<Player> _membersOf(List<Player> frame, Team team) =>
      frame.where((player) => player.team == team).toList();

  /// A [candidates]-ból kizárja az [excluded] neveket, ha így is marad
  /// legalább [needed] jelölt; különben a kizárás feloldódik (a teljes
  /// jelöltlistát adja vissza). Ez a 3. invariáns mindent-vagy-semmit szabálya.
  List<Player> _withExclusion(
    List<Player> candidates,
    Set<String> excluded,
    int needed,
  ) {
    final eligible = candidates.where((player) => !excluded.contains(player.name)).toList();
    return eligible.length >= needed ? eligible : candidates;
  }

  /// A [pool]-ból [count] különböző játékost választ, a megjelenésszámmal
  /// fordítottan súlyozva (súly = 1/(1+szám)), ismétlés nélkül.
  ///
  /// A súlyok a kártya előtti [appearanceCounts]-ból rögzülnek; a kártyán
  /// belül a számlálót nem növeljük, csak a kiválasztottat vesszük ki a
  /// poolból, és a maradék fix súlyait normáljuk újra. Minden súly pozitív,
  /// így minden jogosult játékos esélye pozitív marad (2. invariáns).
  List<Player> _pickWeighted({
    required List<Player> pool,
    required int count,
    required Map<String, int> appearanceCounts,
    required Random random,
  }) {
    assert(pool.length >= count, 'A pool kevesebb, mint a kért slotszám.');
    final remaining = [...pool];
    final selected = <Player>[];
    for (var picked = 0; picked < count; picked++) {
      final weights = [
        for (final player in remaining) 1 / (1 + (appearanceCounts[player.name] ?? 0)),
      ];
      final total = weights.fold<double>(0, (sum, weight) => sum + weight);
      var threshold = random.nextDouble() * total;
      var index = 0;
      while (index < remaining.length - 1) {
        threshold -= weights[index];
        if (threshold < 0) {
          break;
        }
        index++;
      }
      selected.add(remaining.removeAt(index));
    }
    return selected;
  }
}
