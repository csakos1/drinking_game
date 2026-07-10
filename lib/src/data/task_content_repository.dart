import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_cache.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/content_validator.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/task_content.dart';

/// A tartalom-pipeline belépőpontja: forrásokból validált [TaskContent]-et ad.
///
/// Olvasási sorrend: érvényes lokális cache → bundled asset (padló). Mindkettő
/// átmegy a domain `ContentValidator`-án; az érvénytelen cache-t eldobjuk. A
/// bundled a build-garancia „padlója" (a séma-teszt mindig érvényesnek tartja),
/// ezért a [loadContent] nem-nullable — sosem bukhat teljesen. Ha a bundled
/// mégis olvashatatlan vagy érvénytelen, az build-/programozói hiba
/// (`StateError`), nem várható futásidejű állapot.
///
/// A háttér-frissítést a [refreshInBackground] végzi, fire-and-forget módon:
/// remote fetch → validálás → atomi cache-csere; minden hibát némán elnyel
/// (naplózva). Offline-first: az olvasás sosem függ a hálózattól, a frissítés
/// sosem blokkolja a UI-t (lásd ADR-0002, `ARCHITECTURE.md` 7. fejezet).
class TaskContentRepository {
  /// Létrehoz egy [TaskContentRepository]-t a három forrással.
  ///
  /// A [bundled] a beépített padló, a [cache] az írható lokális cache (egyben
  /// olvasható forrás), a [remote] a távoli frissítés forrása. A [validator] a
  /// domain tartalom-validátora (alap: friss `ContentValidator`); a [logger] a
  /// némán elnyelt hibák naplózására szolgál (alap: no-op).
  TaskContentRepository({
    required TaskTemplateSource bundled,
    required TaskTemplateCache cache,
    required TaskTemplateSource remote,
    ContentValidator? validator,
    void Function(String message)? logger,
  }) : _bundled = bundled,
       _cache = cache,
       _remote = remote,
       _validator = validator ?? const ContentValidator(),
       _log = logger ?? _noopLog;

  final TaskTemplateSource _bundled;
  final TaskTemplateCache _cache;
  final TaskTemplateSource _remote;
  final ContentValidator _validator;
  final void Function(String message) _log;

  /// Betölti a validált tartalmat: érvényes cache → bundled padló.
  ///
  /// Nem-nullable: a bundled padló mindig érvényes (séma-teszt garancia). Ha a
  /// bundled mégis hibás, `StateError`-t dob (build-/programozói hiba).
  Future<TaskContent> loadContent() async {
    final fromCache = await _loadFromCache();
    if (fromCache != null) {
      return fromCache;
    }
    return _loadFromBundled();
  }

  /// Fire-and-forget háttér-frissítés: remote → validálás → atomi cache-csere.
  ///
  /// Sosem dob és sosem blokkolja a UI-t: minden forrás-, validációs- és
  /// mentési hibát némán elnyel (naplózva). Érvénytelen remote tartalmat nem
  /// ír a cache-be, így a padló nem romolhat el.
  Future<void> refreshInBackground() async {
    try {
      final loaded = await _remote.load();
      final String raw;
      switch (loaded) {
        case Success(:final value):
          raw = value;
        case Failure(:final error):
          _log('Remote frissítés sikertelen: ${error.message}');
          return;
      }

      final validated = _validator.validate(raw);
      switch (validated) {
        case Success():
          // A nyers JSON-t mentjük, hogy a következő indulás a cache-t
          // ugyanúgy validálja, mint a bundledet.
          final saved = await _cache.save(raw);
          if (saved case Failure(error: final saveError)) {
            _log('Cache mentés sikertelen: ${saveError.message}');
          }
        case Failure(:final error):
          _log('Érvénytelen remote tartalom eldobva (${error.length} hiba).');
      }
    } on Object catch (e) {
      // Védőháló: a háttér-frissítés soha nem buktathatja meg az appot.
      _log('Váratlan hiba a háttér-frissítés során: $e');
    }
  }

  /// A cache-ből próbál érvényes tartalmat olvasni; siker esetén [TaskContent],
  /// egyébként `null` (a hívó a bundled padlóra lép).
  Future<TaskContent?> _loadFromCache() async {
    final loaded = await _cache.load();
    final String raw;
    switch (loaded) {
      case Success(:final value):
        raw = value;
      case Failure(:final error):
        // A NotFound várható (első indítás, üres cache) → néma továbblépés.
        // Minden más olvasási hiba naplózandó, de szintén nem végzetes.
        if (error is! TaskSourceNotFound) {
          _log('Cache olvasási hiba: ${error.message}');
        }
        return null;
    }

    final validated = _validator.validate(raw);
    switch (validated) {
      case Success(:final value):
        return value;
      case Failure(:final error):
        // Érvénytelen cache → eldobjuk, hogy a sérült tartalom ne ragadjon ott
        // (offline gépen egy sikeres remote-fetchig maradna).
        _log('Érvénytelen cache eldobva (${error.length} hiba).');
        final cleared = await _cache.clear();
        if (cleared case Failure(error: final clearError)) {
          _log('Cache törlés sikertelen: ${clearError.message}');
        }
        return null;
    }
  }

  /// A bundled padlóból olvas; ez sosem adhat `null`-t (build-garancia).
  ///
  /// Ha a bundled olvashatatlan vagy érvénytelen, `StateError`-t dob: a
  /// séma-tesztnek ezt ki kellett volna szűrnie, tehát build-/programozói hiba.
  Future<TaskContent> _loadFromBundled() async {
    final loaded = await _bundled.load();
    final String raw;
    switch (loaded) {
      case Success(:final value):
        raw = value;
      case Failure(:final error):
        throw StateError('A bundled tartalom nem olvasható: ${error.message}');
    }

    final validated = _validator.validate(raw);
    switch (validated) {
      case Success(:final value):
        return value;
      case Failure(:final error):
        throw StateError(
          'A bundled tartalom érvénytelen (${error.length} hiba) — '
          'a séma-tesztnek ezt ki kellett volna szűrnie.',
        );
    }
  }
}

/// Alapértelmezett naplózó: eldobja az üzenetet (a hívó adhat sajátot).
void _noopLog(String _) {}
