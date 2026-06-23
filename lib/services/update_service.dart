import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String _githubApiUrl = 'https://api.github.com/repos/infernoGurala/delve-app/releases/latest';

  static Future<void> checkAndTriggerUpdate(BuildContext context) async {
    try {
      // 1. Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Fetch latest release from GitHub
      final dio = Dio();
      final response = await dio.get(_githubApiUrl);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final String latestTagName = data['tag_name'];
        final String latestVersion = latestTagName.replaceAll(RegExp(r'^v'), '');
        final String releaseNotes = data['body'] ?? 'No release notes provided.';

        // 3. Compare versions
        if (_isNewerVersion(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, releaseNotes, data['assets']);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    List<int> currentParts = _parseVersion(current);
    List<int> latestParts = _parseVersion(latest);

    for (var i = 0; i < latestParts.length; i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (latestParts[i] > currentPart) return true;
      if (latestParts[i] < currentPart) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    // Extract only digits from each part separated by '.'
    // Handles cases like '0(Beta)' or '1.0.0-v1'
    return v.split('.').map((part) {
      final match = RegExp(r'\d+').firstMatch(part);
      return match != null ? int.parse(match.group(0)!) : 0;
    }).toList();
  }

  static void _showUpdateDialog(
    BuildContext context, 
    String version, 
    String notes, 
    List<dynamic> assets
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateDialog(
        version: version,
        notes: notes,
        assets: assets,
      ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String version;
  final String notes;
  final List<dynamic> assets;

  const _UpdateDialog({
    required this.version,
    required this.notes,
    required this.assets,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _progress = 0;
  bool _isDownloading = false;
  String _status = 'A new version is available.';

  Future<void> _startUpdate() async {
    // 1. Check/Request Permission
    var status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        setState(() => _status = 'Permission required to install updates.');
        await openAppSettings();
        return;
      }
    }

    setState(() {
      _isDownloading = true;
      _status = 'Downloading update...';
    });

    try {
      // 2. ABI Detection
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final supportedAbis = androidInfo.supportedAbis;

      String assetName = 'app-release.apk'; // Default fallback
      if (supportedAbis.contains('arm64-v8a')) {
        assetName = 'app-arm64-v8a-release.apk';
      } else if (supportedAbis.contains('armeabi-v7a')) {
        assetName = 'app-armeabi-v7a-release.apk';
      } else if (supportedAbis.contains('x86_64')) {
        assetName = 'app-x86_64-release.apk';
      }

      final asset = widget.assets.firstWhere(
        (a) => a['name'] == assetName,
        orElse: () => widget.assets.firstWhere((a) => a['name'] == 'app-release.apk', orElse: () => null),
      );

      if (asset == null) {
        setState(() => _status = 'Update asset not found.');
        return;
      }

      final downloadUrl = asset['browser_download_url'];
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$assetName';

      // 3. Download
      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              _progress = count / total;
            });
          }
        },
      );

      // 4. Install
      setState(() => _status = 'Installing...');
      await OpenFilex.open(filePath);
      
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _status = 'Update failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Available v${widget.version}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (!_isDownloading)
              Flexible(
                child: SingleChildScrollView(
                  child: Text(widget.notes, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ),
              ),
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress, borderRadius: BorderRadius.circular(10)),
              const SizedBox(height: 8),
              Center(child: Text('${(_progress * 100).toInt()}%')),
            ],
          ],
        ),
        actions: [
          if (!_isDownloading)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _startUpdate,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Update Now'),
              ),
            ),
        ],
      ),
    );
  }
}
