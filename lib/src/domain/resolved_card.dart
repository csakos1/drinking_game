import 'package:igyal2/src/domain/task_type.dart';
import 'package:meta/meta.dart';

/// A feloldott, megjeleníthető kártya: a sablonmotor kimenete.
///
/// Immutable. A [templateId] a forrássablon azonosítója (debug/telemetria); a
/// [type] a megjelenítési kategória (badge/szín); a [text] a placeholderektől
/// mentes, konkrét nevekre és csapatcímkékre feloldott szöveg.
@immutable
class ResolvedCard {
  /// Létrehoz egy [ResolvedCard]-ot.
  const ResolvedCard({
    required this.templateId,
    required this.type,
    required this.text,
  });

  /// A forrássablon azonosítója.
  final String templateId;

  /// A kártya megjelenítési kategóriája.
  final TaskType type;

  /// A feloldott (placeholder-mentes) szöveg.
  final String text;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ResolvedCard &&
        other.templateId == templateId &&
        other.type == type &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(templateId, type, text);

  @override
  String toString() => 'ResolvedCard(templateId: $templateId, type: $type, text: $text)';
}
