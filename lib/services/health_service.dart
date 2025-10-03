import '../services/supabase_service.dart';

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
}