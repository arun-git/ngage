import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper class for handling Firestore index creation
class FirestoreIndexHelper {
  /// Extracts the index creation command from a Firestore error message
  static String? extractIndexCommand(String errorMessage) {
    // Check if this is an index error
    if (!errorMessage.contains('FAILED_PRECONDITION') || 
        !errorMessage.contains('index') || 
        !errorMessage.contains('firestore')) {
      return null;
    }
    
    // Try to extract the Firebase console URL
    final RegExp urlRegex = RegExp(r'https://console\.firebase\.google\.com/[^\s]+');
    final urlMatch = urlRegex.firstMatch(errorMessage);
    
    if (urlMatch != null) {
      return urlMatch.group(0);
    }
    
    return null;
  }
  
  /// Shows a dialog with instructions for creating a Firestore index
  static void showIndexCreationDialog(BuildContext context, String errorMessage) {
    final indexUrl = extractIndexCommand(errorMessage);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firestore Index Required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This operation requires a Firestore index to be created. You can:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('1. Copy the error message and create the index manually'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                child: SelectableText(
                  errorMessage,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (indexUrl != null) ...[
                const Text('2. Click the button below to open the Firebase console'),
                const SizedBox(height: 8),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final Uri url = Uri.parse(indexUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Firebase Console'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: errorMessage));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error message copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copy Error'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}