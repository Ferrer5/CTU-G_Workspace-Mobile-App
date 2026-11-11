# Development Environment

## Verified on 2026-11-12

| Tool | Observed |
|---|---|
| OS | Windows 11, 25H2 |
| Flutter | 3.47.9, stable, `C:\Users\Janrey\develop\flutter` |
| Dart | 3.13.7 |
| Android SDK | 36.0.0 at `C:\Users\Janrey\AppData\Local\Android\sdk`; Flutter doctor reported Android platform 37.0 and build-tools 36.0 |
| Java selected by Flutter | Android Studio bundled JDK, OpenJDK 25.0.3 at `C:\Program Files\Android\Android Studio\jbr\bin\java` |
| `java` on terminal PATH | Java 24.0.2; Flutter selected the bundled JDK instead |
| Git | 2.52.0.windows.1 |
| Connected devices at baseline | Windows desktop, Chrome, Edge; no Android device connected |
| Existing emulator | `Medium_Phone` listed; launch attempted, but ADB reported `emulator-5554` offline |
| Android Gradle Plugin / Gradle | 9.1.0 / 9.3.1 |

## Generated Android application configuration

| Setting | Verified value |
|---|---|
| Application ID | `com.ctug.ctug_mobile` |
| Namespace | `com.ctug.ctug_mobile` |
| `minSdk` | 24 (`flutter.minSdkVersion` resolved from this Flutter SDK) |
| `compileSdk` | 36 (`flutter.compileSdkVersion`) |
| `targetSdk` | 36 (`flutter.targetSdkVersion`) |
| Java source/target compatibility | 17 |
| Kotlin JVM target | 17 |
| Main manifest label | `CTU-G` |

`flutter doctor -v` reported the Android toolchain usable and all Android
licenses accepted. It also reported a Visual Studio C++ components warning;
that warning is unrelated to Android and was not changed. Android Studio has
not been opened with this project; editor integration is not verified.

## Steps not executed

- No software was installed, upgraded, or removed, and PATH/environment
  variables were not changed.
- Android Studio project import, emulator boot completion, and physical-device
  setup were not verified.
- No Android SDK/license or Visual Studio setup was attempted.

## Commands

The supplied Flutter path was used directly for this session:

```powershell
& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' pub get
& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' analyze
& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' test
& 'C:\Users\Janrey\develop\flutter\bin\flutter.bat' build apk --debug
```

To run with local configuration, copy `env\dev.example.json` to the ignored
`env\dev.json`, then use `flutter run -d <deviceId>
--dart-define-from-file=env\dev.json`.
