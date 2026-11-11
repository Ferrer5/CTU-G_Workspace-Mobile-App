# Android Studio Setup

## Verified facts

- Flutter doctor found a usable Android SDK at
  `C:\Users\Janrey\AppData\Local\Android\sdk` (Android SDK 36.0.0) and selected
  the JDK bundled at
  `C:\Program Files\Android\Android Studio\jbr\bin\java` (OpenJDK 25.0.3).
- The Android Gradle build succeeded with this environment.
- Android Studio itself did not report a separately verified version in the
  collected Flutter doctor output. The project was not opened in its UI.
- The existing `Medium_Phone` AVD was listed. Its launch was attempted, but ADB
  reported it offline; no AVD was created.

## Instructions not executed

1. Open Android Studio and choose **Open**.
2. Select `C:\Users\Janrey\CTU-G_Workspace Mobile App`.
3. Allow Gradle sync to complete.
4. Select the existing `Medium_Phone` device or connect an Android device.
5. If asked to install components or accept licenses, stop and request approval;
   no software installation is authorized by Phase 1.

Opening the project and successful Android Studio run/debug integration remain
unverified until those steps are completed.
