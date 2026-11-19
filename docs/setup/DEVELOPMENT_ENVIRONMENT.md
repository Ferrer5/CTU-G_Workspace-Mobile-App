# Development Environment

For emulator connectivity, the host/backend boundary, and the Phase 2 test
results, see [Network Setup](NETWORK_SETUP.md),
[Network Architecture](../architecture/NETWORK_ARCHITECTURE.md), and the
[Phase 2 Test Report](../testing/PHASE-2-TEST-REPORT.md).

## Daily run routine

Open three PowerShell windows:

1. **Backend:** In the backend repo's `backend` folder, run
   `python manage.py runserver 0.0.0.0:8000`. Include the emulator's host alias
   and the laptop's LAN address in `WORKSPACE_ALLOWED_HOSTS`.
2. **Emulator:** Start `Medium_Phone` with
   `emulator.exe -avd Medium_Phone -feature -Vulkan -no-snapshot-load -cores 4 -memory 4096`.
3. **App:** From the mobile repo root, run
   `flutter run -d emulator-5554 --no-enable-impeller --dart-define-from-file=env\dev.emulator.example.json`.

**REPORTED:** The shorthand `python manage.py runserver 0:8000` failed with
`getaddrinfo failed` on this Windows machine, so the full address is used.

## Emulator hang on this laptop

**REPORTED:** `Medium_Phone` initially stopped at “hanging thread QEMU2 CPU0”; a
first attempt with `-gpu swiftshader_indirect` also hung. It ran smoothly with
the launch command above. The Android emulator reaches the backend through its
host alias, which must be allowed by `WORKSPACE_ALLOWED_HOSTS`.

If Windows reports multiple emulator instances for the same AVD, check for
leftover processes with:

```powershell
Get-Process | Where-Object { $_.ProcessName -match 'qemu|emulator' }
```

**REPORTED:** `adb` is not on PATH on this laptop; it is under the Android SDK's
`platform-tools` folder.

## Verified on 2026-11-12

| Tool | Observed |
|---|---|
| OS | Windows 11, 25H2 |
| Flutter | 3.47.9, stable (installation path omitted) |
| Dart | 3.13.7 |
| Android SDK | 36.0.0 (installation path omitted); Flutter doctor reported Android platform 37.0 and build-tools 36.0 |
| Java selected by Flutter | Android Studio bundled JDK, OpenJDK 25.0.3 at `C:\Program Files\Android\Android Studio\jbr\bin\java` |
| `java` on terminal PATH | Java 24.0.2; Flutter selected the bundled JDK instead |
| Git | 2.52.0.windows.1 |
| Connected devices at baseline | Windows desktop, Chrome, Edge; no Android device connected |
| Existing emulator | `Medium_Phone`; initially listed as offline by ADB, later recovered by the user and successfully used for the debug runtime check below |
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

## Emulator offline troubleshooting

The existing `Medium_Phone` emulator initially appeared offline in ADB and
`flutter devices` reported `Device emulator-5554 is offline`, even though the
emulator window showed the home screen. `adb kill-server`/`adb start-server`
and `adb reconnect offline` did not resolve it.

- Likely cause: a stale saved emulator snapshot (inferred from the cold boot with -no-snapshot-load working; not proven).
- Hardware acceleration was ruled out as the cause: the emulator log reported "Windows Hypervisor Platform accelerator is operational" and all compatibility checks passed.

The user resolved the issue by stopping leftover emulator/QEMU processes,
restarting ADB, and cold-booting the existing AVD with
`emulator.exe -avd Medium_Phone -no-snapshot-load`. The boot log reported
WHPX operational and compatibility checks passed. After `adb wait-for-device`,
`getprop sys.boot_completed` returned `1` and ADB listed the emulator as
`device`. No AVD was created by the agent.

The agent then ran
`flutter run -d emulator-5554 --dart-define-from-file=env/dev.json --no-resident`.
It exited successfully, and the app process remained present with the same PID
after 30 seconds. The user had previously confirmed the startup screen text;
the agent did not inspect the screen.

## Steps not executed

- No software was installed, upgraded, or removed, and PATH/environment
  variables were not changed.
- Android Studio project import and physical-device setup were not verified.
- No Android SDK/license or Visual Studio setup was attempted.

## Commands

The supplied Flutter path was used directly for this session:

```powershell
& '<Flutter SDK path>\bin\flutter.bat' pub get
& '<Flutter SDK path>\bin\flutter.bat' analyze
& '<Flutter SDK path>\bin\flutter.bat' test
& '<Flutter SDK path>\bin\flutter.bat' build apk --debug
```

To run with local configuration, copy `env\dev.example.json` to the ignored
`env\dev.json`, then use `flutter run -d <deviceId>
--dart-define-from-file=env\dev.json`.
