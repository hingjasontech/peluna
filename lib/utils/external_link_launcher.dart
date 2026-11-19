import 'package:url_launcher/url_launcher.dart';

/// Opens an HTTPS link outside the app.
abstract interface class ExternalLinkLauncher {
  Future<bool> open(Uri uri);
}

class UrlExternalLinkLauncher implements ExternalLinkLauncher {
  const UrlExternalLinkLauncher();

  @override
  Future<bool> open(Uri uri) async {
    if (uri.scheme != 'https') return false;
    try {
      // platformDefault also works on web, where externalApplication is not
      // supported; on Android and iOS it still opens the system browser.
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }
}
