# Phase 1 Test Report

Date: 2026-11-12. Commands were run from the mobile repository root, using the
Flutter SDK path supplied for this session. Results below reflect observed
terminal output; no unrun check is represented as passing. Full final-check
output is retained outside the repository under
`%TEMP%\ctug_phase1_logs\final-*.txt`; baseline and runtime logs are in the same
directory.

| Check | Exact command | Expected | Actual output / result | Limitations |
|---|---|---|---|---|
| Flutter version | `& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' --version` | Flutter runs and reports its version | `Flutter 3.47.9 • channel stable`; exit 0 | Flutter invoked by full path; PATH unchanged. |
| Dart version | `& 'C:\Users\Janrey\develop\flutter\bin\cache\dart-sdk\bin\dart.exe' --version` | Dart version available | `Dart SDK version: 3.13.7`; exit 0 | None. |
| Android environment | `& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' doctor -v` | Android toolchain has no failed item | `[√] Android toolchain ... (Android SDK version 36.0.0)`; bundled Java 25.0.3; Visual Studio warning only; exit 0 | Android Studio UI integration not verified. |
| Dependency resolution | `& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' pub get` | Resolve declared packages | `Got dependencies!`; exit 0 | Pub reports five packages have newer versions outside current constraints; no upgrade requested. |
| Dependency graph | `& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' pub deps` | Report direct and transitive resolved packages | Direct additions: `flutter_riverpod 3.5.0`, `go_router 18.1.4`; exit 0 | Full graph is in command output and `pubspec.lock`. |
| Dart format | `& 'C:\Users\Janrey\develop\flutter\bin\cache\dart-sdk\bin\dart.exe' format --output=none --set-exit-if-changed .` | No files require formatting | Final run: `Formatted 12 files (0 changed)`; exit 0 | Initial check found three files and they were formatted before final check. |
| Static analysis | `& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' analyze` | Zero errors, warnings, and infos | `No issues found!`; exit 0 | An initial missing `material.dart` import was fixed, then analysis passed. |
| Tests | `& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' test` | All config and widget/router tests pass | `00:04 +17: All tests passed!`; exit 0 | No Django server or network required. |
| Debug APK | `& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' build apk --debug` | APK builds successfully | `Built build\app\outputs\flutter-apk\app-debug.apk`; exit 0 | Gradle emitted Java restricted-native-access warnings; build succeeded. |
| Runtime device discovery | `& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' devices --device-timeout 60` | Existing emulator available | `Device emulator-5554 is offline.`; command exit 0 | Runtime launch not verified. |
| Emulator launch | `& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' emulators --launch Medium_Phone` | Launch the existing AVD | Command exit 0; ADB still reported the emulator offline | No AVD was created. |
| ADB state | `C:\Users\Janrey\AppData\Local\Android\sdk\platform-tools\adb.exe devices -l`; `C:\Users\Janrey\AppData\Local\Android\sdk\platform-tools\adb.exe -s emulator-5554 get-state` | ADB reports emulator online | ADB listed `emulator-5554 offline`; `get-state` returned `error: device offline` | Diagnostics were read-only. App was not run and no `env/dev.json` was created. |
| Ignore examples | `git check-ignore -v env/dev.json`; `git check-ignore -v env/dev.example.json`; `git check-ignore -q env/dev.example.json` | Local config ignored; examples trackable | `dev.json` matched `.gitignore:41:env/*.json` (exit 0). The verbose example query displayed `.gitignore:42:!env/*.example.json`; quiet query returned exit 1, and Git status listed the example as untracked (therefore trackable). | `git check-ignore -v` displays the matching negation rule; `-q` plus status confirms the example is not ignored. |
| Credential scan | `git grep --cached -n -I -i -E "password|passwd|secret|token|api[_-]?key|BEGIN [A-Z ]*PRIVATE KEY"` | No secret values | Reviewed staged matches; hits are documentation terminology/configuration discussion, not credentials | Raw hits are retained outside the repo; values were not printed. |
| Workstation-path scan | `git grep --cached -n -I -E 'C:\\Users\\Janrey|C:/Users/Janrey'` | No accidental machine-specific source/config paths | Matches occur in required setup/README/architecture/ADR documentation only; none in source or Android config | Local paths in docs are intentional environment/repository facts. |

## Permission exception

The main `android/app/src/main/AndroidManifest.xml` was inspected: its
`<application>`/activity/query declarations contain no `INTERNET` permission
and no cleartext/network-security setting. The generated debug and profile
manifests were inspected and contain Flutter template development
`INTERNET` permissions. Those debug/profile files were left untouched under
the user's explicit exception. Source inspection found no networking code or
HTTP package dependency. The built release manifest was not inspected;
release permission status is **not verified**.

## Baseline and repository boundary

Before project creation, the user verified that the target contained no entries.
`.vscode` was an allowed-but-optional entry; the folder was empty before
creation, and no files were deleted. The mobile repository was initialized on
`main`. Protected-repository HEAD, status, diff stat, and diff SHA-256 are
compared against the authorized baseline in the completion report.
