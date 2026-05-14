---
name: Replicate Angular Workshop GDG in Flutter
overview: Mirror the Angular `workshop_gdg` "Do Caos ao Kanban" app as a Flutter app for Web, Android, and iOS — same class names (`App`, `Quadro`, `Tarefa`, `GeminiService`, `QuadrosService`), same folder structure under `lib/`, same Gemini + Firestore behavior, same dark/red UI.
todos:
  - id: deps
    content: Add firebase_core, cloud_firestore, google_generative_ai to pubspec.yaml; bump Android minSdk to 21 and iOS platform to 13.0
    status: completed
  - id: flutterfire
    content: Run flutterfire configure against workshop-gdg-rec to generate lib/firebase_options.dart, google-services.json, GoogleService-Info.plist
    status: completed
  - id: environment
    content: Create lib/environments/environment.dart mirroring environment.ts (production flag + geminiApiKey)
    status: completed
  - id: models
    content: Create lib/app/models/quadro_model.dart and tarefa_model.dart mirroring the Angular interfaces and union types (with JSON helpers)
    status: completed
  - id: services
    content: Create lib/app/services/gemini_service.dart (GenerativeModel, identical prompt) and quadros_service.dart (Firestore collection 'quadros', criadoEm ISO timestamp)
    status: completed
  - id: app_config_routes
    content: Create lib/app/app_config.dart and lib/app/app_routes.dart as structural mirrors of app.config.ts and app.routes.ts
    status: completed
  - id: app_widget
    content: Create lib/app/app.dart with the App StatefulWidget reproducing app.ts state, methods, and the app.html UI (hero, panel, kanban, history) with dark/red theme from app.css and 980px responsive breakpoint
    status: completed
  - id: main
    content: Rewrite lib/main.dart to initialize Firebase with DefaultFirebaseOptions.currentPlatform and run App (mirror of main.ts)
    status: completed
  - id: web_index
    content: Update web/index.html title to match the Angular app's title block
    status: completed
  - id: test
    content: Add test/app_test.dart mirroring app.spec.ts (smoke test that App renders)
    status: completed
  - id: verify
    content: Run flutter analyze and flutter build for web (and a smoke flutter run on chrome if quick) to confirm everything compiles
    status: completed
isProject: false
---

## Reference structure (Angular → Flutter mapping)

```mermaid
flowchart LR
  subgraph Angular [refs/workshop_gdg/src]
    A1[main.ts]
    A2[app/app.config.ts]
    A3[app/app.routes.ts]
    A4["app/app.ts + app.html + app.css"]
    A5[app/models/quadro.model.ts]
    A6[app/models/tarefa.model.ts]
    A7[app/services/gemini.service.ts]
    A8[app/services/quadros.service.ts]
    A9[environments/environment.ts]
  end
  subgraph Flutter [lib/]
    F1[main.dart]
    F2[app/app_config.dart]
    F3[app/app_routes.dart]
    F4[app/app.dart]
    F5[app/models/quadro_model.dart]
    F6[app/models/tarefa_model.dart]
    F7[app/services/gemini_service.dart]
    F8[app/services/quadros_service.dart]
    F9[environments/environment.dart]
    F10[firebase_options.dart]
  end
  A1-->F1
  A2-->F2
  A3-->F3
  A4-->F4
  A5-->F5
  A6-->F6
  A7-->F7
  A8-->F8
  A9-->F9
  A9-->F10
```

## Dependency & tooling setup

- Update [pubspec.yaml](pubspec.yaml) to add:
  - `firebase_core` (Firebase bootstrap, all platforms)
  - `cloud_firestore` (mirrors `firebase/firestore`)
  - `google_generative_ai` (Dart equivalent of `@google/genai`)
- Run `flutterfire configure --project=workshop-gdg-rec` to:
  - Generate `lib/firebase_options.dart`
  - Add `android/app/google-services.json`
  - Add `ios/Runner/GoogleService-Info.plist`
  - Patch Gradle (`android/build.gradle`, `android/app/build.gradle`) and `ios/Runner/Info.plist` automatically.
- `android/app/build.gradle`: confirm `minSdkVersion >= 21` (Firestore requirement); bump if needed.
- `ios/Podfile`: confirm `platform :ios, '13.0'` (Firestore requirement); bump if needed.
- `web/index.html`: update `<title>` to `Plan w/ AI` (mirror of Angular `index.html` title block). No Firebase JS SDK needed — `firebase_core_web` handles it via `firebase_options.dart`.

## Class & file mapping (same class names, snake_case files)

