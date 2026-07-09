import 'package:meta/meta.dart';

/// A tartalom-validáció során felmerülő hibák sealed hierarchiája.
///
/// Minden hibaosztály egy konkrét séma-szabály megsértését jelöli. A
/// sablonhoz köthető hibák hordozzák az érintett [templateId]-t (a nyers,
/// még nem validált sztringet, ami akár hiányzó/érvénytelen is lehet). A
/// nem sablonspecifikus, dokumentum-szintű hibáknál a [templateId] `null`.
///
/// A validátor a hibákat listaként gyűjti (nem az elsőnél áll meg), és
/// egyetlen hiba is a teljes tartalmat érvényteleníti (mindent-vagy-semmit).
@immutable
sealed class ContentValidationError {
  const ContentValidationError();

  /// Az érintett sablon azonosítója, vagy `null` dokumentum-szintű hibánál.
  String? get templateId;
}

/// A nyers szöveg nem érvényes JSON, vagy nem a várt gyökérszerkezet
/// (objektum `version` és `templates` mezővel).
@immutable
final class MalformedJson extends ContentValidationError {
  /// Létrehoz egy [MalformedJson] hibát a [detail] emberi olvasható
  /// magyarázattal.
  const MalformedJson(this.detail);

  /// Rövid leírás arról, mi tört el a parszolás/szerkezet szintjén.
  final String detail;

  @override
  String? get templateId => null;

  @override
  bool operator ==(Object other) => other is MalformedJson && other.detail == detail;

  @override
  int get hashCode => detail.hashCode;

  @override
  String toString() => 'MalformedJson($detail)';
}

/// A `version` mező nem a támogatott sémaverzió.
@immutable
final class UnsupportedVersion extends ContentValidationError {
  /// Létrehoz egy [UnsupportedVersion] hibát: a [found] a talált, az
  /// [supported] az elvárt verzió.
  const UnsupportedVersion({required this.found, required this.supported});

  /// A tartalomban talált verzió.
  final int found;

  /// Az app által támogatott verzió.
  final int supported;

  @override
  String? get templateId => null;

  @override
  bool operator ==(Object other) =>
      other is UnsupportedVersion && other.found == found && other.supported == supported;

  @override
  int get hashCode => Object.hash(found, supported);

  @override
  String toString() => 'UnsupportedVersion(found: $found, supported: $supported)';
}

/// A `templates` lista üres.
@immutable
final class EmptyTemplateList extends ContentValidationError {
  /// Létrehoz egy [EmptyTemplateList] hibát.
  const EmptyTemplateList();

  @override
  String? get templateId => null;

  @override
  bool operator ==(Object other) => other is EmptyTemplateList;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'EmptyTemplateList()';
}

/// Két vagy több sablon ugyanazt az `id`-t használja.
@immutable
final class DuplicateId extends ContentValidationError {
  /// Létrehoz egy [DuplicateId] hibát a duplikált [templateId]-vel.
  const DuplicateId(this.templateId);

  @override
  final String templateId;

  @override
  bool operator ==(Object other) => other is DuplicateId && other.templateId == templateId;

  @override
  int get hashCode => templateId.hashCode;

  @override
  String toString() => 'DuplicateId($templateId)';
}

/// A sablon `type` mezője ismeretlen típus-slug.
@immutable
final class UnknownType extends ContentValidationError {
  /// Létrehoz egy [UnknownType] hibát: a [templateId] a sablon, a [slug]
  /// az ismeretlen érték.
  const UnknownType({required this.templateId, required this.slug});

  @override
  final String templateId;

  /// A talált, ismeretlen típus-slug.
  final String slug;

  @override
  bool operator ==(Object other) =>
      other is UnknownType && other.templateId == templateId && other.slug == slug;

  @override
  int get hashCode => Object.hash(templateId, slug);

  @override
  String toString() => 'UnknownType(templateId: $templateId, slug: $slug)';
}

/// A sablon `constraint` mezője ismeretlen megkötés-slug.
@immutable
final class UnknownConstraint extends ContentValidationError {
  /// Létrehoz egy [UnknownConstraint] hibát: a [templateId] a sablon, a
  /// [slug] az ismeretlen érték.
  const UnknownConstraint({required this.templateId, required this.slug});

