import 'dart:convert';

import 'package:igyal2/src/domain/content_validation_error.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/slot_constraint.dart';
import 'package:igyal2/src/domain/task_content.dart';
import 'package:igyal2/src/domain/task_template.dart';
import 'package:igyal2/src/domain/task_type.dart';

/// A nyers tartalom-JSON-t validált [TaskContent]-té alakítja.
///
/// Tiszta domain-use case: `dart:convert`-en kívül semmilyen külső vagy
/// platform-függőség. A séma minden szabályát kikényszeríti (lásd
/// `ARCHITECTURE.md` 4. fejezet), a hibákat listaként gyűjti (nem az első
/// hibánál áll meg), és mindent-vagy-semmit dönt: egyetlen érvénytelen
/// sablon → az egész tartalom [Failure].
///
/// A dokumentum-szintű hibák (rossz JSON, nem támogatott verzió, üres
/// lista) rövidre zárnak: ha ezek valamelyike fennáll, a sablononkénti
/// validáció el sem indul, mert nincs értelmes keret hozzá.
class ContentValidator {
  /// Létrehoz egy [ContentValidator]-t; a [supportedVersion] az egyetlen
  /// elfogadott sémaverzió (alapértelmezés: 1).
  const ContentValidator({this.supportedVersion = 1});

  /// A támogatott sémaverzió; minden más [UnsupportedVersion] hibát ad.
  final int supportedVersion;

  /// Bármely `{...}` token felismerése (a többlet/ismeretlen token
  /// kiszűréséhez). Szándékosan tág: az azonosított tokenekből vonjuk ki a
  /// megengedetteket.
  static final RegExp _anyToken = RegExp(r'\{[^}]*\}');

  /// Validálja a [rawJson] nyers tartalmat.
  ///
  /// Siker esetén [Success] a validált [TaskContent]-tel; hiba esetén
  /// [Failure] a hibák nem üres listájával.
  Result<TaskContent, List<ContentValidationError>> validate(String rawJson) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException catch (e) {
      return Failure([MalformedJson('Érvénytelen JSON: ${e.message}')]);
    }

    if (decoded is! Map<String, dynamic>) {
      return const Failure([MalformedJson('A gyökérelem nem objektum.')]);
    }

    final version = decoded['version'];
    if (version is! int) {
      return const Failure([
        MalformedJson('Hiányzó vagy nem egész "version" mező.'),
      ]);
    }
    if (version != supportedVersion) {
      return Failure([
        UnsupportedVersion(found: version, supported: supportedVersion),
      ]);
    }

    final rawTemplates = decoded['templates'];
    if (rawTemplates is! List) {
      return const Failure([
        MalformedJson('Hiányzó vagy nem lista "templates" mező.'),
      ]);
    }
    if (rawTemplates.isEmpty) {
      return const Failure([EmptyTemplateList()]);
    }

    final errors = <ContentValidationError>[];
    final templates = <TaskTemplate>[];
    final seenIds = <String>{};

    for (final raw in rawTemplates) {
      final result = _validateTemplate(raw, seenIds);
      switch (result) {
        case Success(:final value):
          templates.add(value);
        case Failure(:final error):
          errors.addAll(error);
      }
    }

