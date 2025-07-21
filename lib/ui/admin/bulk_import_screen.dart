import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/bulk_import.dart';
import '../../providers/bulk_import_providers.dart';

/// Screen for bulk member import functionality
class BulkImportScreen extends ConsumerStatefulWidget {
  const BulkImportScreen({super.key});

  @override
  ConsumerState<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends ConsumerState<BulkImportScreen> {
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  ImportValidationResult? _validationResult;
  ImportResult? _importResult;
  bool _isValidating = false;
  bool _isImporting = false;
  int _importProgress = 0;
  int _importTotal = 0;
  String _currentOperation = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Member Import'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionsCard(),
            const SizedBox(height: 16),
            _buildFileSelectionCard(),
            if (_selectedFileBytes != null) ...[
              const SizedBox(height: 16),
              _buildValidationCard(),
            ],
            if (_validationResult != null) ...[
              const SizedBox(height: 16),
              _buildValidationResultsCard(),
            ],
            if (_importResult != null) ...[
              const SizedBox(height: 16),
              _buildImportResultsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Import Instructions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Prepare a CSV file with member data\n'
              '2. Required columns: email, first_name, last_name\n'
              '3. Optional columns: phone, external_id, category, title\n'
              '4. First row should contain column headers\n'
              '5. Email addresses must be unique',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadTemplate,
                  icon: const Icon(Icons.download),
                  label: const Text('Download Template'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _showExpectedHeaders,
                  icon: const Icon(Icons.list),
                  label: const Text('View Headers'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select CSV File',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedFileName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFileName!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _clearSelectedFile,
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove file',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_selectedFileName == null ? 'Select CSV File' : 'Select Different File'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isValidating) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Validating import data...'),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _validateData,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Validate Data'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationResultsCard() {
    final result = _validationResult!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isValid ? Icons.check_circle : Icons.error,
                  color: result.isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Validation Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildValidationSummary(result),
            if (result.hasErrors) ...[
              const SizedBox(height: 16),
              _buildErrorsList(result.errors),
            ],
            if (result.hasWarnings) ...[
              const SizedBox(height: 16),
              _buildWarningsList(result.warnings),
            ],
            if (result.isValid && result.validMembers.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _startImport,
                  icon: _isImporting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isImporting ? 'Importing...' : 'Start Import'),
                ),
              ),
              if (_isImporting) ...[
                const SizedBox(height: 12),
                _buildImportProgress(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationSummary(ImportValidationResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Total Processed', result.totalProcessed.toString()),
          _buildSummaryRow('Valid Members', result.validMembers.length.toString()),
          if (result.hasErrors)
            _buildSummaryRow('Errors', result.errors.length.toString(), Colors.red),
          if (result.hasWarnings)
            _buildSummaryRow('Warnings', result.warnings.length.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsList(List<ImportError> errors) {
    return ExpansionTile(
      title: Text('Errors (${errors.length})'),
      leading: const Icon(Icons.error, color: Colors.red),
      children: [
        ...errors.take(10).map((error) => ListTile(
          dense: true,
          leading: const Icon(Icons.error_outline, color: Colors.red, size: 16),
          title: Text(error.toString()),
          subtitle: error.memberData != null 
              ? Text('${error.memberData!.firstName} ${error.memberData!.lastName} (${error.memberData!.email})')
              : null,
        )),
        if (errors.length > 10)
          ListTile(
            dense: true,
            title: Text('... and ${errors.length - 10} more errors'),
          ),
      ],
    );
  }

  Widget _buildWarningsList(List<ImportWarning> warnings) {
    return ExpansionTile(
      title: Text('Warnings (${warnings.length})'),
      leading: const Icon(Icons.warning, color: Colors.orange),
      children: [
        ...warnings.take(10).map((warning) => ListTile(
          dense: true,
          leading: const Icon(Icons.warning_outlined, color: Colors.orange, size: 16),
          title: Text(warning.toString()),
          subtitle: Text('${warning.memberData.firstName} ${warning.memberData.lastName} (${warning.memberData.email})'),
        )),
        if (warnings.length > 10)
          ListTile(
            dense: true,
            title: Text('... and ${warnings.length - 10} more warnings'),
          ),
      ],
    );
  }

  Widget _buildImportProgress() {
    final progress = _importTotal > 0 ? _importProgress / _importTotal : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
        Text(
          '$_currentOperation ($_importProgress / $_importTotal)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildImportResultsCard() {
    final result = _importResult!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isSuccessful ? Icons.check_circle : Icons.warning,
                  color: result.isSuccessful ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Import Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildImportSummary(result),
            if (result.hasErrors) ...[
              const SizedBox(height: 16),
              _buildImportErrorsList(result.errors),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _resetImport,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Import More'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSummary(ImportResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Total Processed', result.totalProcessed.toString()),
          _buildSummaryRow('Successful', result.successfulImports.toString(), Colors.green),
          if (result.failedImports > 0)
            _buildSummaryRow('Failed', result.failedImports.toString(), Colors.red),
          _buildSummaryRow('Success Rate', '${(result.successRate * 100).toStringAsFixed(1)}%'),
          _buildSummaryRow('Processing Time', '${result.processingTime.inMilliseconds}ms'),
        ],
      ),
    );
  }

  Widget _buildImportErrorsList(List<ImportError> errors) {
    return ExpansionTile(
      title: Text('Import Errors (${errors.length})'),
      leading: const Icon(Icons.error, color: Colors.red),
      children: [
        ...errors.take(10).map((error) => ListTile(
          dense: true,
          leading: const Icon(Icons.error_outline, color: Colors.red, size: 16),
          title: Text(error.toString()),
        )),
        if (errors.length > 10)
          ListTile(
            dense: true,
            title: Text('... and ${errors.length - 10} more errors'),
          ),
      ],
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFileBytes = file.bytes;
          _selectedFileName = file.name;
          _validationResult = null;
          _importResult = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select file: $e');
    }
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
      _validationResult = null;
      _importResult = null;
    });
  }

  Future<void> _validateData() async {
    if (_selectedFileBytes == null) return;

    setState(() {
      _isValidating = true;
      _validationResult = null;
    });

    try {
      final bulkImportService = ref.read(bulkImportServiceProvider);
      
      // Parse CSV file
      final importData = await bulkImportService.parseCsvFile(
        _selectedFileBytes!,
        fileName: _selectedFileName,
      );
      
      // Validate data
      final validationResult = await bulkImportService.validateImportData(importData);
      
      setState(() {
        _validationResult = validationResult;
      });
      
    } catch (e) {
      _showErrorSnackBar('Validation failed: $e');
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _startImport() async {
    final validationResult = _validationResult;
    if (validationResult == null || !validationResult.isValid) return;

    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = validationResult.validMembers.length;
      _currentOperation = 'Starting import...';
    });

    try {
      final bulkImportService = ref.read(bulkImportServiceProvider);
      
      final importResult = await bulkImportService.importMembers(
        validationResult.validMembers,
        onProgress: (processed, total, operation) {
          setState(() {
            _importProgress = processed;
            _importTotal = total;
            _currentOperation = operation;
          });
        },
      );
      
      setState(() {
        _importResult = importResult;
      });
      
      if (importResult.isSuccessful) {
        _showSuccessSnackBar('Import completed successfully!');
      } else {
        _showWarningSnackBar('Import completed with ${importResult.failedImports} errors');
      }
      
    } catch (e) {
      _showErrorSnackBar('Import failed: $e');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  void _resetImport() {
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
      _validationResult = null;
      _importResult = null;
      _isValidating = false;
      _isImporting = false;
      _importProgress = 0;
      _importTotal = 0;
      _currentOperation = '';
    });
  }

  void _downloadTemplate() {
    final bulkImportService = ref.read(bulkImportServiceProvider);
    final csvData = bulkImportService.getSampleCsvData();
    
    // In a real app, you would trigger a download here
    // For now, show the template data in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Template'),
        content: SingleChildScrollView(
          child: Text(
            csvData,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExpectedHeaders() {
    final bulkImportService = ref.read(bulkImportServiceProvider);
    final headers = bulkImportService.getExpectedHeaders();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expected CSV Headers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Required headers:'),
            const Text('• email'),
            const Text('• first_name'),
            const Text('• last_name'),
            const SizedBox(height: 12),
            const Text('Optional headers:'),
            ...headers.where((h) => !['email', 'first_name', 'last_name'].contains(h))
                .map((h) => Text('• $h')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}