  @override
  final String templateId;

  /// A talált, ismeretlen megkötés-slug.
  final String slug;

  @override
  bool operator ==(Object other) =>
      other is UnknownConstraint && other.templateId == templateId && other.slug == slug;

  @override
  int get hashCode => Object.hash(templateId, slug);

  @override
  String toString() => 'UnknownConstraint(templateId: $templateId, slug: $slug)';
}

/// A `playerCount` nem felel meg a megkötés szabályának.
@immutable
final class InvalidPlayerCount extends ContentValidationError {
  /// Létrehoz egy [InvalidPlayerCount] hibát: a [templateId] a sablon, a
  /// [constraintSlug] a megkötés, a [playerCount] a hibás érték.
  const InvalidPlayerCount({
    required this.templateId,
    required this.constraintSlug,
    required this.playerCount,
  });

  @override
  final String templateId;

  /// A sablon megkötésének slugja (kontextus a hibaüzenethez).
  final String constraintSlug;

  /// A séma szabályát megsértő játékosszám.
  final int playerCount;

  @override
  bool operator ==(Object other) =>
      other is InvalidPlayerCount &&
      other.templateId == templateId &&
      other.constraintSlug == constraintSlug &&
      other.playerCount == playerCount;

  @override
  int get hashCode => Object.hash(templateId, constraintSlug, playerCount);

  @override
  String toString() =>
      'InvalidPlayerCount(templateId: $templateId, '
      'constraintSlug: $constraintSlug, playerCount: $playerCount)';
}

/// A `text` placeholderei nem egyeznek a deklarált slotokkal.
///
/// Ide tartozik a hiányzó (`{p2}` deklarálva, de nincs a szövegben),
/// a többlet (`{p3}` a szövegben, de a playerCount csak 2), az ismeretlen
/// (`{player1}`, `{P1}`) és a rossz helyen álló `{team}` token is. A
/// [detail] emberi olvasható magyarázatot ad az editornak.
@immutable
final class PlaceholderMismatch extends ContentValidationError {
  /// Létrehoz egy [PlaceholderMismatch] hibát: a [templateId] a sablon, a
  /// [detail] a konkrét eltérés leírása.
  const PlaceholderMismatch({required this.templateId, required this.detail});

  @override
  final String templateId;

  /// A konkrét placeholder-eltérés emberi olvasható leírása.
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is PlaceholderMismatch && other.templateId == templateId && other.detail == detail;

  @override
  int get hashCode => Object.hash(templateId, detail);

  @override
  String toString() => 'PlaceholderMismatch(templateId: $templateId, detail: $detail)';
}

/// A sablon `text` mezője üres (vagy csak whitespace).
@immutable
final class BlankText extends ContentValidationError {
  /// Létrehoz egy [BlankText] hibát a [templateId]-vel.
  const BlankText(this.templateId);

  @override
  final String templateId;

  @override
  bool operator ==(Object other) => other is BlankText && other.templateId == templateId;

  @override
  int get hashCode => templateId.hashCode;

  @override
  String toString() => 'BlankText($templateId)';
}

/// A sablon egy kötelező mezője hiányzik vagy rossz típusú.
///
/// Strukturális, sablonszintű hiba (pl. hiányzó `text`, nem-string `id`,
/// nem-egész `playerCount`). A [templateId] a sablon azonosítója, ha
/// kiolvasható volt, különben `null`; a [detail] a hiányzó/hibás mezőt írja.
@immutable
final class MalformedTemplate extends ContentValidationError {
  /// Létrehoz egy [MalformedTemplate] hibát: a [templateId] a sablon (ha
  /// ismert), a [detail] a strukturális probléma leírása.
  const MalformedTemplate({required this.templateId, required this.detail});

  @override
  final String? templateId;

  /// A strukturális probléma emberi olvasható leírása.
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is MalformedTemplate && other.templateId == templateId && other.detail == detail;

  @override
  int get hashCode => Object.hash(templateId, detail);

  @override
  String toString() => 'MalformedTemplate(templateId: $templateId, detail: $detail)';
}
