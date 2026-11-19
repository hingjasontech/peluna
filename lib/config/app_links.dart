/// Public links the app can open when the user asks for them.
///
/// Nothing here is fetched automatically; Peluna only goes online after an
/// explicit tap.
abstract final class AppLinks {
  static final Uri sourceCode = Uri.https(
    'github.com',
    '/hingjasontech/peluna',
  );
}
