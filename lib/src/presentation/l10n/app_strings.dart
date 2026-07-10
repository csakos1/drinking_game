import 'package:flutter/widgets.dart';

// A statikus `of` a bevett Flutter lookup-minta (widget-fából olvas, nem
// konstruktor) — a lint itt téves.
// ignore_for_file: prefer_constructors_over_static_methods

/// Az app magyar UI-stringjei (v1 egynyelvű).
///
/// A `lib/l10n/app_hu.arb` a forrás-katalógus (i18n-ready): a getter-nevek az
/// ARB kulcsaival egyeznek, így egy második nyelvhez később `gen_l10n`-re
/// migrálható. A stringeket a widgetek az [of] segítségével érik el
/// ([BuildContext]-en keresztül), a [delegate]-et a `MaterialApp` regisztrálja.
class AppStrings {
  /// Létrehoz egy [AppStrings] példányt (v1: mindig a magyar katalógus).
  const AppStrings();

  /// A jelenlegi [BuildContext]-hez tartozó stringek.
  ///
  /// Ha valamiért nincs regisztrálva (nem várható, mert a gyökér `MaterialApp`
  /// felveszi a [delegate]-et), a magyar katalógusra esik vissza.
  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ?? const AppStrings();
  }

  /// Az [AppStrings] lokalizáció-delegate-je a `MaterialApp` számára.
  static const LocalizationsDelegate<AppStrings> delegate = _AppStringsDelegate();

  /// A támogatott nyelvek (v1: csak magyar).
  static const List<Locale> supportedLocales = [Locale('hu')];

  /// Az app neve.
  String get appTitle => 'Igyál 2';

  /// A setup-képernyő üdvözlő címe.
  String get setupWelcome => 'Üdvözlet az Igyál 2-ben!';

  /// Az első csapat neve/felirata.
  String get firstTeam => 'Első csapat';

  /// A második csapat neve/felirata.
  String get secondTeam => 'Második csapat';

  /// A setup tippszövege az automatikus csapatosztásról.
  String get autoSplitTip =>
      'Ha csak az első csapathoz adsz meg játékosokat, a játék automatikusan '
      'szétosztja őket.';

  /// A „játékos hozzáadása" gomb/mező felirata.
  String get addPlayer => 'Hozzáadás';

  /// A setup fő gombja (IGYUNK): tovább a csapat-áttekintőhöz.
  String get cheers => 'Igyunk';

  /// A játék indítása gomb (KEZDÉS).
  String get start => 'Kezdés';

  /// A csapatok újrasorsolása gomb.
  String get redraw => 'Újrasorsolás';

  /// Visszalépés a setupra.
  String get back => 'Vissza';

  /// A kilépés-megerősítő párbeszéd címe.
  String get quitTitle => 'Kilépsz a játékból?';

  /// A kilépés-megerősítő párbeszéd megerősítő gombja.
  String get quitConfirm => 'Kilépés';

  /// A kilépés-megerősítő párbeszéd elutasító gombja.
  String get quitCancel => 'Mégse';

  /// A beállítások felirata.
  String get settings => 'Beállítások';
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'hu';

  @override
  Future<AppStrings> load(Locale locale) async => const AppStrings();

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
