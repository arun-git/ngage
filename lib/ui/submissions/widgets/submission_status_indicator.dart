import 'package:flutter/material.dart';
import '../../../models/enums.dart';

/// Widget that displays the current status of a submission with appropriate styling
class SubmissionStatusIndicator extends StatelessWidget {
  final SubmissionStatus status;
  final bool showLabel;

  const SubmissionStatusIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(context);
    
    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusInfo.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusInfo.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusInfo.icon,
              size: 16,
              color: statusInfo.color,
            ),
            const SizedBox(width: 4),
            Text(
              statusInfo.label,
              style: TextStyle(
                color: statusInfo.color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      return Icon(
        statusInfo.icon,
        color: statusInfo.color,
        size: 20,
      );
    }
  }

  _StatusInfo _getStatusInfo(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (status) {
      case SubmissionStatus.draft:
        return _StatusInfo(
          label: 'Draft',
          icon: Icons.edit,
          color: theme.colorScheme.outline,
        );
      case SubmissionStatus.submitted:
        return _StatusInfo(
          label: 'Submitted',
          icon: Icons.send,
          color: Colors.blue,
        );
      case SubmissionStatus.underReview:
        return _StatusInfo(
          label: 'Under Review',
          icon: Icons.hourglass_empty,
          color: Colors.orange,
        );
      case SubmissionStatus.approved:
        return _StatusInfo(
          label: 'Approved',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case SubmissionStatus.rejected:
        return _StatusInfo(
          label: 'Rejected',
          icon: Icons.cancel,
          color: Colors.red,
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;

  _StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Extension to provide helper methods for SubmissionStatus
extension SubmissionStatusExtension on SubmissionStatus {
  /// Get a human-readable description of the status
  String get description {
    switch (this) {
      case SubmissionStatus.draft:
        return 'This submission is still being edited and has not been submitted yet.';
      case SubmissionStatus.submitted:
        return 'This submission has been submitted and is waiting for review.';
      case SubmissionStatus.underReview:
        return 'This submission is currently being reviewed by judges.';
      case SubmissionStatus.approved:
        return 'This submission has been approved and accepted.';
      case SubmissionStatus.rejected:
        return 'This submission has been rejected and will not be considered.';
    }
  }

  /// Check if the status allows editing
  bool get canEdit {
    return this == SubmissionStatus.draft;
  }

  /// Check if the status is final (no further changes expected)
  bool get isFinal {
    return this == SubmissionStatus.approved || this == SubmissionStatus.rejected;
  }

  /// Get the next possible statuses from the current status
  List<SubmissionStatus> get possibleNextStatuses {
    switch (this) {
      case SubmissionStatus.draft:
        return [SubmissionStatus.submitted];
      case SubmissionStatus.submitted:
        return [SubmissionStatus.underReview];
      case SubmissionStatus.underReview:
        return [SubmissionStatus.approved, SubmissionStatus.rejected];
      case SubmissionStatus.approved:
      case SubmissionStatus.rejected:
        return []; // Final states
    }
  }
}