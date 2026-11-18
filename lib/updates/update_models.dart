/// A semantic app version, optionally carrying an Android build number.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(
    this.major,
    this.minor,
    this.patch, {
    this.prerelease,
    this.build,
  });

  factory AppVersion.parse(String input, {int? build}) {
    var value = input.trim();
    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }

    final plus = value.indexOf('+');
    if (plus >= 0) value = value.substring(0, plus);

    String? prerelease;
    final dash = value.indexOf('-');
    if (dash >= 0) {
      prerelease = value.substring(dash + 1);
      value = value.substring(0, dash);
    }

    final parts = value.split('.');
    if (parts.isEmpty || parts.length > 3) {
      throw FormatException('Invalid version: $input');
    }

    int partAt(int index) {
      if (index >= parts.length) return 0;
      final part = parts[index];
      if (part.isEmpty) throw FormatException('Invalid version: $input');
      return int.parse(part);
    }

    return AppVersion(
      partAt(0),
      partAt(1),
      partAt(2),
      prerelease: (prerelease?.isEmpty ?? true) ? null : prerelease,
      build: build,
    );
  }

  static AppVersion? tryParse(String? input, {int? build}) {
    if (input == null || input.trim().isEmpty) return null;
    try {
      return AppVersion.parse(input, build: build);
    } on FormatException {
      return null;
    }
  }

  final int major;
  final int minor;
  final int patch;
  final String? prerelease;
  final int? build;

  @override
  int compareTo(AppVersion other) {
    for (final pair in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      final comparison = pair.$1.compareTo(pair.$2);
      if (comparison != 0) return comparison;
    }

    if (prerelease == null && other.prerelease != null) return 1;
    if (prerelease != null && other.prerelease == null) return -1;
    if (prerelease != null && other.prerelease != null) {
      final comparison = prerelease!.compareTo(other.prerelease!);
      if (comparison != 0) return comparison;
    }

    if (build != null && other.build != null) {
      return build!.compareTo(other.build!);
    }
    return 0;
  }

  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  @override
  String toString() {
    final suffix = prerelease == null ? '' : '-$prerelease';
    final buildSuffix = build == null ? '' : '+$build';
    return '$major.$minor.$patch$suffix$buildSuffix';
  }
}

/// A newer GitHub release that the user can open in a browser.
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.releaseNotes,
    required this.releasePage,
  });

  final AppVersion version;
  final String releaseNotes;
  final Uri releasePage;

  String get versionLabel => version.toString();
}

/// A user-facing update failure.
class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
