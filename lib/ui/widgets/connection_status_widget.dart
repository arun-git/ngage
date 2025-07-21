import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/realtime_service.dart';
import '../../providers/realtime_providers.dart';

/// Widget that displays connection status and provides user feedback
/// 
/// Shows connection status indicators and allows users to retry connections
/// or force sync when offline.
class ConnectionStatusWidget extends ConsumerWidget {
  final bool showDetails;
  final VoidCallback? onRetry;

  const ConnectionStatusWidget({
    super.key,
    this.showDetails = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final pendingOperations = ref.watch(pendingOperationsCountProvider);

    return connectionStatus.when(
      data: (status) => _buildStatusWidget(context, status, pendingOperations),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildErrorWidget(context),
    );
  }

  Widget _buildStatusWidget(BuildContext context, ConnectionStatus status, int pendingCount) {
    switch (status) {
      case ConnectionStatus.connected:
        if (pendingCount > 0) {
          return _buildSyncingWidget(context, pendingCount);
        }
        return showDetails ? _buildConnectedWidget(context) : const SizedBox.shrink();
        
      case ConnectionStatus.disconnected:
        return _buildDisconnectedWidget(context, pendingCount);
        
      case ConnectionStatus.reconnecting:
        return _buildReconnectingWidget(context);
    }
  }

  Widget _buildConnectedWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi,
            size: 16,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Online',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedWidget(BuildContext context, int pendingCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Offline${pendingCount > 0 ? ' ($pendingCount pending)' : ''}',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Icon(
                Icons.refresh,
                size: 16,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReconnectingWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Reconnecting...',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingWidget(BuildContext context, int pendingCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Syncing $pendingCount item${pendingCount == 1 ? '' : 's'}...',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Connection Error',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner widget that shows connection status at the top of the screen
class ConnectionStatusBanner extends ConsumerWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final pendingOperations = ref.watch(pendingOperationsCountProvider);

    return connectionStatus.when(
      data: (status) {
        if (status == ConnectionStatus.connected && pendingOperations == 0) {
          return const SizedBox.shrink();
        }
        
        return _buildBanner(context, ref, status, pendingOperations);
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildErrorBanner(context, ref),
    );
  }

  Widget _buildBanner(BuildContext context, WidgetRef ref, ConnectionStatus status, int pendingCount) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;
    bool showAction = false;

    switch (status) {
      case ConnectionStatus.connected:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.sync;
        message = 'Syncing $pendingCount item${pendingCount == 1 ? '' : 's'}...';
        break;
        
      case ConnectionStatus.disconnected:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.wifi_off;
        message = pendingCount > 0 
            ? 'You\'re offline. $pendingCount change${pendingCount == 1 ? '' : 's'} will sync when reconnected.'
            : 'You\'re offline. Some features may be limited.';
        showAction = true;
        break;
        
      case ConnectionStatus.reconnecting:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.wifi_protected_setup;
        message = 'Reconnecting...';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showAction) ...[
            TextButton(
              onPressed: () => ref.read(realtimeServiceProvider).forceSyncWhenOnline(),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        border: Border(
          bottom: BorderSide(
            color: Colors.red.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Connection error. Please check your internet connection.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(realtimeServiceProvider).forceSyncWhenOnline(),
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating action button that shows connection status
class ConnectionStatusFAB extends ConsumerWidget {
  final VoidCallback? onPressed;

  const ConnectionStatusFAB({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final pendingOperations = ref.watch(pendingOperationsCountProvider);

    return connectionStatus.when(
      data: (status) {
        if (status == ConnectionStatus.connected && pendingOperations == 0) {
          return const SizedBox.shrink();
        }
        
        return _buildFAB(context, ref, status, pendingOperations);
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildErrorFAB(context, ref),
    );
  }

  Widget _buildFAB(BuildContext context, WidgetRef ref, ConnectionStatus status, int pendingCount) {
    Color backgroundColor;
    IconData icon;
    String tooltip;

    switch (status) {
      case ConnectionStatus.connected:
        backgroundColor = Colors.blue;
        icon = Icons.sync;
        tooltip = 'Syncing $pendingCount item${pendingCount == 1 ? '' : 's'}';
        break;
        
      case ConnectionStatus.disconnected:
        backgroundColor = Colors.orange;
        icon = Icons.wifi_off;
        tooltip = 'Offline - Tap to retry connection';
        break;
        
      case ConnectionStatus.reconnecting:
        backgroundColor = Colors.blue;
        icon = Icons.wifi_protected_setup;
        tooltip = 'Reconnecting...';
        break;
    }

    return FloatingActionButton.small(
      onPressed: onPressed ?? () => ref.read(realtimeServiceProvider).forceSyncWhenOnline(),
      backgroundColor: backgroundColor,
      tooltip: tooltip,
      child: status == ConnectionStatus.reconnecting || (status == ConnectionStatus.connected && pendingCount > 0)
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, color: Colors.white),
    );
  }

  Widget _buildErrorFAB(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      onPressed: onPressed ?? () => ref.read(realtimeServiceProvider).forceSyncWhenOnline(),
      backgroundColor: Colors.red,
      tooltip: 'Connection error - Tap to retry',
      child: const Icon(Icons.error_outline, color: Colors.white),
    );
  }
}