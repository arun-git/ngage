import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/analytics.dart';

class AnalyticsFilterWidget extends ConsumerStatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? selectedEventId;
  final AnalyticsPeriod selectedPeriod;
  final String groupId;
  final Function(DateTime startDate, DateTime endDate, String? eventId, AnalyticsPeriod period) onFilterChanged;

  const AnalyticsFilterWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.selectedEventId,
    required this.selectedPeriod,
    required this.groupId,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<AnalyticsFilterWidget> createState() => _AnalyticsFilterWidgetState();
}

class _AnalyticsFilterWidgetState extends ConsumerState<AnalyticsFilterWidget> {
  late DateTime _startDate;
  late DateTime _endDate;
  late String? _selectedEventId;
  late AnalyticsPeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedEventId = widget.selectedEventId;
    _selectedPeriod = widget.selectedPeriod;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Date Range Selection
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Quick Date Ranges
                _buildQuickDateRanges(),
                
                // Custom Date Range
                _buildCustomDateRange(),
                
                // Period Selection
                _buildPeriodSelection(),
                
                // Event Filter (placeholder - would need events provider)
                _buildEventFilter(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Apply Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateRanges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Ranges',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickRangeChip('Last 7 days', 7),
            _buildQuickRangeChip('Last 30 days', 30),
            _buildQuickRangeChip('Last 90 days', 90),
            _buildQuickRangeChip('Last 6 months', 180),
            _buildQuickRangeChip('Last year', 365),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickRangeChip(String label, int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final isSelected = _startDate.isAtSameMomentAs(startDate) && 
                     _endDate.day == endDate.day;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _startDate = startDate;
            _endDate = endDate;
          });
        }
      },
    );
  }

  Widget _buildCustomDateRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Range',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'From: ${_formatDate(_startDate)}',
                ),
                onPressed: () => _selectStartDate(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  'To: ${_formatDate(_endDate)}',
                ),
                onPressed: () => _selectEndDate(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Period',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AnalyticsPeriod>(
          value: _selectedPeriod,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: AnalyticsPeriod.values.map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(_getPeriodLabel(period)),
            );
          }).toList(),
          onChanged: (period) {
            if (period != null) {
              setState(() {
                _selectedPeriod = period;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildEventFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Filter',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _selectedEventId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: 'All Events',
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Events'),
            ),
            // TODO: Add actual events from provider
            // This would require implementing an events provider
          ],
          onChanged: (eventId) {
            setState(() {
              _selectedEventId = eventId;
            });
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getPeriodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return 'Daily';
      case AnalyticsPeriod.weekly:
        return 'Weekly';
      case AnalyticsPeriod.monthly:
        return 'Monthly';
      case AnalyticsPeriod.quarterly:
        return 'Quarterly';
      case AnalyticsPeriod.yearly:
        return 'Yearly';
      case AnalyticsPeriod.custom:
        return 'Custom';
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(const Duration(days: 30));
      _selectedEventId = null;
      _selectedPeriod = AnalyticsPeriod.monthly;
    });
  }

  void _applyFilters() {
    widget.onFilterChanged(_startDate, _endDate, _selectedEventId, _selectedPeriod);
  }
}