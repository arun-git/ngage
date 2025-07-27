import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/submission.dart';
import '../../models/event.dart';
import '../../providers/submission_providers.dart';
import '../../providers/event_providers.dart';
import 'widgets/file_upload_widget.dart';
import 'widgets/submission_status_indicator.dart';
import 'widgets/deadline_countdown_widget.dart';

/// Screen for creating and editing submissions
class SubmissionScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String teamId;
  final String memberId;
  final String? submissionId; // null for new submission

  const SubmissionScreen({
    super.key,
    required this.eventId,
    required this.teamId,
    required this.memberId,
    this.submissionId,
  });

  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  Submission? _submission;
  Event? _event;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
    _loadEvent();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmission() async {
    if (widget.submissionId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final submissionService = ref.read(submissionServiceProvider);
      final submission =
          await submissionService.getSubmission(widget.submissionId!);

      if (submission != null) {
        setState(() {
          _submission = submission;
          _textController.text = submission.textContent ?? '';
        });
      } else {
        setState(() {
          _error = 'Submission not found';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load submission: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEvent() async {
    try {
      final eventService = ref.read(eventServiceProvider);
      final event = await eventService.getEventById(widget.eventId);

      if (event != null) {
        setState(() {
          _event = event;
        });
      }
    } catch (e) {
      print('Failed to load event: $e');
    }
  }

  Future<void> _createOrUpdateSubmission() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final submissionService = ref.read(submissionServiceProvider);

      if (_submission == null) {
        // Create new submission
        final submission = await submissionService.createSubmission(
          eventId: widget.eventId,
          teamId: widget.teamId,
          submittedBy: widget.memberId,
          initialContent: {'text': _textController.text.trim()},
        );
        setState(() {
          _submission = submission;
        });
      } else {
        // Update existing submission
        final updatedContent = Map<String, dynamic>.from(_submission!.content);
        updatedContent['text'] = _textController.text.trim();

        final updatedSubmission =
            await submissionService.updateSubmissionContent(
          submissionId: _submission!.id,
          content: updatedContent,
        );
        setState(() {
          _submission = updatedSubmission;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission saved successfully')),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to save submission: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadFiles(String fileType) async {
    if (_submission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save your submission first')),
      );
      return;
    }

    FileType pickerFileType;
    List<String> allowedExtensions = [];

    switch (fileType) {
      case 'photos':
        pickerFileType = FileType.image;
        break;
      case 'videos':
        pickerFileType = FileType.video;
        break;
      case 'documents':
        pickerFileType = FileType.custom;
        allowedExtensions = ['pdf', 'doc', 'docx', 'txt'];
        break;
      default:
        return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: pickerFileType,
      allowedExtensions:
          allowedExtensions.isNotEmpty ? allowedExtensions : null,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _error = null;
    });

    try {
      final submissionService = ref.read(submissionServiceProvider);
      final files = result.files;

      final updatedSubmission = await submissionService.uploadPlatformFiles(
        submissionId: _submission!.id,
        files: files,
        fileType: fileType,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _submission = updatedSubmission;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${files.length} file(s) uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to upload files: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _removeFile(String fileUrl, String fileType) async {
    if (_submission == null) return;

    try {
      final submissionService = ref.read(submissionServiceProvider);
      final updatedSubmission = await submissionService.removeFile(
        submissionId: _submission!.id,
        fileUrl: fileUrl,
        fileType: fileType,
      );

      setState(() {
        _submission = updatedSubmission;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File removed successfully')),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to remove file: $e';
      });
    }
  }

  Future<void> _submitSubmission() async {
    if (_submission == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Entry'),
        content: const Text(
          'Are you sure you want to submit this entry? You won\'t be able to edit it after submission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final submissionService = ref.read(submissionServiceProvider);
      final submittedSubmission =
          await submissionService.submitSubmission(_submission!.id);

      setState(() {
        _submission = submittedSubmission;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission submitted successfully!')),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to submit: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_submission == null ? 'New Submission' : 'Edit Submission'),
        actions: [
          if (_submission != null)
            SubmissionStatusIndicator(status: _submission!.status),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: _submission?.canBeEdited == true
          ? FloatingActionButton.extended(
              onPressed:
                  _submission?.hasContent == true ? _submitSubmission : null,
              icon: const Icon(Icons.send),
              label: const Text('Submit'),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSubmission,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event information section
            if (_event != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _event!.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (_event!.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _event!.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Deadline countdown section
            if (_event != null && _event!.submissionDeadline != null) ...[
              DeadlineCountdownWidget(event: _event!),
              const SizedBox(height: 16),
            ],

            // Text content section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _textController,
                      maxLines: 5,
                      enabled: _submission?.canBeEdited != false,
                      decoration: const InputDecoration(
                        hintText: 'Describe your submission...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a description';
                        }
                        if (value.length > 5000) {
                          return 'Description must not exceed 5000 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submission?.canBeEdited != false
                          ? _createOrUpdateSubmission
                          : null,
                      child: const Text('Save Description'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // File upload sections
            if (_submission != null) ...[
              FileUploadWidget(
                title: 'Photos',
                fileType: 'photos',
                files: _submission!.photoUrls,
                canEdit: _submission!.canBeEdited,
                isUploading: _isUploading,
                uploadProgress: _uploadProgress,
                onUpload: () => _uploadFiles('photos'),
                onRemove: (url) => _removeFile(url, 'photos'),
              ),
              const SizedBox(height: 16),
              FileUploadWidget(
                title: 'Videos',
                fileType: 'videos',
                files: _submission!.videoUrls,
                canEdit: _submission!.canBeEdited,
                isUploading: _isUploading,
                uploadProgress: _uploadProgress,
                onUpload: () => _uploadFiles('videos'),
                onRemove: (url) => _removeFile(url, 'videos'),
              ),
              const SizedBox(height: 16),
              FileUploadWidget(
                title: 'Documents',
                fileType: 'documents',
                files: _submission!.documentUrls,
                canEdit: _submission!.canBeEdited,
                isUploading: _isUploading,
                uploadProgress: _uploadProgress,
                onUpload: () => _uploadFiles('documents'),
                onRemove: (url) => _removeFile(url, 'documents'),
              ),
            ],

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }
}
