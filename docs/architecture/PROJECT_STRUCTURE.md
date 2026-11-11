# Project Structure

This map describes the Phase 1 files and directories created or retained in
this repository. Flutter/Gradle generated build output and local caches are
ignored rather than treated as source.

```text
.
├── android/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/ctug/ctug_mobile/MainActivity.kt
│   ├── gradle/wrapper/gradle-wrapper.properties
│   ├── build.gradle.kts
│   └── settings.gradle.kts
├── docs/
│   ├── architecture/
│   ├── decisions/
│   ├── setup/
│   └── testing/
├── env/
│   ├── dev.example.json
│   ├── prod.example.json
│   └── test.example.json
├── lib/
│   ├── app/
│   │   ├── theme/app_theme.dart
│   │   ├── app.dart
│   │   ├── app_constants.dart
│   │   ├── providers.dart
│   │   ├── router.dart
│   │   └── startup_screen.dart
│   ├── core/config/
│   │   ├── app_config.dart
│   │   └── environment.dart
│   └── main.dart
├── test/
│   ├── app/app_test.dart
│   ├── app/router_test.dart
│   └── core/config/app_config_test.dart
├── .gitattributes
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
└── README.md
```

## Layer responsibilities

- `lib/main.dart`: compile-time configuration validation and provider override;
  fail-fast startup.
- `lib/app/`: root widget, routes, app-scoped provider, startup UI, constant
  application label, and Material 3 theme.
- `lib/core/config/`: environment/log-level parsing and immutable URL
  configuration.
- `env/*.example.json`: configuration examples only; not read from disk.
- `test/`: observable configuration and widget behavior, independent of Django.
- `android/`: platform shell and generated Gradle setup; only the main
  manifest's app label changed.

## Naming and future placement

Use descriptive `snake_case.dart` file names and `UpperCamelCase` types.
Feature-specific code belongs in `lib/features/<name>/{presentation,data,domain-if-needed}/`
only when an actual feature is authorized and has content. Shared app
infrastructure stays in `lib/app/` or `lib/core/`. No empty feature directories
were created.
