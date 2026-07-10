import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/presentation/card_text.dart';

/// A kártyaszöveg-spanek szövegeit adja vissza (ellenőrzéshez).
List<String?> _texts(List<InlineSpan> spans) {
  return [for (final span in spans) (span as TextSpan).text];
}

/// A [color]-ral kiemelt spanek szövegeit adja vissza.
List<String?> _highlighted(List<InlineSpan> spans, Color color) {
  return [
    for (final span in spans)
      if ((span as TextSpan).style?.color == color) span.text,
  ];
}

void main() {
  const green = Color(0xFF2E8B57);
  const labels = ['Első csapat', 'Második csapat'];

  test('címke nélküli szöveg egyetlen, kiemelés nélküli span', () {
    final spans = teamHighlightSpans('Igyál egyet', labels, green);

    expect(spans, hasLength(1));
    expect((spans.single as TextSpan).text, 'Igyál egyet');
    expect((spans.single as TextSpan).style, isNull);
  });

  test('a csapatcímkét kiemeli, a körülötte lévő szöveget érintetlenül hagyja', () {
    final spans = teamHighlightSpans('Az Első csapat iszik', labels, green);

    expect(_texts(spans), ['Az ', 'Első csapat', ' iszik']);
    expect(_highlighted(spans, green), ['Első csapat']);
  });

  test('mindkét címkét külön kiemeli, a helyes sorrendben', () {
    final spans = teamHighlightSpans(
      'Első csapat vs Második csapat',
      labels,
      green,
    );

    expect(_highlighted(spans, green), ['Első csapat', 'Második csapat']);
  });

  test('üres címkéket figyelmen kívül hagy', () {
    final spans = teamHighlightSpans('Első csapat iszik', ['', ''], green);

    expect(spans, hasLength(1));
    expect((spans.single as TextSpan).style, isNull);
  });
}
