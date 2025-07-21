import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Log levels for categorizing log entries
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  critical(4);

  const LogLevel(this.value);
  final int value;

  bool operator >=(LogLevel other) => value >= other.value;
}

/// Log entry model
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? category;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final String? userId;
  final String? sessionId;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.category,
    this.error,
    this.stackTrace,
    this.context,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'category': category,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      category: json['category'],
      error: json['error'],
      stackTrace: json['stackTrace'] != null 
          ? StackTrace.fromString(json['stackTrace'])
          : null,
      context: json['context']?.cast<String, dynamic>(),
      userId: json['userId'],
      sessionId: json['sessionId'],
    );
  }
}

/// Comprehensive logging system for the Ngage platform
class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  final List<LogEntry> _localLogs = [];
  final StreamController<LogEntry> _logStreamController = StreamController<LogEntry>.broadcast();
  
  LogLevel _minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  String? _currentUserId;
  String? _currentSessionId;
  bool _enableRemoteLogging = true;
  bool _enableLocalStorage = true;
  int _maxLocalLogs = 1000;

  /// Stream of log entries for real-time monitoring
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Get recent log entries
  List<LogEntry> get recentLogs => List.unmodifiable(_localLogs);

  /// Configure logger settings
  void configure({
    LogLevel? minimumLevel,
    String? userId,
    String? sessionId,
    bool? enableRemoteLogging,
    bool? enableLocalStorage,
    int? maxLocalLogs,
  }) {
    if (minimumLevel != null) _minimumLevel = minimumLevel;
    if (userId != null) _currentUserId = userId;
    if (sessionId != null) _currentSessionId = sessionId;
    if (enableRemoteLogging != null) _enableRemoteLogging = enableRemoteLogging;
    if (enableLocalStorage != null) _enableLocalStorage = enableLocalStorage;
    if (maxLocalLogs != null) _maxLocalLogs = maxLocalLogs;
  }

  /// Log debug message
  void debug(
    String message, {
    String? category,
    Map<String, dynamic>? context,
  }) {
    _log(LogLevel.debug, message, category: category, context: context);
  }

  /// Log info message
  void info(
    String message, {
    String? category,
    Map<String, dynamic>? context,
  }) {
    _log(LogLevel.info, message, category: category, context: context);
  }

  /// Log warning message
  void warning(
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      LogLevel.warning,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log error message
  void error(
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      LogLevel.error,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log critical error message
  void critical(
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      LogLevel.critical,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (level.value < _minimumLevel.value) return;

    final entry = LogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      category: category,
      error: error,
      stackTrace: stackTrace,
      context: context,
      userId: _currentUserId,
      sessionId: _currentSessionId,
    );

    // Add to local storage
    if (_enableLocalStorage) {
      _addToLocalStorage(entry);
    }

    // Send to stream
    _logStreamController.add(entry);

    // Console output in debug mode
    if (kDebugMode) {
      _printToConsole(entry);
    }

    // Remote logging
    if (_enableRemoteLogging && level >= LogLevel.warning) {
      _sendToRemoteLogging(entry);
    }
  }

  /// Add log entry to local storage
  void _addToLocalStorage(LogEntry entry) {
    _localLogs.add(entry);
    
    // Maintain maximum log count
    while (_localLogs.length > _maxLocalLogs) {
      _localLogs.removeAt(0);
    }
  }

  /// Print log entry to console
  void _printToConsole(LogEntry entry) {
    final category = entry.category != null ? '[${entry.category}] ' : '';
    
    developer.log(
      '$category${entry.message}',
      time: entry.timestamp,
      level: entry.level.value,
      name: 'Ngage',
      error: entry.error,
      stackTrace: entry.stackTrace,
    );
  }

  /// Send log entry to remote logging service
  Future<void> _sendToRemoteLogging(LogEntry entry) async {
    try {
      // Only log errors and critical issues to Firestore to avoid quota issues
      if (entry.level >= LogLevel.error) {
        await FirebaseFirestore.instance
            .collection('logs')
            .doc(entry.id)
            .set(entry.toJson());
      }
    } catch (e) {
      // Silently fail remote logging to avoid infinite loops
      if (kDebugMode) {
        developer.log('Failed to send log to remote: $e');
      }
    }
  }

  /// Generate unique log ID
  String _generateLogId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_localLogs.length}';
  }

  /// Clear local logs
  void clearLocalLogs() {
    _localLogs.clear();
  }

  /// Get logs by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _localLogs.where((log) => log.level == level).toList();
  }

  /// Get logs by category
  List<LogEntry> getLogsByCategory(String category) {
    return _localLogs.where((log) => log.category == category).toList();
  }

  /// Get logs by time range
  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _localLogs
        .where((log) => 
            log.timestamp.isAfter(start) && log.timestamp.isBefore(end))
        .toList();
  }

  /// Export logs as JSON
  String exportLogsAsJson() {
    return jsonEncode(_localLogs.map((log) => log.toJson()).toList());
  }

  /// Dispose resources
  void dispose() {
    _logStreamController.close();
  }
}