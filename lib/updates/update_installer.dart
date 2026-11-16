import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:peluna/updates/update_models.dart';

/// Bridges the downloaded APK to Android's package installer.
class UpdateInstaller {
  const UpdateInstaller();

  static const MethodChannel _channel = MethodChannel('peluna/updater');

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> canInstall() async {
    if (!isSupported) return false;
    return await _channel.invokeMethod<bool>('canInstall') ?? false;
  }

  Future<void> openInstallSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('openInstallSettings');
  }

  Future<void> install(String path) async {
    if (!isSupported) {
      throw const UpdateException(
        'Updates can only be installed from the Android app.',
      );
    }
    await _channel.invokeMethod<void>('install', {'path': path});
  }
}
