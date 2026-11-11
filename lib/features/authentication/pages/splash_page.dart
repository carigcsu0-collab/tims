import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tims/app/config/app_config.dart';
import 'package:tims/app/routes/route_paths.dart';
import 'package:tims/app/widgets/csu_logo.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/features/authentication/providers/auth_provider.dart';

/// Splash page that attempts to restore a previous session on launch.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConfig.mediumAnimation,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    await ref.read(authNotifierProvider.notifier).restoreSession();
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state is AuthAuthenticated) {
      context.go(RoutePaths.dashboard);
    } else {
      context.go(RoutePaths.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CsuLogo(size: 96),
              const SizedBox(height: 24),
              Text(
                AppConfig.universityName,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConfig.appFullName,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
