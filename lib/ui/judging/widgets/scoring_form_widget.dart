import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/judging_providers.dart';

/// Widget for scoring submissions using a scoring rubric
class ScoringFormWidget extends ConsumerStatefulWidget {
  final String submissionId;
  final String eventId;
  final String judgeId;
  final ScoringRubric rubric;
  final Score? existingScore;
  final VoidCallback? onScoreSubmitted;

  const ScoringFormWidget({
    super.key,
    required this.submissionId,
    required this.eventId,
    required this.judgeId,
    required this.rubric,
    this.existingScore,
    this.onScoreSubmitted,
  });

  @override
  ConsumerState<ScoringFormWidget> createState() => _ScoringFormWidgetState();
}

class _ScoringFormWidgetState extends ConsumerState<ScoringFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _scoreControllers = {};
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize score controllers for each criterion
    for (final criterion in widget.rubric.criteria) {
      final controller = TextEditingController();
      
      // Pre-fill with existing score if available
      if (widget.existingScore != null) {
        final existingValue = widget.existingScore!.getScore(criterion.key);
        if (existingValue != null) {
          controller.text = existingValue.toString();
        }
      }
      
      _scoreControllers[criterion.key] = controller;
    }

    // Initialize comments
    if (widget.existingScore?.comments != null) {
      _commentsController.text = widget.existingScore!.comments!;
    }
  }

  @override
  void dispose() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitScore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Collect scores from form
      final Map<String, dynamic> scores = {};
      for (final entry in _scoreControllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          final criterion = widget.rubric.getCriterion(entry.key);
          if (criterion != null) {
            switch (criterion.type) {
              case ScoringType.numeric:
              case ScoringType.scale:
                scores[entry.key] = double.tryParse(value) ?? 0.0;
                break;
              case ScoringType.boolean:
                scores[entry.key] = value.toLowerCase() == 'true' || value == '1';
                break;
            }
          }
        }
      }

      // Submit score
      await ref.read(judgingServiceProvider).scoreSubmission(
        submissionId: widget.submissionId,
        judgeId: widget.judgeId,
        eventId: widget.eventId,
        scores: scores,
        comments: _commentsController.text.trim().isEmpty 
            ? null 
            : _commentsController.text.trim(),
        rubric: widget.rubric,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Score submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onScoreSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting score: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scoring: ${widget.rubric.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (widget.rubric.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.rubric.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              
              // Scoring criteria
              ...widget.rubric.criteria.map((criterion) => 
                _buildCriterionField(criterion)
              ),
              
              const SizedBox(height: 24),
              
              // Comments section
              TextFormField(
                controller: _commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comments (Optional)',
                  hintText: 'Add any additional comments about this submission...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 2000,
              ),
              
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitScore,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Submitting...'),
                          ],
                        )
                      : const Text('Submit Score'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriterionField(ScoringCriterion criterion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  criterion.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (criterion.required)
                const Text(
                  '*',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
          if (criterion.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              criterion.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          
          // Score input based on criterion type
          _buildScoreInput(criterion),
        ],
      ),
    );
  }

  Widget _buildScoreInput(ScoringCriterion criterion) {
    switch (criterion.type) {
      case ScoringType.numeric:
        return TextFormField(
          controller: _scoreControllers[criterion.key],
          decoration: InputDecoration(
            labelText: 'Score (0 - ${criterion.maxScore})',
            border: const OutlineInputBorder(),
            suffixText: 'pts',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (criterion.required && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            
            if (value != null && value.trim().isNotEmpty) {
              final score = double.tryParse(value.trim());
              if (score == null) {
                return 'Please enter a valid number';
              }
              if (score < 0 || score > criterion.maxScore) {
                return 'Score must be between 0 and ${criterion.maxScore}';
              }
            }
            
            return null;
          },
        );
        
      case ScoringType.scale:
        final minValue = criterion.options?['min'] as num? ?? 0;
        final maxValue = criterion.options?['max'] as num? ?? criterion.maxScore;
        
        return TextFormField(
          controller: _scoreControllers[criterion.key],
          decoration: InputDecoration(
            labelText: 'Score ($minValue - $maxValue)',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (criterion.required && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            
            if (value != null && value.trim().isNotEmpty) {
              final score = double.tryParse(value.trim());
              if (score == null) {
                return 'Please enter a valid number';
              }
              if (score < minValue || score > maxValue) {
                return 'Score must be between $minValue and $maxValue';
              }
            }
            
            return null;
          },
        );
        
      case ScoringType.boolean:
        return DropdownButtonFormField<String>(
          value: _scoreControllers[criterion.key]!.text.isEmpty 
              ? null 
              : _scoreControllers[criterion.key]!.text,
          decoration: const InputDecoration(
            labelText: 'Select',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'true', child: Text('Yes')),
            DropdownMenuItem(value: 'false', child: Text('No')),
          ],
          onChanged: (value) {
            if (value != null) {
              _scoreControllers[criterion.key]!.text = value;
            }
          },
          validator: (value) {
            if (criterion.required && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        );
    }
  }
}