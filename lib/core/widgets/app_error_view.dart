import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../errors/failure_mapper.dart';

class AppErrorView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const AppErrorView({
    super.key,
    this.title = 'Something Went Wrong',
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
  });

  /// Factory constructor that automatically transforms any exception or failure
  /// object into a user-friendly error message via [FailureMapper].
  factory AppErrorView.fromError({
    Key? key,
    required dynamic error,
    String title = 'Error',
    IconData icon = Icons.error_outline,
    VoidCallback? onRetry,
  }) {
    return AppErrorView(
      key: key,
      title: title,
      message: FailureMapper.mapToMessage(error),
      icon: icon,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
