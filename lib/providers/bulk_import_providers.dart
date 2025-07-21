import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bulk_import_service.dart';
import '../repositories/repository_providers.dart';

/// Provider for BulkImportService
final bulkImportServiceProvider = Provider<BulkImportService>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  
  return BulkImportServiceImpl(
    memberRepository: memberRepository,
  );
});