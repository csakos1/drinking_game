import 'package:flutter/services.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/result.dart';

/// A csomagba ágyazott (bundled) tartalom forrása.
///
/// A `pubspec.yaml`-ban regisztrált assetből (alap:
/// `assets/content/tasks.json`) olvassa a nyers JSON-t. Ez a pipeline
/// garantált „padlója": a séma-teszt biztosítja, hogy mindig érvényes
/// tartalmat adjon, ezért az olvasási hiba itt sosem „nincs meg", hanem
/// build-/integritási probléma → [TaskSourceUnreadable].
class BundledAssetTaskTemplateSource implements TaskTemplateSource {
  /// Létrehoz egy [BundledAssetTaskTemplateSource]-t.
  ///
  /// A [bundle] a tesztelhetőségért injektálható; ha `null`, a
  /// [rootBundle]-t használja. Az [assetPath] a `pubspec.yaml`-ban
  /// regisztrált asset útvonala.
  BundledAssetTaskTemplateSource({
    AssetBundle? bundle,
    String assetPath = 'assets/content/tasks.json',
  }) : _bundle = bundle ?? rootBundle,
       _assetPath = assetPath;

  final AssetBundle _bundle;
  final String _assetPath;

  @override
  Future<Result<String, TaskSourceError>> load() async {
    // A load() sosem dobhat (interfész-szerződés): minden hibát Failure-ré
    // fordítunk. A hiányzó asset `FlutterError`-t dob (ami Error, nem
    // Exception), ezért szélesen, `on Object`-tal kapjuk el.
    try {
      final raw = await _bundle.loadString(_assetPath);
      return Success(raw);
    } on Object catch (e) {
      return Failure(
        TaskSourceUnreadable('Bundled asset olvasási hiba ($_assetPath): $e'),
      );
    }
  }
}
