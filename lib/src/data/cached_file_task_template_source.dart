import 'dart:io';

import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_cache.dart';
import 'package:igyal2/src/domain/result.dart';

/// A lokális cache-fájl forrása (app-adatkönyvtár).
///
/// A könyvtárat a composition root oldja fel (a `path_provider` ott hívódik,
/// nem itt — így a forrás temp-könyvtárral tesztelhető). A tartalmat a
/// `tasks.json` fájlban tárolja; a mentés atomi (temp fájl + `rename`), így
/// félbeszakadt írás sosem hagy sérült cache-t.
///
/// A [TaskTemplateCache]-t valósítja meg: a közös `load()`-on túl `save()`-t
/// és `clear()`-t is ad, így a repository forrás-agnosztikusan (DIP) végezheti
/// az atomi cache-cserét és az érvénytelen cache eldobását.
class CachedFileTaskTemplateSource implements TaskTemplateCache {
  /// Létrehoz egy [CachedFileTaskTemplateSource]-t a megadott
  /// app-adatkönyvtárral.
  CachedFileTaskTemplateSource(this._directory);

  final Directory _directory;

  static const _fileName = 'tasks.json';
  static const _tempFileName = 'tasks.json.tmp';

  File get _file => File('${_directory.path}/$_fileName');
  File get _tempFile => File('${_directory.path}/$_tempFileName');

  @override
  Future<Result<String, TaskSourceError>> load() async {
    // A load() sosem dobhat (interfész-szerződés): minden hibát Failure-ré
    // fordítunk. A hiányzó fájl várható, nem „kemény" hiba → NotFound.
    try {
      final file = _file;
      if (!file.existsSync()) {
        return const Failure(TaskSourceNotFound('Nincs cache-fájl.'));
      }
      final raw = await file.readAsString();
      return Success(raw);
    } on Object catch (e) {
      return Failure(TaskSourceUnreadable('Cache olvasási hiba: $e'));
    }
  }

  @override
  Future<Result<void, TaskSourceError>> save(String rawJson) async {
    // Előbb temp fájlba írunk (flush-sal), majd rename a véglegesre (azonos
    // fs-en atomi), így félbeszakadt írás nem hagy sérült cache-t.
    try {
      if (!_directory.existsSync()) {
        await _directory.create(recursive: true);
      }
      final temp = _tempFile;
      await temp.writeAsString(rawJson, flush: true);
      await temp.rename(_file.path);
      return const Success<void, TaskSourceError>(null);
    } on Object catch (e) {
      return Failure(TaskSourceUnreadable('Cache mentési hiba: $e'));
    }
  }

  @override
  Future<Result<void, TaskSourceError>> clear() async {
    // Az érvénytelennek bizonyult cache eldobása. Ha nincs fájl, az is siker
    // (nincs teendő). No-throw: minden hibát Failure-ré fordítunk.
    try {
      final file = _file;
      if (file.existsSync()) {
        await file.delete();
      }
      return const Success<void, TaskSourceError>(null);
    } on Object catch (e) {
      return Failure(TaskSourceUnreadable('Cache törlési hiba: $e'));
    }
  }
}
