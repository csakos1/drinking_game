import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/main.dart';

void main() {
  // Smoke teszt: csak azt ellenőrzi, hogy az app gyökérwidgetje
  // hiba nélkül felépül és renderel. A tényleges viselkedést a domain-
  // és widget-tesztek fedik le, ahogy a rétegek felépülnek; ez a teszt
  // addig is életben tartja a test/ könyvtárat és a pre-flight tesztlépését.
  testWidgets('MainApp builds and renders without error', (tester) async {
    // Given-When: az app gyökere beépül a widgetfába.
    await tester.pumpWidget(const MainApp());

    // Then: a MaterialApp jelen van, a fa hiba nélkül felépült.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
