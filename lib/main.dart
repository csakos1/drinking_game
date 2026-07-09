import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

/// Az alkalmazás gyökérwidgetje.
///
/// Egyelőre csak a Flutter-scaffold Hello World tartalmát mutatja; a
/// tényleges setup- és kártyafolyam-képernyők a domain- és
/// presentation-rétegek felépülésével kerülnek a helyére.
class MainApp extends StatelessWidget {
  /// Létrehoz egy [MainApp] példányt.
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
