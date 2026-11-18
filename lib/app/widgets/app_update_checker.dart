import 'package:flutter/material.dart';

import 'package:tims/app/services/app_update_service.dart';

/// Looks for a newer release on launch and whenever the app resumes,
/// and offers to download and install it.
class AppUpdateChecker extends StatefulWidget {
  const AppUpdateChecker({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AppUpdateChecker> createState() => _AppUpdateCheckerState();
}

class _AppUpdateCheckerState extends State<AppUpdateChecker> {
  static const _checkInterval = Duration(hours: 1);

  final _service = AppUpdateService();
  late final AppLifecycleListener _lifecycle;
  DateTime? _lastCheck;
  bool _checking = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final now = DateTime.now();
    final last = _lastCheck;
    if (_checking ||
        _dialogOpen ||
        (last != null && now.difference(last) < _checkInterval)) {
      return;
    }

    _checking = true;
    AppUpdate? update;
    try {
      update = await _service.checkForUpdate();
      _lastCheck = DateTime.now();
    } catch (_) {
      // Offline or GitHub unreachable: the next resume retries.
      update = null;
    } finally {
      _checking = false;
    }

    final found = update;
    final navContext = widget.navigatorKey.currentContext;
    if (found == null || navContext == null || !navContext.mounted) return;

    _dialogOpen = true;
    await showDialog<void>(
      context: navContext,
      barrierDismissible: false,
      builder: (_) => _UpdateDialog(service: _service, update: found),
    );
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.service, required this.update});

  final AppUpdateService service;
  final AppUpdate update;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    try {
      final path = await widget.service.download(widget.update, (p) {
        if (mounted) setState(() => _progress = p);
      });
      await widget.service.install(path);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Update failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.update;
    return AlertDialog(
      title: const Text('Update available'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${update.latestVersion} is available '
              '(you have ${update.currentVersion}).',
            ),
            if (update.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(update.notes),
            ],
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 8),
              Text('Downloading ${(_progress * 100).toStringAsFixed(0)}%'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
        if (!_downloading)
          FilledButton(
            onPressed: _startUpdate,
            child: const Text('Update now'),
          ),
      ],
    );
  }
}
