import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(connectivityStreamProvider);

    return statusAsync.when(
      data: (status) {
        Color color;
        String message;

        switch (status) {
          case ConnectivityStatus.online:
            color = Colors.green;
            message = 'Online';
            break;
          case ConnectivityStatus.slow:
            color = Colors.orange;
            message = 'Weak Connection';
            break;
          case ConnectivityStatus.offline:
            color = Colors.red;
            message = 'Offline';
            break;
        }

        return Tooltip(
          message: message,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
