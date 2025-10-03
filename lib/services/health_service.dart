import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HealthService {
  final _client = SupabaseService.instance.client;

  // Health Metrics Operations
  Future<List<Map<String, dynamic>>> getHealthMetrics(String userId) async {
    try {
      final response = await _client
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch health metrics: $error');
    }
  }

  Future<Map<String, dynamic>> addHealthMetric(
      Map<String, dynamic> metric) async {
    try {
      final response =
          await _client.from('health_metrics').insert(metric).select().single();

      return response;
    } catch (error) {
      throw Exception('Failed to add health metric: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getLatestMetricsByType(
      String userId) async {
    try {
      final response = await _client
          .rpc('get_latest_health_metrics', params: {'user_uuid': userId});

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      // Fallback query if RPC doesn't exist
      final response = await _client
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false);

      // Group by metric type and get latest
      Map<String, Map<String, dynamic>> latestMetrics = {};
      for (var metric in response) {
        String type = metric['metric_type'];
        if (!latestMetrics.containsKey(type)) {
          latestMetrics[type] = metric;
        }
      }

      return latestMetrics.values.toList();
    }
  }

  // Medications Operations
  Future<List<Map<String, dynamic>>> getMedications(String userId,
      {bool activeOnly = true}) async {
    try {
      var query = _client.from('medications').select().eq('user_id', userId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch medications: $error');
    }
  }

  Future<Map<String, dynamic>> addMedication(
      Map<String, dynamic> medication) async {
    try {
      final response = await _client
          .from('medications')
          .insert(medication)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add medication: $error');
    }
  }

  Future<Map<String, dynamic>> updateMedication(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await _client
          .from('medications')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update medication: $error');
    }
  }

  // Appointments Operations
  Future<List<Map<String, dynamic>>> getAppointments(String userId) async {
    try {
      final response = await _client
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch appointments: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingAppointments(String userId,
      {int limit = 5}) async {
    try {
      final response = await _client
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .gte('appointment_date', DateTime.now().toIso8601String())
          .eq('status', 'scheduled')
          .order('appointment_date', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch upcoming appointments: $error');
    }
  }

  Future<Map<String, dynamic>> addAppointment(
      Map<String, dynamic> appointment) async {
    try {
      final response = await _client
          .from('appointments')
          .insert(appointment)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add appointment: $error');
    }
  }

  // Health Events Operations
  Future<List<Map<String, dynamic>>> getHealthEvents(String userId,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('health_events')
          .select('*, medical_documents(*)')
          .eq('user_id', userId)
          .order('event_date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch health events: $error');
    }
  }

  Future<Map<String, dynamic>> addHealthEvent(
      Map<String, dynamic> event) async {
    try {
      final response =
          await _client.from('health_events').insert(event).select().single();

      return response;
    } catch (error) {
      throw Exception('Failed to add health event: $error');
    }
  }

  // Emergency Access Methods
  Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    try {
      final response = await _client
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch emergency contacts: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getCriticalMedicalInfo(String userId) async {
    try {
      // Get health events that are marked as critical
      final response = await _client
          .from('health_events')
          .select()
          .eq('user_id', userId)
          .eq('event_type', 'condition')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch critical medical info: $error');
    }
  }

  // Emergency Contacts Operations
  Future<Map<String, dynamic>?> getPrimaryEmergencyContact(
      String userId) async {
    try {
      final response = await _client
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .eq('is_primary', true)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (error) {
      throw Exception('Failed to fetch primary emergency contact: $error');
    }
  }

  // Dashboard Analytics
  Future<Map<String, dynamic>> getDashboardStats(String userId) async {
    try {
      final metricsCount = await _client
          .from('health_metrics')
          .select('id')
          .eq('user_id', userId)
          .count();

      final activemedications = await _client
          .from('medications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .count();

      final upcomingAppointments = await _client
          .from('appointments')
          .select('id')
          .eq('user_id', userId)
          .gte('appointment_date', DateTime.now().toIso8601String())
          .eq('status', 'scheduled')
          .count();

      final documentsCount = await _client
          .from('medical_documents')
          .select('id')
          .eq('user_id', userId)
          .count();

      return {
        'total_metrics': metricsCount.count ?? 0,
        'active_medications': activemedications.count ?? 0,
        'upcoming_appointments': upcomingAppointments.count ?? 0,
        'total_documents': documentsCount.count ?? 0,
      };
    } catch (error) {
      throw Exception('Failed to fetch dashboard stats: $error');
    }
  }

  // Recent Activity
  Future<List<Map<String, dynamic>>> getRecentActivity(String userId,
      {int limit = 10}) async {
    try {
      final recentMetrics = await _client
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(3);

      final recentEvents = await _client
          .from('health_events')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(3);

      final recentDocuments = await _client
          .from('medical_documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(3);

      List<Map<String, dynamic>> activities = [];

      // Add metrics to activities
      for (var metric in recentMetrics) {
        activities.add({
          'type': 'metric',
          'title': '${metric['metric_type']} recorded',
          'description': '${metric['value']} ${metric['unit']}',
          'timestamp': metric['recorded_at'],
          'icon': 'trending_up',
        });
      }

      // Add events to activities
      for (var event in recentEvents) {
        activities.add({
          'type': 'event',
          'title': event['title'],
          'description': event['description'] ?? '',
          'timestamp': event['created_at'],
          'icon': 'event',
        });
      }

      // Add documents to activities
      for (var doc in recentDocuments) {
        activities.add({
          'type': 'document',
          'title': 'Document added',
          'description': doc['title'],
          'timestamp': doc['created_at'],
          'icon': 'description',
        });
      }

      // Sort by timestamp and limit
      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      return activities.take(limit).toList();
    } catch (error) {
      throw Exception('Failed to fetch recent activity: $error');
    }
  }

  // ===== ENHANCED METHODS FOR INDIAN HEALTH APP =====

  // Timeline Events Operations
  Future<List<Map<String, dynamic>>> getTimelineEvents(String userId) async {
    try {
      final response = await _client
          .from('timeline_events')
          .select('''
            *, 
            doctor_profiles!doctor_id(full_name, specialization),
            medical_documents_enhanced!related_document_ids(title, file_category)
          ''')
          .eq('user_id', userId)
          .order('event_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch timeline events: $error');
    }
  }

  Future<Map<String, dynamic>> addTimelineEvent(
      Map<String, dynamic> event) async {
    try {
      final response = await _client
          .from('timeline_events')
          .insert(event)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add timeline event: $error');
    }
  }

  // Medical Documents Enhanced Operations
  Future<List<Map<String, dynamic>>> getMedicalDocuments(String userId,
      {String? category, bool? isCritical}) async {
    try {
      var query = _client
          .from('medical_documents_enhanced')
          .select('''
            *, 
            doctor_profiles!doctor_id(full_name, specialization),
            timeline_events!timeline_event_id(title, event_date)
          ''')
          .eq('user_id', userId);

      if (category != null) {
        query = query.eq('file_category', category);
      }
      if (isCritical != null) {
        query = query.eq('is_critical', isCritical);
      }

      final response = await query.order('document_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch medical documents: $error');
    }
  }

  Future<Map<String, dynamic>> uploadMedicalDocument(
      Map<String, dynamic> document) async {
    try {
      final response = await _client
          .from('medical_documents_enhanced')
          .insert(document)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to upload medical document: $error');
    }
  }

  // QR Code Operations
  Future<String> createEmergencyQRCode(String userId) async {
    try {
      final response = await _client
          .rpc('create_emergency_qr', params: {'user_uuid': userId});
      
      return response as String;
    } catch (error) {
      throw Exception('Failed to create emergency QR code: $error');
    }
  }

  Future<Map<String, dynamic>?> getQRCodeData(String accessCode) async {
    try {
      final response = await _client
          .from('qr_codes')
          .select('qr_data')
          .eq('access_code', accessCode)
          .eq('is_active', true)
          .single();

      // Update view count
      await _client
          .from('qr_codes')
          .update({
            'view_count': SupabaseQueryBuilder.raw('view_count + 1'),
            'last_accessed_at': DateTime.now().toIso8601String()
          })
          .eq('access_code', accessCode);

      return response['qr_data'] as Map<String, dynamic>;
    } catch (error) {
      return null; // QR code not found or expired
    }
  }

  // Reminders Operations
  Future<List<Map<String, dynamic>>> getActiveReminders(String userId) async {
    try {
      final response = await _client
          .from('reminders')
          .select('''
            *, 
            medications!related_medication_id(name, dosage),
            appointments!related_appointment_id(title, appointment_date)
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('scheduled_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch reminders: $error');
    }
  }

  Future<Map<String, dynamic>> createReminder(
      Map<String, dynamic> reminder) async {
    try {
      final response = await _client
          .from('reminders')
          .insert(reminder)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create reminder: $error');
    }
  }

  Future<void> markReminderCompleted(String reminderId) async {
    try {
      await _client
          .from('reminders')
          .update({
            'is_completed': true,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', reminderId);
    } catch (error) {
      throw Exception('Failed to mark reminder completed: $error');
    }
  }

  // Doctor Notes Operations
  Future<List<Map<String, dynamic>>> getDoctorNotes(String patientId) async {
    try {
      final response = await _client
          .from('doctor_notes')
          .select('''
            *, 
            doctor_profiles!doctor_id(full_name, specialization),
            timeline_events!timeline_event_id(title, event_type)
          ''')
          .eq('patient_id', patientId)
          .eq('is_shared_with_patient', true)
          .order('visit_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch doctor notes: $error');
    }
  }

  // Vaccination Records Operations
  Future<List<Map<String, dynamic>>> getVaccinations(String userId) async {
    try {
      final response = await _client
          .from('vaccinations')
          .select()
          .eq('user_id', userId)
          .order('administered_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch vaccinations: $error');
    }
  }

  Future<Map<String, dynamic>> addVaccination(
      Map<String, dynamic> vaccination) async {
    try {
      final response = await _client
          .from('vaccinations')
          .insert(vaccination)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add vaccination: $error');
    }
  }

  // Health Insurance Operations
  Future<List<Map<String, dynamic>>> getHealthInsurance(String userId) async {
    try {
      final response = await _client
          .from('health_insurance')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch health insurance: $error');
    }
  }

  // Secure Sharing Operations
  Future<String> createSecureShare({
    required String userId,
    required String sharingType,
    required Map<String, dynamic> sharedData,
    String? sharedWithEmail,
    String? doctorId,
    DateTime? expiresAt,
    int? maxAccessCount,
    String? purpose,
  }) async {
    try {
      // Generate unique access code
      String accessCode;
      do {
        accessCode = _generateAccessCode();
      } while (await _accessCodeExists(accessCode));

      final shareData = {
        'shared_by': userId,
        'sharing_type': sharingType,
        'shared_data': sharedData,
        'access_code': accessCode,
        'shared_with_email': sharedWithEmail,
        'shared_with_doctor_id': doctorId,
        'expires_at': expiresAt?.toIso8601String(),
        'max_access_count': maxAccessCount,
        'purpose': purpose,
      };

      await _client.from('secure_shares').insert(shareData);
      return accessCode;
    } catch (error) {
      throw Exception('Failed to create secure share: $error');
    }
  }

  Future<Map<String, dynamic>?> getSecureShare(String accessCode) async {
    try {
      final response = await _client
          .from('secure_shares')
          .select()
          .eq('access_code', accessCode)
          .eq('is_active', true)
          .single();

      // Check if expired or max access reached
      final share = response;
      if (share['expires_at'] != null &&
          DateTime.parse(share['expires_at']).isBefore(DateTime.now())) {
        return null; // Expired
      }
      if (share['max_access_count'] != null &&
          share['current_access_count'] >= share['max_access_count']) {
        return null; // Max access reached
      }

      // Update access count
      await _client
          .from('secure_shares')
          .update({
            'current_access_count': SupabaseQueryBuilder.raw('current_access_count + 1'),
          })
          .eq('access_code', accessCode);

      return share;
    } catch (error) {
      return null;
    }
  }

  // Offline Sync Operations
  Future<void> queueForOfflineSync({
    required String userId,
    required String tableName,
    required String recordId,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _client.from('offline_sync').insert({
        'user_id': userId,
        'table_name': tableName,
        'record_id': recordId,
        'action': action,
        'data': data,
      });
    } catch (error) {
      // Silent fail for offline sync
      print('Failed to queue for offline sync: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems(String userId) async {
    try {
      final response = await _client
          .from('offline_sync')
          .select()
          .eq('user_id', userId)
          .eq('sync_status', 'pending')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch pending sync items: $error');
    }
  }

  // Search Operations
  Future<List<Map<String, dynamic>>> searchMedicalRecords(
      String userId, String query) async {
    try {
      final response = await _client
          .from('medical_documents_enhanced')
          .select()
          .eq('user_id', userId)
          .textSearch('title,description,ocr_text', query);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to search medical records: $error');
    }
  }

  // Helper methods
  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    for (int i = 0; i < 8; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }

  Future<bool> _accessCodeExists(String accessCode) async {
    try {
      final response = await _client
          .from('secure_shares')
          .select('id')
          .eq('access_code', accessCode)
          .limit(1);
      return response.isNotEmpty;
    } catch (error) {
      return false;
    }
  }
}