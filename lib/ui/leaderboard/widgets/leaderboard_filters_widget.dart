import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// Widget for leaderboard filtering and sorting options
class LeaderboardFiltersWidget extends StatefulWidget {
  final LeaderboardFilter? currentFilter;
  final LeaderboardSort currentSort;
  final bool showCriteriaBreakdown;
  final ValueChanged<LeaderboardFilter?> onFilterChanged;
  final ValueChanged<LeaderboardSort> onSortChanged;
  final ValueChanged<bool> onShowCriteriaChanged;

  const LeaderboardFiltersWidget({
    super.key,
    required this.currentFilter,
    required this.currentSort,
    required this.showCriteriaBreakdown,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onShowCriteriaChanged,
  });

  @override
  State<LeaderboardFiltersWidget> createState() => _LeaderboardFiltersWidgetState();
}

class _LeaderboardFiltersWidgetState extends State<LeaderboardFiltersWidget> {
  bool _isExpanded = false;
  
  // Filter controllers
  final _minScoreController = TextEditingController();
  final _maxScoreController = TextEditingController();
  final _minSubmissionsController = TextEditingController();
  final _topNController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _minScoreController.dispose();
    _maxScoreController.dispose();
    _minSubmissionsController.dispose();
    _topNController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    final filter = widget.currentFilter;
    if (filter != null) {
      _minScoreController.text = filter.minScore?.toString() ?? '';
      _maxScoreController.text = filter.maxScore?.toString() ?? '';
      _minSubmissionsController.text = filter.minSubmissions?.toString() ?? '';
      _topNController.text = filter.topN?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Header with expand/collapse
          ListTile(
            leading: const Icon(Icons.filter_list),
            title: const Text('Filters & Options'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick sort buttons
                _buildQuickSortButton(
                  'Score',
                  LeaderboardSortField.averageScore,
                  Icons.score,
                ),
                _buildQuickSortButton(
                  'Name',
                  LeaderboardSortField.teamName,
                  Icons.sort_by_alpha,
                ),
                _buildQuickSortButton(
                  'Submissions',
                  LeaderboardSortField.submissionCount,
                  Icons.assignment,
                ),
                
                // Expand/collapse button
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),
          
          // Expandable content
          if (_isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display options
                  _buildDisplayOptions(),
                  
                  const SizedBox(height: 16),
                  
                  // Score filters
                  _buildScoreFilters(),
                  
                  const SizedBox(height: 16),
                  
                  // Other filters
                  _buildOtherFilters(),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSortButton(String label, LeaderboardSortField field, IconData icon) {
    final isActive = widget.currentSort.field == field;
    final isAscending = widget.currentSort.ascending;
    
    return Tooltip(
      message: 'Sort by $label',
      child: InkWell(
        onTap: () => _handleQuickSort(field),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: isActive ? Border.all(color: Theme.of(context).primaryColor) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Theme.of(context).primaryColor : null,
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Options',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        
        CheckboxListTile(
          title: const Text('Show Criteria Breakdown'),
          subtitle: const Text('Display individual scoring criteria'),
          value: widget.showCriteriaBreakdown,
          onChanged: (value) => widget.onShowCriteriaChanged(value ?? false),
          dense: true,
        ),
      ],
    );
  }

  Widget _buildScoreFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score Filters',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minScoreController,
                decoration: const InputDecoration(
                  labelText: 'Min Score',
                  hintText: '0.0',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxScoreController,
                decoration: const InputDecoration(
                  labelText: 'Max Score',
                  hintText: '100.0',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other Filters',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minSubmissionsController,
                decoration: const InputDecoration(
                  labelText: 'Min Submissions',
                  hintText: '1',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _topNController,
                decoration: const InputDecoration(
                  labelText: 'Show Top N',
                  hintText: 'All',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _applyFilters,
          icon: const Icon(Icons.check),
          label: const Text('Apply Filters'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.clear),
          label: const Text('Clear All'),
        ),
        const Spacer(),
        
        // Sort direction toggle
        IconButton(
          onPressed: _toggleSortDirection,
          icon: Icon(
            widget.currentSort.ascending ? Icons.arrow_upward : Icons.arrow_downward,
          ),
          tooltip: widget.currentSort.ascending ? 'Sort Descending' : 'Sort Ascending',
        ),
      ],
    );
  }

  void _handleQuickSort(LeaderboardSortField field) {
    final currentSort = widget.currentSort;
    
    // If same field, toggle direction; otherwise, use default direction
    final ascending = currentSort.field == field ? !currentSort.ascending : false;
    
    widget.onSortChanged(LeaderboardSort(
      field: field,
      ascending: ascending,
    ));
  }

  void _toggleSortDirection() {
    widget.onSortChanged(widget.currentSort.copyWith(
      ascending: !widget.currentSort.ascending,
    ));
  }

  void _applyFilters() {
    final minScore = double.tryParse(_minScoreController.text);
    final maxScore = double.tryParse(_maxScoreController.text);
    final minSubmissions = int.tryParse(_minSubmissionsController.text);
    final topN = int.tryParse(_topNController.text);

    // Validate inputs
    if (minScore != null && (minScore < 0 || minScore > 100)) {
      _showValidationError('Min score must be between 0 and 100');
      return;
    }
    
    if (maxScore != null && (maxScore < 0 || maxScore > 100)) {
      _showValidationError('Max score must be between 0 and 100');
      return;
    }
    
    if (minScore != null && maxScore != null && minScore > maxScore) {
      _showValidationError('Min score cannot be greater than max score');
      return;
    }
    
    if (minSubmissions != null && minSubmissions < 0) {
      _showValidationError('Min submissions cannot be negative');
      return;
    }
    
    if (topN != null && topN <= 0) {
      _showValidationError('Top N must be a positive number');
      return;
    }

    // Create filter
    final filter = LeaderboardFilter(
      minScore: minScore,
      maxScore: maxScore,
      minSubmissions: minSubmissions,
      topN: topN,
    );

    widget.onFilterChanged(filter);
    
    // Collapse the filters
    setState(() => _isExpanded = false);
  }

  void _clearFilters() {
    _minScoreController.clear();
    _maxScoreController.clear();
    _minSubmissionsController.clear();
    _topNController.clear();
    
    widget.onFilterChanged(null);
    
    // Reset sort to default
    widget.onSortChanged(const LeaderboardSort(
      field: LeaderboardSortField.averageScore,
      ascending: false,
    ));
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}