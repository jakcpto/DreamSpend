import 'package:flutter/material.dart';

import '../widgets/app_scope.dart';

/// Shows a dismissible MaterialBanner if GameStore has a persistenceError.
class ErrorBannerListener extends StatelessWidget {
  const ErrorBannerListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (store.persistenceError == null) return child;

    return Column(
      children: [
        MaterialBanner(
          backgroundColor: Colors.red.shade50,
          content: Text(
            store.persistenceError!,
            style: const TextStyle(color: Colors.red),
          ),
          leading: const Icon(Icons.error_outline, color: Colors.red),
          actions: [
            TextButton(
              onPressed: () => store.clearPersistenceError(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
        Expanded(child: child),
      ],
    );
  }
}
