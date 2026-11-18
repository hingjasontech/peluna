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

## Landing hero

The hero for the separate landing-page repo is rendered from the real home
screen, pinned to Nov 10–17, 2026 so the image only changes when the UI does:

```sh
flutter test tool/generate_landing_hero.dart
```

This writes `build/landing/home.png`, `og.png`, and `manifest.json`. The
`publish-hero` job in `Android Release` runs after a successful `v*` release
and pushes those files to the site repo, skipping the push when the images are
byte-identical.

One-time site repo setup:

1. Create the Astro repo with placeholders at `src/assets/hero/home.png` and
   `src/assets/og/og.png`. The workflow also writes
   `src/assets/hero/manifest.json`.
2. Generate a deploy key outside this repo:

   ```sh
   ssh-keygen -t ed25519 -C "peluna-hero-publisher" -f peluna_hero_deploy -N ""
   ```

3. Add `peluna_hero_deploy.pub` to the **site repo** as a deploy key with write
   access.
4. Add the private key as the `SITE_DEPLOY_KEY` secret in this repo, and a
   repository variable `SITE_REPO` set to `owner/repo`.
5. Make the site repo deploy on push to its default branch, or connect it to
   Vercel/Netlify's Git integration.

`publish-hero` is skipped until `SITE_REPO` is set, so the release workflow is
safe to keep before the site repo exists.

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
