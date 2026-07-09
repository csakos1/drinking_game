import 'package:igyal2/src/domain/slot_constraint.dart';
import 'package:igyal2/src/domain/task_type.dart';
import 'package:meta/meta.dart';

/// Egy validált feladatsablon: a kártyák nyersanyaga.
///
/// Immutable értékobjektum, forrás-agnosztikus: semmit nem feltételez
/// arról, honnan (fájl, repó, DB) származik. A `{p1}`..`{pN}` (illetve
/// `wholeTeam` esetén `{team}`) placeholdereket a [text] tartalmazza; a
/// feloldásukat a sablonmotor végzi, nem ez az osztály.
///
/// A `copyWith` szándékosan hiányzik: a sablonokat betöltés után nem
/// módosítjuk, csak olvassuk. Ha később kell, külön adjuk hozzá.
@immutable
class TaskTemplate {
  /// Létrehoz egy [TaskTemplate] példányt.
  const TaskTemplate({
    required this.id,
    required this.type,
    required this.constraint,
    required this.playerCount,
    required this.text,
  });

  /// Stabil, a tartalmon belül egyedi editori azonosító (pl. `"parbaj-003"`).
  final String id;

  /// A kártya megjelenítési kategóriája.
  final TaskType type;

  /// A szereplőválasztási megkötés.
  final SlotConstraint constraint;

  /// A sablon által igényelt játékos-slotok száma (a [constraint]
  /// szabálya szerint; `wholeTeam`/`everyone` esetén 0).
  final int playerCount;

  /// A sablon szövege placeholderekkel.
  final String text;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TaskTemplate &&
        other.id == id &&
        other.type == type &&
        other.constraint == constraint &&
        other.playerCount == playerCount &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(id, type, constraint, playerCount, text);

  @override
  String toString() =>
      'TaskTemplate(id: $id, type: $type, constraint: $constraint, '
      'playerCount: $playerCount, text: $text)';
}
