import 'package:flutter/painting.dart';

/// A kártyaszöveget megjelenítési szegmensekre bontja: a [labels]
/// (csapatcímkék) előfordulásait [highlightColor]-ral kiemeli, a többit a szülő
/// stílusával (kiemelés nélkül) hagyja.
///
/// A [labels] pontosan a `DrawNext` által a szövegbe írt csapatcímkék (a
/// `teamLabelsProvider` értékei), így a keresett és a beírt szöveg egyezése
/// garantált. A szöveget balról jobbra dolgozza fel: minden pozíción a
/// legkorábban kezdődő címke-előfordulást emeli ki. Üres címkéket figyelmen
/// kívül hagy; ha nincs kiemelendő, egyetlen, stílus nélküli szegmenst ad
/// vissza.
List<InlineSpan> teamHighlightSpans(
  String text,
  Iterable<String> labels,
  Color highlightColor,
) {
  final terms = [
    for (final label in labels)
      if (label.isNotEmpty) label,
  ];
  if (terms.isEmpty) {
    return [TextSpan(text: text)];
  }

  final highlight = TextStyle(color: highlightColor);
  final spans = <InlineSpan>[];
  var index = 0;
  while (index < text.length) {
    var matchAt = -1;
    var matchLen = 0;
    for (final term in terms) {
      final at = text.indexOf(term, index);
      if (at != -1 && (matchAt == -1 || at < matchAt)) {
        matchAt = at;
        matchLen = term.length;
      }
    }

    if (matchAt == -1) {
      spans.add(TextSpan(text: text.substring(index)));
      break;
    }
    if (matchAt > index) {
      spans.add(TextSpan(text: text.substring(index, matchAt)));
    }
    spans.add(
      TextSpan(
        text: text.substring(matchAt, matchAt + matchLen),
        style: highlight,
      ),
    );
    index = matchAt + matchLen;
  }
  return spans;
}