    if (errors.isNotEmpty) {
      return Failure(errors);
    }
    return Success(TaskContent(version: version, templates: templates));
  }

  /// Egyetlen nyers sablon validálása; a [seenIds] halmazba felveszi az
  /// érvényes id-ket a duplikátum-ellenőrzéshez.
  Result<TaskTemplate, List<ContentValidationError>> _validateTemplate(
    Object? raw,
    Set<String> seenIds,
  ) {
    if (raw is! Map<String, dynamic>) {
      return const Failure([
        MalformedTemplate(
          templateId: null,
          detail: 'A sablon nem objektum.',
        ),
      ]);
    }

    // Az id-t előre kiolvassuk, hogy a többi hiba hivatkozhasson rá.
    final rawId = raw['id'];
    final templateId = rawId is String ? rawId : null;

    final errors = <ContentValidationError>[];

    if (templateId == null || templateId.isEmpty) {
      errors.add(
        MalformedTemplate(
          templateId: templateId,
          detail: 'Hiányzó vagy nem szöveges "id" mező.',
        ),
      );
    } else if (!seenIds.add(templateId)) {
      errors.add(DuplicateId(templateId));
    }

    final type = _readType(raw, templateId, errors);
    final constraint = _readConstraint(raw, templateId, errors);
    final playerCount = _readPlayerCount(raw, templateId, errors);
    final text = _readText(raw, templateId, errors);

    // A placeholder-ellenőrzéshez minden összetevő kell; ha bármi hiányzik,
    // a részleges ellenőrzés félrevezető lenne, ezért kihagyjuk.
    if (constraint != null && playerCount != null && text != null) {
      _validatePlaceholders(
        templateId: templateId ?? '(ismeretlen)',
        constraint: constraint,
        playerCount: playerCount,
        text: text,
        errors: errors,
      );
    }

    if (errors.isNotEmpty) {
      return Failure(errors);
    }

    // Ide csak akkor jutunk, ha minden mező érvényes. A lokális
    // ellenőrzés a fordítónak bizonyítja a non-null-t (a ! elkerülésére),
    // és védőhálóként throw helyett hibát ad, ha valaha logikai rés
    // maradna a validációban.
    if (templateId == null ||
        type == null ||
        constraint == null ||
        playerCount == null ||
        text == null) {
      return Failure([
        MalformedTemplate(
          templateId: templateId,
          detail: 'Belső ellentmondás: hiba nélkül is hiányzó mező.',
        ),
      ]);
    }

    return Success(
      TaskTemplate(
        id: templateId,
        type: type,
        constraint: constraint,
        playerCount: playerCount,
        text: text,
      ),
    );
  }

  TaskType? _readType(
    Map<String, dynamic> raw,
    String? templateId,
    List<ContentValidationError> errors,
  ) {
    final rawType = raw['type'];
    if (rawType is! String) {
      errors.add(
        MalformedTemplate(
          templateId: templateId,
          detail: 'Hiányzó vagy nem szöveges "type" mező.',
        ),
      );
      return null;
    }
    final type = TaskType.fromSlug(rawType);
    if (type == null) {
      errors.add(
        UnknownType(templateId: templateId ?? '(ismeretlen)', slug: rawType),
      );
    }
    return type;
  }

  SlotConstraint? _readConstraint(
    Map<String, dynamic> raw,
    String? templateId,
    List<ContentValidationError> errors,
  ) {
    final rawConstraint = raw['constraint'];
    if (rawConstraint is! String) {
      errors.add(
        MalformedTemplate(
          templateId: templateId,
          detail: 'Hiányzó vagy nem szöveges "constraint" mező.',
        ),
      );
      return null;
    }
    final constraint = SlotConstraint.fromSlug(rawConstraint);
    if (constraint == null) {
      errors.add(
        UnknownConstraint(
          templateId: templateId ?? '(ismeretlen)',
          slug: rawConstraint,
        ),
      );
    }
    return constraint;
  }

  int? _readPlayerCount(
    Map<String, dynamic> raw,
    String? templateId,
    List<ContentValidationError> errors,
  ) {
    final rawCount = raw['playerCount'];
    if (rawCount is! int) {
      errors.add(
        MalformedTemplate(
          templateId: templateId,
          detail: 'Hiányzó vagy nem egész "playerCount" mező.',
        ),
      );
      return null;
    }
    return rawCount;
  }

  String? _readText(
    Map<String, dynamic> raw,
    String? templateId,
    List<ContentValidationError> errors,
  ) {
    final rawText = raw['text'];
    if (rawText is! String) {
      errors.add(
        MalformedTemplate(
          templateId: templateId,
          detail: 'Hiányzó vagy nem szöveges "text" mező.',
        ),
      );
      return null;
    }
    if (rawText.trim().isEmpty) {
      errors.add(BlankText(templateId ?? '(ismeretlen)'));
      return null;
    }
    return rawText;
  }

  /// A megkötés–playerCount–placeholder összhang ellenőrzése.
  ///
  /// Előbb a séma szintaktikai playerCount-szabálya (a megkötéshez
  /// megengedett-e a szám), majd a szövegbeli placeholderek egyeztetése a
  /// deklarált slotokkal. A `wholeTeam` a `{team}` tokent várja, minden
  /// más játékos-megkötés a `{p1}`..`{pN}` teljes, hézagmentes halmazát; az
  /// `everyone` egyetlen placeholdert sem enged.
  void _validatePlaceholders({
    required String templateId,
    required SlotConstraint constraint,
    required int playerCount,
    required String text,
    required List<ContentValidationError> errors,
  }) {
    if (!constraint.isValidPlayerCount(playerCount)) {
      errors.add(
        InvalidPlayerCount(
          templateId: templateId,
          constraintSlug: constraint.slug,
          playerCount: playerCount,
        ),
      );
      // Rossz playerCount mellett a placeholder-elvárás sem értelmezhető
      // tisztán; a séma-hibát jelentettük, a token-ellenőrzést kihagyjuk.
      return;
    }

    final allTokens = _anyToken.allMatches(text).map((m) => m.group(0)).whereType<String>().toSet();

    switch (constraint) {
      case SlotConstraint.wholeTeam:
        _requireExactTokens(
          templateId: templateId,
          actual: allTokens,
          expected: {'{team}'},
          errors: errors,
        );
      case SlotConstraint.everyone:
        _requireExactTokens(
          templateId: templateId,
          actual: allTokens,
          expected: const {},
          errors: errors,
        );
      case SlotConstraint.anyone:
      case SlotConstraint.sameTeam:
      case SlotConstraint.oppositeTeams:
        // A várt tokenhalmaz pontosan {p1}..{pN}. Az exact-ellenőrzés
        // egyszerre fedi a hiányzó, a többlet és az ismeretlen (pl. {P1},
        // {p01}, {player1}) tokent is, ezért külön index-ellenőrzés nem kell.
        final expected = {for (var i = 1; i <= playerCount; i++) '{p$i}'};
        _requireExactTokens(
          templateId: templateId,
          actual: allTokens,
          expected: expected,
          errors: errors,
        );
    }
  }

  /// Elhasal, ha az [actual] tokenhalmaz nem pontosan az [expected].
  void _requireExactTokens({
    required String templateId,
    required Set<String> actual,
    required Set<String> expected,
    required List<ContentValidationError> errors,
  }) {
    if (_setEquals(actual, expected)) {
      return;
    }
    final unexpected = actual.difference(expected);
    final missing = expected.difference(actual);
    final parts = <String>[];
    if (unexpected.isNotEmpty) {
      parts.add('nem várt: ${_sortedList(unexpected)}');
    }
    if (missing.isNotEmpty) {
      parts.add('hiányzó: ${_sortedList(missing)}');
    }
    errors.add(
      PlaceholderMismatch(
        templateId: templateId,
        detail: 'Placeholder-eltérés (${parts.join(', ')}).',
      ),
    );
  }

  bool _setEquals<E>(Set<E> a, Set<E> b) => a.length == b.length && a.containsAll(b);

  String _sortedList<E extends Comparable<E>>(Iterable<E> items) {
    final sorted = items.toList()..sort();
    return sorted.toString();
  }
}
