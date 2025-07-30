import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Modal widget for viewing PDF documents
class PDFViewerModal extends StatefulWidget {
  final String pdfUrl;

  const PDFViewerModal({
    super.key,
    required this.pdfUrl,
  });

  @override
  State<PDFViewerModal> createState() => _PDFViewerModalState();
}

class _PDFViewerModalState extends State<PDFViewerModal> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfController;

  @override
  void initState() {
    super.initState();
    _downloadAndCachePDF();
  }

  Future<void> _downloadAndCachePDF() async {
    try {
      // Download PDF to local storage for viewing
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/temp_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes);

        if (mounted) {
          setState(() {
            _localPath = file.path;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load PDF',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_localPath == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Column(
      children: [
        // PDF page indicator and controls
        if (_totalPages > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black.withOpacity(0.7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  tooltip: 'Previous page',
                ),
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
        // PDF viewer
        Expanded(
          child: PDFView(
            filePath: _localPath!,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              if (mounted) {
                setState(() {
                  _totalPages = pages ?? 0;
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _error = error.toString();
                });
              }
            },
            onPageError: (page, error) {
              if (mounted) {
                setState(() {
                  _error = 'Error on page $page: $error';
                });
              }
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _pdfController = pdfViewController;
            },
            onLinkHandler: (String? uri) {
              // Handle PDF links if needed
            },
            onPageChanged: (int? page, int? total) {
              if (mounted && page != null) {
                setState(() {
                  _currentPage = page;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  void _previousPage() {
    if (_pdfController != null && _currentPage > 0) {
      _pdfController!.setPage(_currentPage - 1);
    }
  }

  void _nextPage() {
    if (_pdfController != null && _currentPage < _totalPages - 1) {
      _pdfController!.setPage(_currentPage + 1);
    }
  }

  @override
  void dispose() {
    // Clean up temporary file
    if (_localPath != null) {
      try {
        File(_localPath!).delete();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    super.dispose();
  }
}
