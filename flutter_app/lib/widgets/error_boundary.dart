import 'package:flutter/material.dart';
import '../theme.dart';

class AppErrorBoundary extends StatelessWidget {
  final Widget child;

  const AppErrorBoundary({super.key, required this.child});

  static void init() {
    ErrorWidget.builder = (details) => _ErrorWidget(details: details);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _ErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  const _ErrorWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: AppTheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.danger),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'An unexpected error occurred. Please restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
