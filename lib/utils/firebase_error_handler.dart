import 'package:flutter/material.dart';
import '../ui/widgets/selectable_error_message.dart';
import 'firestore_index_helper.dart';

/// Utility class for handling Firebase errors
class FirebaseErrorHandler {
  /// Shows a dialog with a selectable error message for Firebase errors
  static void showFirebaseErrorDialog(BuildContext context, Object error) {
    final errorMessage = error.toString();
    
    // Check if this is a Firestore index error
    if (isFirebaseIndexError(errorMessage)) {
      FirestoreIndexHelper.showIndexCreationDialog(context, errorMessage);
      return;
    }
    
    // Show regular Firebase error dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Error'),
        content: SizedBox(
          width: double.maxFinite,
          child: SelectableErrorMessage(
            message: errorMessage,
            title: 'Error Details',
            backgroundColor: Colors.orange,
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

  /// Shows a snackbar with a selectable error message for Firebase errors
  static void showFirebaseErrorSnackbar(BuildContext context, Object error) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text('Firebase Error: Tap to view details')),
        ],
      ),
      action: SnackBarAction(
        label: 'View',
        onPressed: () {
          showFirebaseErrorDialog(context, error);
        },
      ),
      duration: const Duration(seconds: 10),
      backgroundColor: Colors.orange,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Determines if an error is a Firebase index error
  static bool isFirebaseIndexError(String errorMessage) {
    return errorMessage.contains('FAILED_PRECONDITION') && 
           errorMessage.contains('index') && 
           errorMessage.contains('firestore');
  }

  /// Extracts the index creation command from a Firebase index error
  static String? extractIndexCreationCommand(String errorMessage) {
    if (!isFirebaseIndexError(errorMessage)) return null;
    
    // Try to extract the command between backticks or based on common patterns
    final RegExp commandRegex = RegExp(r'`(.*?)`');
    final match = commandRegex.firstMatch(errorMessage);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    
    return null;
  }
}