# ADR-0002 — Tartalomforrás-absztrakció és cache-orchestráció

- **Státusz:** elfogadva
- **Dátum:** 2026-07-10

## Kontextus

Az `ARCHITECTURE.md` 7. fejezete a tartalom-pipeline *viselkedését* normatívan
leírja (forrás → validáció → entitás; olvasási sorrend cache → bundled asset;
háttérben fire-and-forget frissítés + atomi cache-csere; offline-first;
v2-határ). A data-réteg *konkrét formája* viszont nyitott: a forrás-interfész
aláírása, a hibatípus, a függőség-injektálás és a bevonandó csomagok.

Kényszerek és adottságok:

- **v2-garancia:** forrás-specifikus fogalom (URL, HTTP, cache-fájl) nem
  léphet át a data→domain határon; a v2 backend bevezetése pontosan egy
  data-implementáció cseréje vagy hozzáadása, a domaint és a presentationt nem
  érinti.
- A domain már ad egy `Result<T, E>` sealed típust és egy
  `ContentValidator.validate(String)`-et, amely a nyers JSON-ból validált
  `TaskContent`-et állít elő, `ContentValidationError`-ral bukva.
- Tesztelhetőség/determinizmus: a domain-konvenció szerint a külső
  függőségek injektáltak (pl. a `Random` hívásparaméterként).
- A bundled asset a séma-teszt miatt mindig érvényes „padló".

## Döntés

### 1. Read-interfész: nyers JSON, domain `Result`-tal

```dart
abstract interface class TaskTemplateSource {
  Future<Result<String, TaskSourceError>> load();
}
```

A forrás nyers JSON stringet ad; a **tartalom érvényessége nem a forrás dolga**
(azt a `ContentValidator` dönti el). A `Result` a domainből újrahasznosítva
(a data→domain import engedett). `Future`, mert az asset/fájl/hálózat aszinkron.

### 2. Külön, data-rétegbeli hibatípus

Sealed `TaskSourceError` a data rétegben — **nem** a domain
`ContentValidationError`-ja. Esetek:

- `notFound` — az asset/cache nem létezik;
- `unreadable` — I/O-hiba olvasáskor;
- `network` — fetch sikertelen (timeout, nem-2xx, üres törzs).

Indok: az I/O-hiba nem tartalom-validációs hiba; a kettő keverése sértené az
SRP-t, és beszennyezné a domain-hibahierarchiát. A `notFound` nem „kemény"
hiba: a repository ilyenkor a következő forrásra lép.

### 3. Implementációk és a cache írási felelőssége

- `BundledAssetTaskTemplateSource` — `rootBundle`, `assets/content/tasks.json`;
- `CachedFileTaskTemplateSource` — app-adatkönyvtár;
- `RemoteTaskTemplateSource` — statikus hosting URL, rövid timeout.

A `CachedFileTaskTemplateSource` a közös `load()`-on túl kap egy
`save(String rawJson)`-t, amely a **temp-írás + rename atomi cserét maga
végzi** — így minden fájlút/`dart:io`-fogalom a cache-osztályon belül marad.
A read-interfész csak `load()` (ISP: a többi forrás nem ír).

### 4. Függőség-injektálás

A konkrét cache-könyvtárat (`Directory`) és a remote URL-t (`Uri`) a
**composition root (application)** oldja fel és injektálja konstruktorban; a
`RemoteTaskTemplateSource` `http.Client`-et és timeoutot is kap. A
`path_provider`-hívás **kizárólag a composition rootban** él — a platform-
channel nem szivárog a forrásba, és a források temp-könyvtárral / fake klienssel
unit-tesztelhetők (illeszkedik a „`Random` mint hívásparaméter" filozófiához).

### 5. Orchestráció: `TaskContentRepository`

- **Olvasás:** érvényes cache → bundled asset. A cache olvasáskor is
  validálódik; az érvénytelen cache (sérült fájl, nem támogatott verzió)
  figyelmen kívül marad és törlődik, a bundled asset szolgál ki.
- **Frissítés:** háttérben, fire-and-forget: remote fetch → validálás →
  `cache.save()` atomi csere. Bármely lépés hibája némán (logolva) elnyelődik;
  a UI-t soha nem blokkolja.
- Mivel a bundled asset mindig érvényes padló, a `loadContent()`
  **nem-nullable** `TaskContent`-et ad — sosem bukhat teljesen.

### 6. Új függőségek

- `path_provider` — az app-adatkönyvtár feloldása (data/application);
- `http` — a remote fetch, injektálható klienssel a tiszta teszteléshez.

A domain-tisztaság érintetlen: mindkét csomag a data/application rétegben él, a
domain továbbra is csak `dart:core/convert/math` + `package:meta`.

## Következmények

- A v2 backend bevezetése: egy új vagy cserélt `TaskTemplateSource`
  implementáció + a repository forrás-listájának bővítése; a domain és a
  presentation érintetlen.
- A cache írás/olvasás a cache-osztályba zárva → a path-fogalom nem szivárog a
  határon túl.
- Új platform-függőség (`path_provider`), de a források továbbra is tisztán
  (temp-könyvtárral, fake klienssel) tesztelhetők.

## Elvetett alternatívák

- **A domain `ContentValidationError` újrahasználata I/O-hibákra** — elvetve
  (SRP + domain-tisztaság; az I/O és a tartalom-érvényesség külön felelősség).
- **`path_provider`-hívás a forráson belül** — elvetve (tesztelhetőség,
  platform-channel-szivárgás).
- **`dart:io HttpClient` a `http` helyett** — elvetve: a `http` injektálható
  kliense tisztább, mock nélküli tesztelést ad; a `dart:io` a cache-fájlhoz
  amúgy is bejön, de a hálózatot a `http` fedi.
