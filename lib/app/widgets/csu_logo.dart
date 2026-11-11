import 'package:flutter/material.dart';

import 'package:tims/app/config/app_config.dart';

/// CSU logo with a graceful fallback when the asset has not been added yet.
class CsuLogo extends StatelessWidget {
  const CsuLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConfig.logoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Cagayan State University logo',
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.school, color: Colors.white, size: size * 0.6),
      ),
    );
  }
}

/// Logo with the university and office names, for headers.
class CsuBrandHeader extends StatelessWidget {
  const CsuBrandHeader({
    super.key,
    this.logoSize = 40,
    this.onDark = false,
    this.compact = false,
  });

  final double logoSize;
  final bool onDark;

  /// Hides the second line (office name) for tight spaces.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = onDark ? Colors.white : AppColors.primary;
    final secondaryColor =
        onDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CsuLogo(size: logoSize),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConfig.universityName,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              if (!compact)
                Text(
                  AppConfig.officeName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
