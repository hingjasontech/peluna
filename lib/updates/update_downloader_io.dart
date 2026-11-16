import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:peluna/updates/update_models.dart';

/// Downloads and verifies the APK for an update.
class UpdateDownloader {
  UpdateDownloader();

  Future<String> download(
    AppUpdate update, {
    void Function(double? progress)? onProgress,
    void Function()? onVerifying,
  }) async {
    final tempDirectory = await getTemporaryDirectory();
    final updateDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}updates',
    );
    await updateDirectory.create(recursive: true);

    final file = File(
      '${updateDirectory.path}${Platform.pathSeparator}peluna-update.apk',
    );
    final client = http.Client();
    var completed = false;

    try {
      final request = http.Request('GET', update.apkUrl);
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw UpdateException(
          'Download failed with HTTP ${response.statusCode}. Try again later.',
        );
      }

      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 30),
        )) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          final progress = totalBytes == null || totalBytes <= 0
              ? null
              : (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress?.call(progress);
        }
      } finally {
        await sink.close();
      }

      onProgress?.call(1);
      onVerifying?.call();

      final expectedChecksum = await _downloadChecksum(
        client,
        update.checksumUrl,
      );
      final actualChecksum = await _sha256(file);
      if (actualChecksum != expectedChecksum) {
        throw const UpdateException(
          'The downloaded update failed security verification.',
        );
      }

      completed = true;
      return file.path;
    } on UpdateException {
      rethrow;
    } on TimeoutException {
      throw const UpdateException(
        'The update download timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const UpdateException(
        'Could not download the update. Check your connection and try again.',
      );
    } finally {
      client.close();
      if (!completed) {
        try {
          if (await file.exists()) await file.delete();
        } on FileSystemException {
          // A leftover partial file is harmless; the next download replaces it.
        }
      }
    }
  }

  Future<String> _downloadChecksum(http.Client client, Uri checksumUrl) async {
    final response = await client
        .get(checksumUrl)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw const UpdateException(
        'Could not download the update checksum. Try again later.',
      );
    }

    final match = RegExp(r'^[a-fA-F0-9]{64}').firstMatch(response.body.trim());
    if (match == null) {
      throw const UpdateException('The release checksum is invalid.');
    }
    return match.group(0)!.toLowerCase();
  }

  Future<String> _sha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
