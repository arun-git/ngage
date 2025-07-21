import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/judging_providers.dart';

/// Widget for managing scoring rubrics
class RubricManagementWidget extends ConsumerStatefulWidget {
  final String? eventId;
  final String? groupId;
  final String createdBy;
  final Function(ScoringRubric)? onRubricSelected;

  const RubricManagementWidget({
    super.key,
    this.eventId,
    this.groupId,
    required this.createdBy,
    this.onRubricSelected,
  });

  @override
  ConsumerState<RubricManagementWidget> createState() => _RubricManagementWidgetState();
}

class _RubricManagementWidgetState extends ConsumerState<RubricManagementWidget> {
  bool _showCreateForm = false;
  ScoringRubric? _selectedRubric;

  @override
  Widget build(BuildContext context) {
    final availableRubricsAsync = ref.watch(eventRubricsProvider(widget.eventId ?? ''));
    final templateRubricsAsync = ref.watch(templateRubricsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule, size: 24, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Scoring Rubrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showCreateForm = !_showCreateForm),
                  icon: Icon(_showCreateForm ? Icons.close : Icons.add),
                  label: Text(_showCreateForm ? 'Cancel' : 'Create New'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_showCreateForm) ...[
              _buildCreateRubricForm(),
              const SizedBox(height: 24),
            ],
            
            // Available rubrics
            availableRubricsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading rubrics: $error'),
              data: (rubrics) => _buildRubricsList(
                'Event Rubrics',
                rubrics,
                Icons.event,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Template rubrics
            templateRubricsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading templates: $error'),
              data: (templates) => _buildRubricsList(
                'Template Rubrics',
                templates,
                Icons.template_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRubricForm() {
    return CreateRubricForm(
      eventId: widget.eventId,
      groupId: widget.groupId,
      createdBy: widget.createdBy,
      onRubricCreated: (rubric) {
        setState(() => _showCreateForm = false);
        widget.onRubricSelected?.call(rubric);
        // Refresh the rubrics list
        ref.refresh(eventRubricsProvider(widget.eventId ?? ''));
      },
    );
  }

  Widget _buildRubricsList(String title, List<ScoringRubric> rubrics, IconData icon) {
    if (rubrics.isEmpty) {
      return Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          const Text('No rubrics available', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ...rubrics.map((rubric) => _buildRubricTile(rubric)),
      ],
    );
  }

  Widget _buildRubricTile(ScoringRubric rubric) {
    final isSelected = _selectedRubric?.id == rubric.id;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        title: Text(rubric.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rubric.description),
            const SizedBox(height: 4),
            Text(
              '${rubric.criteria.length} criteria • Max: ${rubric.maxPossibleScore.toInt()} pts',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rubric.isTemplate)
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Clone Template',
                onPressed: () => _cloneRubric(rubric),
              ),
            IconButton(
              icon: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked),
              onPressed: () {
                setState(() {
                  _selectedRubric = isSelected ? null : rubric;
                });
                if (!isSelected) {
                  widget.onRubricSelected?.call(rubric);
                }
              },
            ),
          ],
        ),
        onTap: () => _showRubricDetails(rubric),
      ),
    );
  }

  void _showRubricDetails(ScoringRubric rubric) {
    showDialog(
      context: context,
      builder: (context) => RubricDetailsDialog(rubric: rubric),
    );
  }

  Future<void> _cloneRubric(ScoringRubric template) async {
    try {
      final cloneRubric = ref.read(cloneRubricProvider);
      final cloned = await cloneRubric(
        rubricId: template.id,
        createdBy: widget.createdBy,
        newName: '${template.name} (Copy)',
        eventId: widget.eventId,
        groupId: widget.groupId,
        isTemplate: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rubric cloned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the rubrics list
        ref.refresh(eventRubricsProvider(widget.eventId ?? ''));
        widget.onRubricSelected?.call(cloned);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cloning rubric: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Form for creating new scoring rubrics
class CreateRubricForm extends ConsumerStatefulWidget {
  final String? eventId;
  final String? groupId;
  final String createdBy;
  final Function(ScoringRubric) onRubricCreated;

  const CreateRubricForm({
    super.key,
    this.eventId,
    this.groupId,
    required this.createdBy,
    required this.onRubricCreated,
  });

  @override
  ConsumerState<CreateRubricForm> createState() => _CreateRubricFormState();
}

class _CreateRubricFormState extends ConsumerState<CreateRubricForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ScoringCriterion> _criteria = [];
  bool _isTemplate = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Rubric',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              // Basic info
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Rubric Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a rubric name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Template checkbox
              CheckboxListTile(
                title: const Text('Save as Template'),
                subtitle: const Text('Templates can be reused across events'),
                value: _isTemplate,
                onChanged: (value) => setState(() => _isTemplate = value ?? false),
              ),
              const SizedBox(height: 16),
              
              // Criteria section
              Row(
                children: [
                  Text(
                    'Scoring Criteria',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _addCriterion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Criterion'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (_criteria.isEmpty)
                const Text(
                  'No criteria added yet. Add at least one criterion to create the rubric.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ..._criteria.asMap().entries.map((entry) => 
                  _buildCriterionTile(entry.key, entry.value)
                ),
              
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _criteria.isEmpty ? null : _submitRubric,
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
                            Text('Creating...'),
                          ],
                        )
                      : const Text('Create Rubric'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriterionTile(int index, ScoringCriterion criterion) {
    return Card(
      child: ListTile(
        title: Text(criterion.name),
        subtitle: Text(
          '${criterion.description}\n'
          'Max: ${criterion.maxScore} pts • Weight: ${criterion.weight} • '
          '${criterion.required ? 'Required' : 'Optional'}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _removeCriterion(index),
        ),
        onTap: () => _editCriterion(index),
      ),
    );
  }

  void _addCriterion() {
    showDialog(
      context: context,
      builder: (context) => CriterionDialog(
        onSave: (criterion) {
          setState(() => _criteria.add(criterion));
        },
      ),
    );
  }

  void _editCriterion(int index) {
    showDialog(
      context: context,
      builder: (context) => CriterionDialog(
        criterion: _criteria[index],
        onSave: (criterion) {
          setState(() => _criteria[index] = criterion);
        },
      ),
    );
  }

  void _removeCriterion(int index) {
    setState(() => _criteria.removeAt(index));
  }

  Future<void> _submitRubric() async {
    if (!_formKey.currentState!.validate() || _criteria.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final createRubric = ref.read(createScoringRubricProvider);
      final rubric = await createRubric(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        criteria: _criteria,
        eventId: _isTemplate ? null : widget.eventId,
        groupId: _isTemplate ? null : widget.groupId,
        isTemplate: _isTemplate,
        createdBy: widget.createdBy,
      );

      widget.onRubricCreated(rubric);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating rubric: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Dialog for creating/editing scoring criteria
class CriterionDialog extends StatefulWidget {
  final ScoringCriterion? criterion;
  final Function(ScoringCriterion) onSave;

  const CriterionDialog({
    super.key,
    this.criterion,
    required this.onSave,
  });

  @override
  State<CriterionDialog> createState() => _CriterionDialogState();
}

class _CriterionDialogState extends State<CriterionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxScoreController;
  late final TextEditingController _weightController;
  late ScoringType _type;
  late bool _required;

  @override
  void initState() {
    super.initState();
    final criterion = widget.criterion;
    
    _keyController = TextEditingController(text: criterion?.key ?? '');
    _nameController = TextEditingController(text: criterion?.name ?? '');
    _descriptionController = TextEditingController(text: criterion?.description ?? '');
    _maxScoreController = TextEditingController(text: criterion?.maxScore.toString() ?? '100');
    _weightController = TextEditingController(text: criterion?.weight.toString() ?? '1.0');
    _type = criterion?.type ?? ScoringType.numeric;
    _required = criterion?.required ?? true;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.criterion == null ? 'Add Criterion' : 'Edit Criterion'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _keyController,
                  decoration: const InputDecoration(
                    labelText: 'Key (unique identifier)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<ScoringType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Scoring Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ScoringType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.value),
                  )).toList(),
                  onChanged: (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxScoreController,
                        decoration: const InputDecoration(
                          labelText: 'Max Score',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final score = double.tryParse(value);
                          if (score == null || score <= 0) {
                            return 'Must be positive';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Must be positive';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                CheckboxListTile(
                  title: const Text('Required'),
                  value: _required,
                  onChanged: (value) => setState(() => _required = value ?? true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCriterion,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveCriterion() {
    if (!_formKey.currentState!.validate()) return;

    final criterion = ScoringCriterion(
      key: _keyController.text.trim(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _type,
      maxScore: double.parse(_maxScoreController.text.trim()),
      weight: double.parse(_weightController.text.trim()),
      required: _required,
    );

    widget.onSave(criterion);
    Navigator.of(context).pop();
  }
}

/// Dialog for showing rubric details
class RubricDetailsDialog extends StatelessWidget {
  final ScoringRubric rubric;

  const RubricDetailsDialog({
    super.key,
    required this.rubric,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(rubric.name),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rubric.description),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  if (rubric.isTemplate)
                    const Chip(
                      label: Text('Template'),
                      backgroundColor: Colors.blue,
                    ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${rubric.criteria.length} criteria'),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('Max: ${rubric.maxPossibleScore.toInt()} pts'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(
                'Scoring Criteria',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              ...rubric.criteria.map((criterion) => Card(
                child: ListTile(
                  title: Text(criterion.name),
                  subtitle: Text(
                    '${criterion.description}\n'
                    'Max: ${criterion.maxScore} pts • Weight: ${criterion.weight} • '
                    'Type: ${criterion.type.value} • '
                    '${criterion.required ? 'Required' : 'Optional'}',
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}