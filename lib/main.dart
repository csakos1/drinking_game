import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igyal2/src/application/content_providers.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A cache-könyvtárat a composition rootban oldjuk fel (a path_provider csak
  // itt hívódik), és override-dal injektáljuk a provider-fába — így a data-réteg
  // valós fájlrendszer nélkül is tesztelhető marad.
  final cacheDirectory = await getApplicationSupportDirectory();

  final container = ProviderContainer(
    overrides: [
      cacheDirectoryProvider.overrideWith((ref) => cacheDirectory),
    ],
  );

  // Egyszeri, nem-awaitolt háttér-frissítés: offline-first, sosem blokkolja a
  // UI-t; a dedikált HTTP-klienst a frissítés végén maga zárja le.
  unawaited(triggerContentRefresh(container));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MainApp(),
    ),
  );
}

/// Az alkalmazás gyökérwidgetje.
///
/// Egyelőre a Flutter-scaffold Hello World tartalmát mutatja; a tényleges
/// setup- és kártyafolyam-képernyők a presentation-réteg felépülésével kerülnek
/// a helyére.
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
