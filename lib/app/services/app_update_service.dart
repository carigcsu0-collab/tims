import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

const _latestReleaseUrl =
    'https://api.github.com/repos/carigcsu0-collab/tims/releases/latest';

/// A newer release that can be installed on the current platform.
class AppUpdate {
  const AppUpdate({
    required this.currentVersion,
    required this.latestVersion,
    required this.notes,
    required this.fileName,
    required this.downloadUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final String notes;
  final String fileName;
  final String downloadUrl;
}

/// Checks GitHub releases for a newer build, downloads it, and installs it.
class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Returns the newer release for this platform, or null when the app is
  /// up to date or the platform does not support in-app updates.
  Future<AppUpdate?> checkForUpdate() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isWindows)) return null;

    final info = await PackageInfo.fromPlatform();
    final response = await _dio.get<Map<String, dynamic>>(
      _latestReleaseUrl,
      options: Options(
        headers: {'Accept': 'application/vnd.github+json'},
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    final data = response.data;
    if (data == null) return null;

    final latest = (data['tag_name'] as String? ?? '').replaceFirst(RegExp('^v'), '');
    if (latest.isEmpty || compareVersions(latest, info.version) <= 0) {
      return null;
    }

    final assets = (data['assets'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (_matchesPlatform(name)) {
        return AppUpdate(
          currentVersion: info.version,
          latestVersion: latest,
          notes: data['body'] as String? ?? '',
          fileName: name,
          downloadUrl: asset['browser_download_url'] as String,
        );
      }
    }
    return null;
  }

  /// Downloads the update into the temp folder and returns its path.
  Future<String> download(
    AppUpdate update,
    void Function(double progress) onProgress,
  ) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}${Platform.pathSeparator}${update.fileName}';
    await _dio.download(
      update.downloadUrl,
      path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );
    return path;
  }

  /// Opens the Android package installer, or runs the Windows setup.
  Future<void> install(String path) async {
    if (Platform.isAndroid) {
      final result = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
      return;
    }
    await Process.start(path, const [], mode: ProcessStartMode.detached);
    // Inno Setup can only replace the running executable once the app exits.
    exit(0);
  }

  bool _matchesPlatform(String name) {
    if (Platform.isAndroid) return name.endsWith('.apk');
    return name.startsWith('CSU-TVET-IMS-Setup') && name.endsWith('.exe');
  }
}

/// Compares dotted version strings numerically. Ignores any `+build` or `-pre` suffix.
int compareVersions(String a, String b) {
  List<int> parse(String v) {
    final core = v.split('+').first.split('-').first;
    return core.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }

  final x = parse(a);
  final y = parse(b);
  final length = x.length > y.length ? x.length : y.length;
  for (var i = 0; i < length; i++) {
    final xi = i < x.length ? x[i] : 0;
    final yi = i < y.length ? y[i] : 0;
    if (xi != yi) return xi.compareTo(yi);
  }
  return 0;
}
