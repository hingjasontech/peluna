import 'package:url_launcher/url_launcher.dart';

/// Opens the GitHub release page outside the app.
abstract interface class UpdateLauncher {
  Future<bool> open(Uri uri);
}

class UrlUpdateLauncher implements UpdateLauncher {
  const UrlUpdateLauncher();

  @override
  Future<bool> open(Uri uri) async {
    if (uri.scheme != 'https') return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
