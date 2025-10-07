import 'package:flutter_test/flutter_test.dart';
import 'package:health_history/services/health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _HealthServiceSpy extends HealthService {
  Map<String, dynamic>? lastInserted;
  final List<Map<String, dynamic>> insertCalls = [];
  final bool simulateMissingDateColumn;

  _HealthServiceSpy({required SupabaseClient client, this.simulateMissingDateColumn = false}) : super(client: client);

  @override
  Future<Map<String, dynamic>> insertMedicalDocument(Map<String, dynamic> document) async {
    lastInserted = document;
    insertCalls.add(document);
    if (simulateMissingDateColumn && document.containsKey('date_of_document')) {
      // Simulate Postgres undefined column error code 42703 by throwing PostgrestException
      throw PostgrestException(message: 'column medical_documents.date_of_document does not exist', code: '42703', details: null, hint: null);
    }
    return {'id': 'doc_1', ...document};
  }
}

void main() {
  group('HealthService.uploadMedicalDocument', () {
    late SupabaseClient dummyClient;

    setUp(() {
      dummyClient = SupabaseClient('http://localhost', 'anon');
    });

    test('inserts as-is when schema supports date_of_document', () async {
      final spy = _HealthServiceSpy(client: dummyClient);
      final service = spy as HealthService;

      final doc = {'title': 'CBC', 'date_of_document': '2025-10-01'};
      final res = await service.uploadMedicalDocument(doc);

      expect(spy.lastInserted, isNotNull);
      expect(spy.lastInserted!['date_of_document'], '2025-10-01');
      expect(res['id'], 'doc_1');
    });

    test('removes date_of_document on 42703 and retries', () async {
      final spy = _HealthServiceSpy(client: dummyClient, simulateMissingDateColumn: true);
      final service = spy as HealthService;

      final doc = {'title': 'CBC', 'date_of_document': '2025-10-01'};
      final res = await service.uploadMedicalDocument(doc);

      // Two insert attempts expected
      expect(spy.insertCalls.length, 2);
      expect(spy.insertCalls.first.containsKey('date_of_document'), true, reason: 'first attempt includes field');
      expect(spy.insertCalls.last.containsKey('date_of_document'), false, reason: 'second attempt removes field');
      expect(res['id'], 'doc_1');
    });
  });
}
