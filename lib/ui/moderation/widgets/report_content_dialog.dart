import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/content_report.dart';
import '../../../providers/moderation_providers.dart';

class ReportContentDialog extends ConsumerStatefulWidget {
  final String contentId;
  final ContentType contentType;

  const ReportContentDialog({
    super.key,
    required this.contentId,
    required this.contentType,
  });

  @override
  ConsumerState<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends ConsumerState<ReportContentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.contentType.name.toUpperCase()}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting this ${widget.contentType.name}?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildReasonSelection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  hintText: 'Provide more context about why you\'re reporting this content...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 8),
              Text(
                'Reports are reviewed by our moderation team. False reports may result in account restrictions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }

  Widget _buildReasonSelection() {
    return Column(
      children: ReportReason.values.map((reason) {
        return RadioListTile<ReportReason>(
          title: Text(_getReasonText(reason)),
          subtitle: Text(_getReasonDescription(reason)),
          value: reason,
          groupValue: _selectedReason,
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
            });
          },
        );
      }).toList(),
    );
  }

  String _getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment or Bullying';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.copyright:
        return 'Copyright Violation';
      case ReportReason.misinformation:
        return 'Misinformation';
      case ReportReason.other:
        return 'Other';
    }
  }

  String _getReasonDescription(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Unwanted commercial content or repetitive posts';
      case ReportReason.harassment:
        return 'Targeted harassment, threats, or bullying behavior';
      case ReportReason.inappropriateContent:
        return 'Content that violates community guidelines';
      case ReportReason.copyright:
        return 'Unauthorized use of copyrighted material';
      case ReportReason.misinformation:
        return 'False or misleading information';
      case ReportReason.other:
        return 'Other policy violations not listed above';
    }
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate() || _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for reporting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final service = ref.read(moderationServiceProvider);
      await service.reportContent(
        reporterId: 'current_user_id', // TODO: Get from auth
        contentId: widget.contentId,
        contentType: widget.contentType,
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Helper function to show the report dialog
void showReportContentDialog(
  BuildContext context,
  String contentId,
  ContentType contentType,
) {
  showDialog(
    context: context,
    builder: (context) => ReportContentDialog(
      contentId: contentId,
      contentType: contentType,
    ),
  );
}