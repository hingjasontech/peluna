

## [--> Download Here <--](https://github.com/hingjasontech/peluna/releases)

# Peluna
Offline diary app. Which 
- Local only.
- No BS cloud.
- No BS ads.
- You own everything.
- Cross Platform (currently only support Android, because i am too lazy)

> [!WARNING]
> Still missing a lot of features. lol

## Architecture

Small, layered and dependency-injected with [Riverpod](https://riverpod.dev):

- `lib/data/` — repositories own the Hive boxes (`DiaryRepository`, `SettingsRepository`) and the JSON backup format (`DiaryBackupService`). This is the only layer that touches storage.
- `lib/providers/` — Riverpod providers expose state to the UI. `selectedDiaryProvider` is *derived* from the selected date and the box, so imports, edits and deletes can never leave it stale. Repositories are injected in `main` through `ProviderScope` overrides.
- `lib/views/` — widgets read providers and render. Navigation, dialogs and snackbars live here; no business logic or persistence.
- `lib/models/` — plain data types (`Diary`, `DiaryDraft`).

Adding state means adding a provider, never a global. Tests inject throwaway Hive boxes via `test/support/test_harness.dart`.

## License
[MIT](./LICENSE)

## Gallery
![Gallery](_gallery/gallery.png)
