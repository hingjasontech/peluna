

## [--> Download Here <--](https://github.com/hingjasontech/peluna/releases/latest)

# Peluna
Offline diary app. Which 
- Local only.
- No BS cloud.
- No BS ads.
- You own everything.
- Cross Platform (currently only support Android, because i am too lazy)

> [!WARNING]
> This app is vibe coded. lol

## Development

Preview locally in Chrome. No Android SDK is required:

```sh
flutter run -d chrome
```

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

## License
[MIT](./LICENSE)

## Gallery
![Gallery](_gallery/gallery.png)
