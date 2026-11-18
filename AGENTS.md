# AGENTS.md

Peluna is a local-only Flutter diary app. Keep it offline: no accounts, cloud sync, analytics, or ads. Android is the release target; Chrome is the fast dev target.

## Commands

```sh
flutter pub get --enforce-lockfile  # CI install mode
flutter run -d chrome               # preview without Android SDK
flutter test                        # full suite
flutter test test/week_start_test.dart
flutter test test/week_start_test.dart --plain-name "HomePage calendar"
flutter analyze --no-fatal-infos    # CI command
dart run build_runner build         # after Hive model/adapter changes
flutter test tool/generate_gallery.dart  # regenerate README gallery
```

CI pins Flutter 3.50.0 (Dart 3.14) and uses the committed lockfile. `flutter analyze` already reports many `deprecated_member_use` infos; do not mass-migrate them as part of unrelated work.

## Dependencies

- Agents may add or remove any package from pub.dev when the task needs it. Prefer `flutter pub add <package>` / `flutter pub remove <package>` and commit both `pubspec.yaml` and `pubspec.lock`; CI installs with `--enforce-lockfile`.

## Terminology

- Peluna is a score-based diary: the daily `-2..2` rating is always called a **score**, never a mood. `Diary.score` is Hive field index `2`; do not change that index. Old backups and settings may still use the legacy `mood` / `show_calendar_mood` keys, which `Diary.fromJson` and `SettingsRepository` accept as fallbacks.

## Wiring

- `lib/main.dart` opens the `diaries` and `settings` Hive boxes and overrides `diaryRepositoryProvider` / `settingsRepositoryProvider`. Those providers throw until overridden, so widget tests must use `HiveTestHarness` or provide equivalent overrides.
- `DiaryRepository` is the only layer that touches the diaries box. Entries are keyed by `dateToString(date)` (`yyyy-MM-dd`). `clear()` intentionally compacts the box so deleted text does not linger on disk.
- Hive adapters are generated from `lib/config/hive/hive_adapters.dart`. Never hand-edit `*.g.dart` or `*.g.yaml`; run build_runner after changing `Diary` or the adapter spec.
- `diaryRevisionProvider` is an incrementing int, not a stream, because Riverpod skips equal states. New providers that must react to box changes should watch it.
- `Diary.fromJson` intentionally throws when `date` is missing or invalid. Do not restore a `DateTime.now()` fallback; it used to overwrite today's entry during imports.
- `lib/config/router.dart` is a 3-branch shell (`/`, `/analytics`, `/settings`); the diary editor and tags are root-navigator routes (`/diary`, `/diary/tags`).
- `DiaryPage` intentionally blocks swipes to days without entries (except the day it opened on) and auto-saves the day being left. Preserve its custom horizontal drag handling.
- Settings are grouped into `SettingsSection` cards (`Appearance`, `Data`, `Updates`) with `SettingsTile` rows from `lib/views/widgets/settings_section.dart`. Put new settings in the matching section, or add a new section/card, instead of a flat list of tiles. The Updates section stays gated by `supportsSelfUpdateProvider`.

## Tests

- Use `HiveTestHarness` from `test/support/test_harness.dart`. It opens memory-backed boxes with `bytes: Uint8List(0)`; real Hive file writes inside widget tests do not resolve.
- Seed or mutate Hive inside `tester.runAsync`, then `await tester.pump()` (often followed by another pump or a short duration) so the change stream updates Riverpod.
- `flutter test` only runs `test/`; the gallery generator lives in `tool/` and must be run explicitly.

## Gallery

- `_gallery/gallery.png` is generated from real widgets by `tool/generate_gallery.dart`; never edit it by hand. Add, remove, or reorder screens in that file.
- The Gallery workflow reruns the generator on `main` for changes under `lib/`, `tool/generate_gallery.dart`, or pubspec, then commits the image. Expect a bot commit after such a push and `git pull --ff-only` before continuing.
- CI renders on Linux, so its image can differ slightly from a local render; the bot commit is the authoritative version.

## Landing hero

- `tool/generate_landing_hero.dart` renders the real home screen at 390×844 @2x with a pinned Nov 10–17, 2026 fixture into `build/landing/` (`home.png`, `og.png`, `manifest.json`). Run `flutter test tool/generate_landing_hero.dart`.
- The pinned date is intentional: it makes a byte-level image diff mean "the home page UI changed". Without it, the rolling calendar would make every release look changed. `nowProvider` exists so the generator can pin "today" as well.
- The `publish-hero` job in `android-release.yml` runs after a successful `v*` release and pushes the images to the separate site repo only when their bytes changed. It stays skipped until the `SITE_REPO` repository variable and `SITE_DEPLOY_KEY` secret exist.
- Never hand-edit the published hero; change the widget or the fixture and regenerate.

## Releases

- A push to `main` never releases. The Android workflow runs only for `v*` tags (or manual dispatch of an existing tag).
- Release flow: bump `version` in `pubspec.yaml` to `X.Y.Z+N`, commit and push `main`, then push tag `vX.Y.Z`. The tag must match the version name or CI fails.
- CI creates `android/key.properties` and the `.p12` keystore from repository secrets. Local release builds without those files fall back to debug signing.
- Full steps and secret names: `CONTRIBUTING.md`.
