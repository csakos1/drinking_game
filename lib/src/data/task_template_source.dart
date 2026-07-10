import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/domain/result.dart';

/// Nyers tartalom-JSON forrása — a data-réteg forrás-absztrakciója.
///
/// A konkrét forrást (bundled asset, lokális cache, távoli hosting) e mögé az
/// interfész mögé rejtjük. A forrás **nyers JSON stringet** ad; a tartalom
/// érvényessége nem a forrás dolga, azt a domain `ContentValidator`-a dönti
/// el. Így forrás-specifikus fogalom (URL, HTTP, cache-fájl) nem szivárog a
/// domain felé (lásd ADR-0002, `ARCHITECTURE.md` 7. fejezet).
///
/// A v2 backend bevezetése pontosan egy új [TaskTemplateSource]
/// implementáció — a domaint és a presentationt nem érinti.
abstract interface class TaskTemplateSource {
  /// Betölti a nyers tartalom-JSON-t.
  ///
  /// Siker esetén [Success] a nyers JSON stringgel; hiba esetén [Failure] a
  /// megfelelő [TaskSourceError]-ral. A hívó (repository) nem `throw`-ra,
  /// hanem a [Result] hibaágára számít.
  Future<Result<String, TaskSourceError>> load();
}
