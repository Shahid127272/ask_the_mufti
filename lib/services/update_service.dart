import 'dart:convert';

import 'package:http/http.dart' as http;

class UpdateInfo {
  final bool updateAvailable;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseUrl;

  const UpdateInfo({
    required this.updateAvailable,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseUrl,
  });
}

class UpdateService {
  static const String _latestReleaseApi =
      'https://api.github.com/repos/Shahid127272/ask_the_mufti/releases/latest';

  static const String apkDownloadUrl =
      'https://github.com/Shahid127272/ask_the_mufti/releases/latest/download/app-release.apk';

  static const String githubReleaseUrl =
      'https://github.com/Shahid127272/ask_the_mufti/releases/latest';

  Future<UpdateInfo> checkForUpdate(String currentVersion) async {
    final response = await http.get(
      Uri.parse(_latestReleaseApi),
      headers: const {
        'Accept': 'application/vnd.github+json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to check for updates. '
            'GitHub returned ${response.statusCode}.',
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    final String tagName = (data['tag_name'] ?? '').toString().trim();

    if (tagName.isEmpty) {
      throw Exception('Latest release version was not found.');
    }

    final String latestVersion = _cleanVersion(tagName);
    final String installedVersion = _cleanVersion(currentVersion);

    final bool updateAvailable =
        _compareVersions(latestVersion, installedVersion) > 0;

    final String releaseUrl =
    (data['html_url'] ?? githubReleaseUrl).toString();

    return UpdateInfo(
      updateAvailable: updateAvailable,
      currentVersion: installedVersion,
      latestVersion: latestVersion,
      downloadUrl: apkDownloadUrl,
      releaseUrl: releaseUrl,
    );
  }

  String _cleanVersion(String version) {
    return version
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^v'), '')
        .split('+')
        .first;
  }

  int _compareVersions(String first, String second) {
    final List<int> firstParts = _versionParts(first);
    final List<int> secondParts = _versionParts(second);

    final int length = firstParts.length > secondParts.length
        ? firstParts.length
        : secondParts.length;

    for (int i = 0; i < length; i++) {
      final int firstPart = i < firstParts.length ? firstParts[i] : 0;
      final int secondPart = i < secondParts.length ? secondParts[i] : 0;

      if (firstPart > secondPart) {
        return 1;
      }

      if (firstPart < secondPart) {
        return -1;
      }
    }

    return 0;
  }

  List<int> _versionParts(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}