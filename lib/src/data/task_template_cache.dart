import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/result.dart';

/// Írható tartalom-cache — a [TaskTemplateSource] olvasási képességét
/// egészíti ki mentéssel és törléssel (data-réteg).
///
/// A repository ezen a szűk absztrakción keresztül végzi a háttér-frissítés
/// atomi cache-cseréjét (`save()`) és az érvénytelennek bizonyult cache
/// eldobását (`clear()`), anélkül hogy a konkrét
/// `CachedFileTaskTemplateSource`-tól függene (DIP). Így a bundled és a remote
/// forrás sima [TaskTemplateSource] marad, az írási út pedig valós
/// fájlrendszer nélkül is tesztelhető (lásd ADR-0002, `ARCHITECTURE.md` 7.
/// fejezet).
///
/// A [TaskTemplateSource]-ból örökli a `load()`-ot, ezért a cache egyúttal
/// olvasható forrás is: a repository olvasási sorrendjében a cache az első.
abstract interface class TaskTemplateCache implements TaskTemplateSource {
  /// Atomikusan lementi a [rawJson] nyers tartalmat a cache-be.
  ///
  /// Az implementáció temp-írás + `rename` cserét végez (azonos
  /// fájlrendszeren atomi), így félbeszakadt írás nem hagy sérült cache-t.
  /// No-throw szerződés: hiba esetén [Failure]-t ad, nem dob.
  Future<Result<void, TaskSourceError>> save(String rawJson);

  /// Eltávolítja a cache-tartalmat (pl. érvénytelennek bizonyult cache).
  ///
  /// Ha nincs mit törölni, az is [Success] (nincs teendő). No-throw
  /// szerződés: hiba esetén [Failure]-t ad, nem dob.
  Future<Result<void, TaskSourceError>> clear();
}
