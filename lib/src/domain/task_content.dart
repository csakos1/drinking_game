import 'package:igyal2/src/domain/task_template.dart';
import 'package:meta/meta.dart';

/// A validált feladattartalom egésze: sémaverzió + a sablonok listája.
///
/// Csak a `ContentValidator` állítja elő, sikeres validáció eredményeként;
/// a domain és az application ezt (illetve a [templates] listát) látja, a
/// nyers JSON-t vagy a forrást soha. Immutable és forrás-agnosztikus.
@immutable
class TaskContent {
  /// Létrehoz egy [TaskContent] példányt a [version] sémaverzióval és a
  /// [templates] sablonlistával.
  const TaskContent({required this.version, required this.templates});

  /// A tartalom sémaverziója (a validátor csak a támogatottat engedi át).
  final int version;

  /// A validált sablonok, a JSON-beli sorrendben.
  final List<TaskTemplate> templates;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TaskContent || other.version != version) {
      return false;
    }
    final otherTemplates = other.templates;
    if (otherTemplates.length != templates.length) {
      return false;
    }
    for (var i = 0; i < templates.length; i++) {
      if (otherTemplates[i] != templates[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(version, Object.hashAll(templates));

  @override
  String toString() => 'TaskContent(version: $version, templates: ${templates.length} db)';
}
