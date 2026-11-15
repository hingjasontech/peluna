# Contributing

## Requirements

- Flutter 3.50+ (Dart 3.11+)

## Preview locally

Preview in Chrome. No Android SDK is required:

```sh
flutter run -d chrome
```

## Tests

```sh
flutter test
flutter analyze --no-fatal-infos
```

## Gallery

The gallery in the README is not hand-made. It is rendered from the real app
widgets, in dark mode at phone size, with sample data for the current month:

```sh
flutter test tool/generate_gallery.dart
```

This rewrites `_gallery/gallery.png`. The generator lives in
`tool/generate_gallery.dart`; edit the capture list there to add, remove or
reorder screens. The `Gallery` GitHub Actions workflow also runs it on pushes
to `main` that touch `lib/` and commits the refreshed image, so the README
never drifts from the app.

## Releasing

Android APKs are built, signed, and published by GitHub Actions.

1. Bump `version` in `pubspec.yaml` (for example `1.0.1+2`) and push `main`.
2. Push a matching tag:

```sh
git tag v1.0.1
git push origin v1.0.1
```

The workflow checks that the tag matches `pubspec.yaml`, runs the tests, builds
the signed APK, and attaches it to the GitHub Release. Required repository
secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`.

The release can also be re-run from **Actions → Android Release → Run
workflow** with an existing tag.
