import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:igyal2/src/data/bundled_asset_task_template_source.dart';
import 'package:igyal2/src/data/cached_file_task_template_source.dart';
import 'package:igyal2/src/data/remote_task_template_source.dart';
import 'package:igyal2/src/data/task_content_repository.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_cache.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/task_content.dart';

/// Az app cache-könyvtára, amelyben a lokális tartalom-cache fájl él.
///
/// Szándékosan nincs alapértéke: a composition rootnak (`main`) kötelező
/// felülírnia a `path_provider` által feloldott könyvtárral. Így a `path_provider`
/// sosem hívódik a data- vagy domain-rétegben, a cache-forrás pedig valós
/// fájlrendszer nélkül, temp-könyvtárral tesztelhető marad.
final cacheDirectoryProvider = Provider<Directory>((ref) {
  throw UnimplementedError(
    'A cacheDirectoryProvider-t a composition rootnak felül kell írnia a '
    'path_provider által feloldott könyvtárral.',
  );
});

/// A v1 távoli tartalom-URL-je, vagy `null`, ha még nincs beállítva.
///
/// Alapból `null`: amíg a tartalom-hosting nincs eldöntve (a repó privát, ezért
/// a raw.githubusercontent.com / GitHub Pages nem járható auth nélkül), a
/// háttér-frissítés meg sem indul, és az app kizárólag a bundled padlóból és a
/// lokális cache-ből fut. A host eldöntésekor ezt a providert kell felülírni a
/// valós URI-val — a data-varrat (`TaskTemplateSource`) érintetlen marad.
final remoteContentUriProvider = Provider<Uri?>((ref) => null);

/// A háttér-frissítés dedikált HTTP-kliense.
///
/// Nem az app teljes élettartamára él: a composition root egyetlen frissítés
/// után lezárja (lásd [triggerContentRefresh]). Csak akkor olvassuk ki, ha van
/// beállított távoli forrás ([remoteContentUriProvider] nem `null`).
final refreshHttpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// A csomagba ágyazott (bundled) tartalom forrása — a pipeline padlója.
final bundledTaskTemplateSourceProvider = Provider<TaskTemplateSource>((ref) {
  return BundledAssetTaskTemplateSource();
});

/// A lokális, írható tartalom-cache (egyben olvasható forrás).
///
/// A cache-könyvtárat a [cacheDirectoryProvider]-ből kapja, amelyet a
/// composition root old fel.
final taskTemplateCacheProvider = Provider<TaskTemplateCache>((ref) {
  final directory = ref.watch(cacheDirectoryProvider);
  return CachedFileTaskTemplateSource(directory);
});

/// A távoli frissítés forrása.
///
/// Ha nincs beállított URL ([remoteContentUriProvider] `null`), egy letiltott
/// forrást ad, amely mindig hálózati hibát jelez. Így a repository szerződése
/// (nem-null `remote`) teljesül, a `refreshInBackground()` pedig érdemi hálózati
/// hívás nélkül, némán no-op marad.
final remoteTaskTemplateSourceProvider = Provider<TaskTemplateSource>((ref) {
  final uri = ref.watch(remoteContentUriProvider);
  if (uri == null) {
    return const _DisabledRemoteSource();
  }
  final client = ref.watch(refreshHttpClientProvider);
  return RemoteTaskTemplateSource(uri, client: client);
});

/// A tartalom-pipeline repository-ja: forrásokból validált [TaskContent].
///
/// A három forrást (bundled padló, lokális cache, távoli frissítés) fogja össze;
/// az olvasási sorrendet és a fire-and-forget frissítést maga a repository
/// kezeli.
final taskContentRepositoryProvider = Provider<TaskContentRepository>((ref) {
  return TaskContentRepository(
    bundled: ref.watch(bundledTaskTemplateSourceProvider),
    cache: ref.watch(taskTemplateCacheProvider),
    remote: ref.watch(remoteTaskTemplateSourceProvider),
  );
});

/// A validált tartalom (offline-first betöltés): érvényes cache → bundled padló.
///
/// A setup-folyam ezt figyeli; a betöltés gyors és lokális, sosem függ a
/// hálózattól. A bundled padló garantálja, hogy mindig érvényes tartalom jön.
final taskContentProvider = FutureProvider<TaskContent>((ref) async {
  final repository = ref.watch(taskContentRepositoryProvider);
  return repository.loadContent();
});

/// Egyszeri, nem-blokkoló háttér-frissítést indít a megadott [container]-ből.
///
/// Ha nincs beállított távoli forrás ([remoteContentUriProvider] `null`), nem
/// tesz semmit: nem jön létre kliens, nincs hálózati hívás. Egyébként lefuttatja
/// a repository `refreshInBackground()`-ját (amely maga is némán elnyel minden
/// hibát), majd a frissítés végén lezárja a dedikált HTTP-klienst.
///
/// A visszaadott future a tesztelhetőségért awaitolható; a composition root
/// `unawaited`-tel, tűzd-és-felejtsd módon indítja.
Future<void> triggerContentRefresh(ProviderContainer container) {
  final uri = container.read(remoteContentUriProvider);
  if (uri == null) {
    return Future<void>.value();
  }
  final repository = container.read(taskContentRepositoryProvider);
  final client = container.read(refreshHttpClientProvider);
  return repository.refreshInBackground().whenComplete(client.close);
}

/// Letiltott távoli forrás: nincs beállított URL, ezért mindig hálózati hibát ad.
///
/// A repository nem-null `remote` szerződését elégíti ki úgy, hogy közben
/// semmilyen hálózati műveletet nem végez.
class _DisabledRemoteSource implements TaskTemplateSource {
  const _DisabledRemoteSource();

  @override
  Future<Result<String, TaskSourceError>> load() async {
    return const Failure(
      TaskSourceNetworkFailure('Nincs beállítva távoli tartalom-forrás.'),
    );
  }
}
