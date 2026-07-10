import 'package:flutter/material.dart';

/// Az Igyál 2 színpalettája: fekete alap + a jóváhagyott zöld árnyalatok (a régi
/// piros séma szerepenkénti megfelelői).
abstract final class AppColors {
  /// Fő háttér: fekete.
  static const background = Color(0xFF000000);

  /// Törzsszöveg és semleges felületek szövege: fehér.
  static const onBackground = Color(0xFFFFFFFF);

  /// CTA-zöld: a KEZDÉS / IGYUNK gombok kitöltése (volt: tiszta piros).
  static const cta = Color(0xFF22A65E);

  /// Márka/fejléc-zöld: a csapatfejlécek (volt: erős piros).
  static const brand = Color(0xFF1B6741);

  /// Accent-zöld: a típuscímek (pl. Vírus) és a kártyaszövegben megjelenő
  /// csapatnevek (volt: téglaszín piros).
  static const accent = Color(0xFF2E8B57);

  /// Mély zöld: a setup csapat-kártya háttere (volt: mély bordó).
  static const deep = Color(0xFF123D28);

  /// Sötét zöld: a tartós vírus-csík (v1-ben halasztva; a token megvan).
  static const strip = Color(0xFF0E3320);

  /// Semleges szürke: az inaktív / auto második csapat kártyája.
  static const neutral = Color(0xFF6B6B6B);
}
