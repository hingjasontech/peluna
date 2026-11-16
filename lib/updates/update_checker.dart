import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:peluna/updates/update_models.dart';

const String _owner = 'hingjasontech';
const String _repository = 'peluna';

abstract interface class UpdateChecker {
  Future<AppUpdate?> checkForUpdate();

  void close();
}

/// Checks the latest public GitHub release for a newer APK.
class GitHubUpdateChecker implements UpdateChecker {
  GitHubUpdateChecker({
    http.Client? client,
    Future<AppVersion> Function()? installedVersion,
  }) : _client = client ?? http.Client(),
       _installedVersion = installedVersion ?? _loadInstalledVersion;

  static final Uri _latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/$_owner/$_repository/releases/latest',
  );

  final http.Client _client;
  final Future<AppVersion> Function() _installedVersion;

  @override
  Future<AppUpdate?> checkForUpdate() async {
    final currentVersion = await _installedVersion();

    final http.Response response;
    try {
      response = await _client
          .get(
            _latestReleaseUri,
            headers: {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'User-Agent': 'Peluna/$currentVersion',
            },
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const UpdateException(
        'GitHub did not respond in time. Check your connection and try again.',
      );
    } on Exception {
      throw const UpdateException(
        'Could not reach GitHub. Check your connection and try again.',
      );
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 403:
        throw const UpdateException(
          'GitHub is temporarily rate-limiting update checks. Try again later.',
        );
      case 404:
        throw const UpdateException('No releases have been published yet.');
      default:
        throw UpdateException(
          'GitHub returned HTTP ${response.statusCode}. Try again later.',
        );
    }

    final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      data = decoded;
    } on FormatException {
      throw const UpdateException('GitHub returned an invalid release.');
    }

    final tag = data['tag_name'];
    final latestVersion = tag is String ? AppVersion.tryParse(tag) : null;
    if (latestVersion == null) {
      throw const UpdateException('The latest release has an invalid version.');
    }

    if (!latestVersion.isNewerThan(currentVersion)) return null;

    final assets = data['assets'];
    Map<String, dynamic>? apkAsset;
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name'];
        if (name is String && name.toLowerCase().endsWith('.apk')) {
          apkAsset = asset;
          break;
        }
      }
    }

    if (apkAsset == null) {
      throw const UpdateException(
        'The latest release does not include an APK to install.',
      );
    }

    final apkName = apkAsset['name'] as String;
    final apkUrl = apkAsset['browser_download_url'];
    if (apkUrl is! String) {
      throw const UpdateException('The latest APK has no download link.');
    }

    Map<String, dynamic>? checksumAsset;
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name'];
        if (name == '$apkName.sha256') {
          checksumAsset = asset;
          break;
        }
      }
    }

    final checksumUrl = checksumAsset?['browser_download_url'];
    if (checksumUrl is! String) {
      throw const UpdateException(
        'The latest release has no checksum for the APK.',
      );
    }

    final releasePage = data['html_url'];
    final releaseNotes = data['body'];
    final apkSize = apkAsset['size'];

    return AppUpdate(
      version: latestVersion,
      releaseNotes: releaseNotes is String ? releaseNotes : '',
      releasePage: releasePage is String
          ? _secureUri(releasePage)
          : Uri.https('github.com', '/$_owner/$_repository/releases/tag/$tag'),
      apkUrl: _secureUri(apkUrl),
      checksumUrl: _secureUri(checksumUrl),
      apkSize: apkSize is int ? apkSize : 0,
    );
  }

  @override
  void close() => _client.close();

  static Uri _secureUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') {
      throw const UpdateException('The release has an insecure download link.');
    }
    return uri;
  }

  static Future<AppVersion> _loadInstalledVersion() async {
    final info = await PackageInfo.fromPlatform();
    return AppVersion.parse(
      info.version,
      build: int.tryParse(info.buildNumber),
    );
  }
}
