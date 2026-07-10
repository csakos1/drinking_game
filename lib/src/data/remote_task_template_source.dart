import 'package:http/http.dart' as http;
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/result.dart';

/// Távoli, statikus hostingról (pl. raw.githubusercontent.com) letöltő forrás.
///
/// Az URL és a timeout a composition rootból jön; a `http.Client`
/// injektálható a tesztelhetőségért (alap: új `http.Client`). Csak GET; a
/// sikeres, nem üres válasz törzsét adja vissza. Bármely hálózati probléma
/// (időtúllépés, nem 2xx státusz, üres válasz, kivétel) →
/// [TaskSourceNetworkFailure].
class RemoteTaskTemplateSource implements TaskTemplateSource {
  /// Létrehoz egy [RemoteTaskTemplateSource]-t.
  ///
  /// A [client] a tesztelhetőségért injektálható; ha `null`, új `http.Client`
  /// jön létre. A [timeout] a kérés időkorlátja (alap: 5 mp).
  RemoteTaskTemplateSource(
    this._uri, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  final Uri _uri;
  final Duration _timeout;
  final http.Client _client;

  @override
  Future<Result<String, TaskSourceError>> load() async {
    // A load() sosem dobhat (interfész-szerződés): minden hibát Failure-ré
    // fordítunk. A timeout `TimeoutException`-t, a hálózat egyéb hibái
    // `ClientException`/`SocketException`-t dobnak — szélesen kapjuk el.
    try {
      final response = await _client.get(_uri).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(
          TaskSourceNetworkFailure('Nem 2xx státusz: ${response.statusCode}.'),
        );
      }
      if (response.body.isEmpty) {
        return const Failure(TaskSourceNetworkFailure('Üres válasz.'));
      }
      return Success(response.body);
    } on Object catch (e) {
      return Failure(TaskSourceNetworkFailure('Hálózati hiba: $e'));
    }
  }
}
