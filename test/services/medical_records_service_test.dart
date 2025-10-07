import 'package:flutter_test/flutter_test.dart';
import 'package:health_history/services/medical_records_service.dart';
import 'package:health_history/services/health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeHealthService extends HealthService {
  final List<Map<String, dynamic>> _docs;
  final List<Map<String, dynamic>> _search;

  _FakeHealthService({required SupabaseClient client, List<Map<String, dynamic>>? docs, List<Map<String, dynamic>>? search})
      : _docs = docs ?? const [],
        _search = search ?? const [],
        super(client: client);

  @override
  Future<List<Map<String, dynamic>>> getMedicalDocuments(String userId, {String? category, bool? isCritical}) async {
    return _docs;
  }

  @override
  Future<List<Map<String, dynamic>>> searchMedicalRecords(String userId, String query) async {
    return _search;
  }
}

void main() {
  group('MedicalRecordsService mapping and filters', () {
    late SupabaseClient dummyClient;

    setUp(() {
      // Dummy client; not used in these tests because file_path is empty so no storage calls.
      dummyClient = SupabaseClient('http://localhost', 'anon-key');
    });

    test('getDocumentsByCategory maps fields and applies date/provider filters', () async {
      final docs = [
        {
          'id': '1',
          'title': 'CBC Report',
          'description': 'Full blood count',
          'document_type': 'lab_report',
          'file_path': '',
          'file_name': 'cbc.pdf',
          'file_size': 1048576,
          'mime_type': 'application/pdf',
          'tags': ['blood', 'cbc'],
          'date_of_document': '2025-10-05',
          'healthcare_provider': 'Apollo Hospital',
          'is_favorite': false,
          'created_at': '2025-10-06T12:34:56Z',
        },
        {
          'id': '2',
          'title': 'X-Ray Chest',
          'document_type': 'medical_image',
          'file_path': '',
          'file_name': 'xray.jpg',
          'file_size': 512000,
          'mime_type': 'image/jpeg',
          'tags': [],
          // missing date_of_document -> fallback to created_at
          'healthcare_provider': 'City Hospital',
          'is_favorite': true,
          'created_at': '2025-09-30T10:00:00Z',
        },
        {
          'id': '3',
          'title': 'Prescription',
          'document_type': 'prescription',
          'file_path': '',
          'file_name': 'rx.pdf',
          'file_size': 256000,
          'mime_type': 'application/pdf',
          'tags': ['meds'],
          'date_of_document': '2025-09-29',
          'healthcare_provider': 'Dr. Kumar Clinic',
          'is_favorite': false,
          'created_at': '2025-09-29T08:00:00Z',
        },
      ];

      final fakeHealth = _FakeHealthService(client: dummyClient, docs: docs);
      final service = MedicalRecordsService(client: dummyClient, healthService: fakeHealth);

      // Filter from 2025-10-01 should include only doc1 (CBC Report)
      final fromDate = DateTime(2025, 10, 1);
      final mapped = await service.getDocumentsByCategory(userId: 'u1', fromDate: fromDate);

      expect(mapped.length, 1);
      final d1 = mapped.first;
      expect(d1['title'], 'CBC Report');
      expect(d1['type'], 'Lab Report');
      expect(d1['date'], '2025-10-05'); // uses date_of_document over created_at
      expect(d1['provider'], contains('Apollo'));

      // Provider filter (case-insensitive)
      final apolloOnly = await service.getDocumentsByCategory(userId: 'u1', hospitalName: 'apollo');
      expect(apolloOnly.length, 1);
      expect(apolloOnly.first['title'], 'CBC Report');

      // Verify mapping of imaging type
      final all = await service.getDocumentsByCategory(userId: 'u1');
      final imaging = all.firstWhere((e) => e['title'] == 'X-Ray Chest', orElse: () => {});
      expect(imaging['type'], 'Imaging');
      expect(imaging['date'], '2025-09-30T10:00:00Z'); // fallback to created_at
    });

    test('searchDocuments maps fields and applies category/date filters', () async {
      final search = [
        {
          'id': '2',
          'title': 'X-Ray Chest',
          'document_type': 'medical_image',
          'file_path': '',
          'created_at': '2025-09-30T10:00:00Z',
          'healthcare_provider': 'City Hospital',
        },
        {
          'id': '3',
          'title': 'Prescription',
          'document_type': 'prescription',
          'file_path': '',
          'date_of_document': '2025-09-29',
          'created_at': '2025-09-29T08:00:00Z',
          'healthcare_provider': 'Dr. Kumar Clinic',
        },
      ];

      final fakeHealth = _FakeHealthService(client: dummyClient, docs: const [], search: search);
      final service = MedicalRecordsService(client: dummyClient, healthService: fakeHealth);

  // Confirm mapping produces UI type 'Imaging' for medical_image
  final allResults = await service.searchDocuments(userId: 'u1', query: 'x');
  expect(allResults.length, 2);
  expect(allResults.any((e) => e['type'] == 'Imaging'), true);

  // Filter by category id 'medical_image' should keep only imaging
  final results = await service.searchDocuments(userId: 'u1', query: 'x', category: 'medical_image');
  // Debug print to inspect filtering behavior
  // ignore: avoid_print
  print('Filtered results: ' + results.toString());
  expect(results.isNotEmpty, true);
  expect(results.first['rawType'], 'medical_image');

      // Date filters
      final fromDate = DateTime(2025, 9, 30);
      final toDate = DateTime(2025, 9, 30);
  final dateFiltered = await service.searchDocuments(userId: 'u1', query: 'x', fromDate: fromDate, toDate: toDate);
  expect(dateFiltered.any((e) => e['date'] == '2025-09-30T10:00:00Z'), true);
    });

    test('getDocumentStatistics aggregates correctly with date fallbacks', () async {
      final now = DateTime.now();
      final docs = [
        {
          'id': '1',
          'title': 'CBC',
          'document_type': 'lab_report',
          'file_size': 1048576, // 1 MB
          'date_of_document': now.toIso8601String().split('T')[0],
          'created_at': now.toIso8601String(),
        },
        {
          'id': '2',
          'title': 'X-Ray',
          'document_type': 'medical_image',
          'file_size': 512000, // ~0.49 MB
          // no date_of_document
          'created_at': now.subtract(const Duration(days: 40)).toIso8601String(),
        },
        {
          'id': '3',
          'title': 'RX',
          'document_type': 'prescription',
          // size null
          'date_of_document': now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
          'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
      ];

      final fakeHealth = _FakeHealthService(client: dummyClient, docs: docs);
      final service = MedicalRecordsService(client: dummyClient, healthService: fakeHealth);

      final stats = await service.getDocumentStatistics('u1');
      expect(stats['total_documents'], 3);
      expect(stats['by_category']['Lab Report'], 1);
      expect(stats['by_category']['Imaging'], 1);
      expect(stats['by_category']['Prescription'], 1);

      // by_month should have entries for current month and for 40-days-ago month
      expect((stats['by_month'] as Map).isNotEmpty, true);

      // total_size_mb rounded to 2 decimals (~1.49)
      final totalSize = stats['total_size_mb'] as double;
      expect(totalSize > 1.48 && totalSize < 1.5, true);

      // recent_uploads should be at least 2 (now and now-1)
      expect(stats['recent_uploads'] >= 2, true);
    });
  });
}
