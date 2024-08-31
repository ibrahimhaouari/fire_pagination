import 'package:flutter/material.dart';

/// A [Widget] to show when there is an error with an option to retry.
class ErrorScreen extends StatelessWidget {
  /// Creates a [Widget] to show when there is an error with an option to retry.
  ///
  /// The [onRetry] callback is triggered when the user taps the retry button.
  final VoidCallback onRetry;

  const ErrorScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Opacity(
          opacity: 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We encountered an issue while trying to load the data. Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        ),
      );
  }
}