- [lib/main.dart](lib/main.dart) — equivalent of [refs/workshop_gdg/src/main.ts](refs/workshop_gdg/src/main.ts). Runs `WidgetsFlutterBinding.ensureInitialized()`, `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`, sets Firestore debug log level when not production (mirror of `setLogLevel('debug')`), then `runApp(const App())`.
- [lib/app/app_config.dart](lib/app/app_config.dart) — mirror of [app.config.ts](refs/workshop_gdg/src/app/app.config.ts). Holds an `appConfig` const placeholder (Angular providers list is empty; we keep the file for structural fidelity and future DI hooks).
- [lib/app/app_routes.dart](lib/app/app_routes.dart) — mirror of [app.routes.ts](refs/workshop_gdg/src/app/app.routes.ts). Empty `routes` list (kept for fidelity).
- [lib/app/app.dart](lib/app/app.dart) — mirror of [app.ts + app.html + app.css](refs/workshop_gdg/src/app/app.ts):
  - `class App extends StatefulWidget` with `_AppState` holding:
    - `String textoTarefas` (mirrors `textoTarefas`)
    - `Quadro? quadroAtual` (mirrors `quadroAtual` signal)
    - `List<Quadro> historico` (mirrors `historico` signal)
    - `bool carregando`, `bool salvando`, `String? erro`
  - `late final GeminiService geminiService` and `late final QuadrosService quadrosService` (constructed in `initState`).
  - Methods with identical names: `organizarComIA()`, `tarefasPorStatus(StatusTarefa)`, `moverTarefa(Tarefa, StatusTarefa)`, `salvarQuadro()`, `carregarHistorico()`, `abrirQuadro(Quadro)`.
  - `build()` recreates the HTML structure: hero (eyebrow / h1 / subtitle), panel (label + multi-line `TextField` + two action buttons + error text), kanban board (3 columns: "A fazer", "Em andamento", "Concluído"), and history list.
  - Theme: black `Scaffold` background, red accent `#FF005C`, Inter font fallback, dark cards with red left-border (`Container` + `Border(left: BorderSide(width: 2, color: pink))`), uppercase tag chips.
  - Responsive: `LayoutBuilder` swaps the kanban from 3-column `Row` to a single-column `Column` when `maxWidth < 980` (mirrors the CSS media query).
- [lib/app/models/quadro_model.dart](lib/app/models/quadro_model.dart) — mirror of [quadro.model.ts](refs/workshop_gdg/src/app/models/quadro.model.ts). `class Quadro { String? id; String tituloQuadro; List<Tarefa> tarefas; String? criadoEm; }` with `Quadro.fromJson`/`toJson`.
- [lib/app/models/tarefa_model.dart](lib/app/models/tarefa_model.dart) — mirror of [tarefa.model.ts](refs/workshop_gdg/src/app/models/tarefa.model.ts). Five Dart enums (`CategoriaTarefa`, `PrioridadeTarefa`, `EsforcoTarefa`, `PrazoSugerido`, `StatusTarefa`) whose string values exactly match the Angular union types (`a_fazer`, `em_andamento`, `concluido`, etc.) via `name`/`fromString`. `class Tarefa { String titulo; CategoriaTarefa categoria; PrioridadeTarefa prioridade; EsforcoTarefa esforco; PrazoSugerido prazoSugerido; StatusTarefa status; }` with JSON helpers.
- [lib/app/services/gemini_service.dart](lib/app/services/gemini_service.dart) — mirror of [gemini.service.ts](refs/workshop_gdg/src/app/services/gemini.service.ts):
  ```dart
  class GeminiService {
    final _ai = GenerativeModel(model: 'gemini-2.5-flash', apiKey: Environment.geminiApiKey);
    Future<Quadro> organizarTarefas(String textoUsuario) async { ... }
    String _criarPrompt(String textoUsuario) { ... }  // exact same prompt text as Angular
    Quadro _converterRespostaParaQuadro(String resposta) { ... }
  }
  ```
  The prompt string is copied verbatim from the Angular service so Gemini output stays identical.
- [lib/app/services/quadros_service.dart](lib/app/services/quadros_service.dart) — mirror of [quadros.service.ts](refs/workshop_gdg/src/app/services/quadros.service.ts):
  ```dart
  class QuadrosService {
    final _quadrosRef = FirebaseFirestore.instance.collection('quadros');
    Future<void> salvarQuadro(Quadro quadro) async { ... }   // adds criadoEm = DateTime.now().toIso8601String()
    Future<List<Quadro>> listarQuadros() async { ... }       // orderBy('criadoEm', descending: true)
  }
  ```
- [lib/environments/environment.dart](lib/environments/environment.dart) — mirror of [environment.ts](refs/workshop_gdg/src/environments/environment.ts). A `class Environment` with `static const bool production = false`, `static const String geminiApiKey = '...'`. Firebase config keys (apiKey/projectId/etc.) live in the generated `firebase_options.dart` rather than being duplicated here, which is the FlutterFire-idiomatic equivalent of the Angular `firebaseConfig` block.

## Tests

- [test/app_test.dart](test/app_test.dart) — mirror of [app.spec.ts](refs/workshop_gdg/src/app/app.spec.ts). A basic `testWidgets` that pumps `App` and asserts an `h1`-equivalent (`Do Caos ao Kanban`) renders. Firebase calls are not exercised in this test (keeping parity with the Angular test, which also doesn't hit Firestore).

## Non-goals / explicit caveats

- Pixel-perfect CSS parity is not promised: borders, spacing, hover transitions, and uppercase-letter spacing will be visually close (same palette, same layout structure, same typography hierarchy) but implemented with Flutter `Theme`/`TextStyle`/`Container` rather than literal CSS.
- The Gemini API key is reproduced from the Angular `environment.ts` as a hardcoded constant for fidelity. If you'd like it moved to `--dart-define` later, that's a small follow-up.
- Running `flutterfire configure` will prompt interactively (account login + platform selection) and will register Android/iOS apps in the `workshop-gdg-rec` Firebase project. I will run it during implementation and pause for any prompts that need your input.
