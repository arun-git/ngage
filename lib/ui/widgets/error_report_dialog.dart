import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/error_reporting_service.dart';
import '../../providers/auth_providers.dart';

/// Dialog for users to report errors and provide feedback
class ErrorReportDialog extends ConsumerStatefulWidget {
  final Object? error;
  final StackTrace? stackTrace;
  final String? context;

  const ErrorReportDialog({
    super.key,
    this.error,
    this.stackTrace,
    this.context,
  });

  @override
  ConsumerState<ErrorReportDialog> createState() => _ErrorReportDialogState();
}

class _ErrorReportDialogState extends ConsumerState<ErrorReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ErrorReportType _selectedType = ErrorReportType.bug;
  ErrorReportPriority _selectedPriority = ErrorReportPriority.medium;
  bool _includeSystemInfo = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.error != null) {
      _titleController.text = 'Error: ${widget.error.runtimeType}';
      _descriptionController.text = 'An error occurred: ${widget.error.toString()}';
      
      if (widget.context != null) {
        _descriptionController.text += '\n\nContext: ${widget.context}';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Issue'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help us improve Ngage by reporting this issue. Your feedback is valuable to us.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Issue Title *',
                    hintText: 'Brief description of the issue',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Detailed description of what happened',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Type selection
                DropdownButtonFormField<ErrorReportType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Issue Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ErrorReportType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeDisplayName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Priority selection
                DropdownButtonFormField<ErrorReportPriority>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: ErrorReportPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Row(
                        children: [
                          Icon(
                            _getPriorityIcon(priority),
                            color: _getPriorityColor(priority),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(_getPriorityDisplayName(priority)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Include system info checkbox
                CheckboxListTile(
                  title: const Text('Include technical details'),
                  subtitle: const Text('Help us debug by including error details and system information'),
                  value: _includeSystemInfo,
                  onChanged: (value) {
                    setState(() {
                      _includeSystemInfo = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      final member = ref.read(currentMemberProvider);
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic>? technicalDetails;
      if (_includeSystemInfo && widget.error != null) {
        technicalDetails = {
          'error': widget.error.toString(),
          'errorType': widget.error.runtimeType.toString(),
          'stackTrace': widget.stackTrace?.toString(),
          'context': widget.context,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final errorReportingService = ref.read(errorReportingServiceProvider);
      
      await errorReportingService.submitErrorReport(
        userId: user.id,
        memberId: member?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        technicalDetails: technicalDetails,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Thank you! Your report has been submitted.'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to submit report: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getTypeDisplayName(ErrorReportType type) {
    switch (type) {
      case ErrorReportType.bug:
        return 'Bug';
      case ErrorReportType.crash:
        return 'App Crash';
      case ErrorReportType.performance:
        return 'Performance Issue';
      case ErrorReportType.ui:
        return 'UI/Design Issue';
      case ErrorReportType.feature:
        return 'Feature Request';
      case ErrorReportType.other:
        return 'Other';
    }
  }

  String _getPriorityDisplayName(ErrorReportPriority priority) {
    switch (priority) {
      case ErrorReportPriority.low:
        return 'Low';
      case ErrorReportPriority.medium:
        return 'Medium';
      case ErrorReportPriority.high:
        return 'High';
      case ErrorReportPriority.critical:
        return 'Critical';
    }
  }

  IconData _getPriorityIcon(ErrorReportPriority priority) {
    switch (priority) {
      case ErrorReportPriority.low:
        return Icons.low_priority;
      case ErrorReportPriority.medium:
        return Icons.remove;
      case ErrorReportPriority.high:
        return Icons.priority_high;
      case ErrorReportPriority.critical:
        return Icons.warning;
    }
  }

  Color _getPriorityColor(ErrorReportPriority priority) {
    switch (priority) {
      case ErrorReportPriority.low:
        return Colors.green;
      case ErrorReportPriority.medium:
        return Colors.orange;
      case ErrorReportPriority.high:
        return Colors.red;
      case ErrorReportPriority.critical:
        return Colors.purple;
    }
  }
}