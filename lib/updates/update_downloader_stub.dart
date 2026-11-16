import 'package:peluna/updates/update_models.dart';

/// Web builds can check for releases but cannot install Android APKs.
class UpdateDownloader {
  UpdateDownloader();

  Future<String> download(
    AppUpdate update, {
    void Function(double? progress)? onProgress,
    void Function()? onVerifying,
  }) {
    throw UnsupportedError('Updates can only be installed on Android.');
  }
}
