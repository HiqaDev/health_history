import '../services/health_service.dart';

class TimelineService {
  final _healthService = HealthService();

  // Get complete timeline with all events
  Future<List<Map<String, dynamic>>> getCompleteTimeline(String userId) async {
    try {
      final timelineEvents = await _healthService.getTimelineEvents(userId);
      final medications = await _healthService.getMedications(userId);
      final appointments = await _healthService.getAppointments(userId);
      final healthMetrics = await _healthService.getHealthMetrics(userId);

      // Combine all events into a unified timeline
      List<Map<String, dynamic>> allEvents = [];

      // Add timeline events
      for (final event in timelineEvents) {
        allEvents.add({
          'type': 'timeline_event',
          'id': event['id'],
          'title': event['title'],
          'description': event['description'],
          'date': DateTime.parse(event['event_date']),
          'event_type': event['event_type'],
          'doctor_name': event['doctor_profiles']?['full_name'],
          'hospital_name': event['hospital_name'],
          'department': event['department'],
          'is_critical': event['is_critical'] ?? false,
          'tags': List<String>.from(event['tags'] ?? []),
          'icon': _getEventIcon(event['event_type']),
          'color': _getEventColor(event['event_type']),
          'data': event,
        });
      }

      // Add medication events
      for (final medication in medications) {
        allEvents.add({
          'type': 'medication',
          'id': medication['id'],
          'title': 'Started ${medication['name']}',
          'description': '${medication['dosage']} - ${medication['frequency']}',
          'date': DateTime.parse(medication['start_date']),
          'event_type': 'medication_start',
          'doctor_name': medication['prescribing_doctor'],
          'is_critical': false,
          'icon': 'medication',
          'color': '#4CAF50',
          'data': medication,
        });

        // Add end date if medication is no longer active
        if (!medication['is_active'] && medication['end_date'] != null) {
          allEvents.add({
            'type': 'medication',
            'id': '${medication['id']}_end',
            'title': 'Stopped ${medication['name']}',
            'description': 'Medication discontinued',
            'date': DateTime.parse(medication['end_date']),
            'event_type': 'medication_end',
            'doctor_name': medication['prescribing_doctor'],
            'is_critical': false,
            'icon': 'medication_off',
            'color': '#FF5722',
            'data': medication,
          });
        }
      }

      // Add appointment events
      for (final appointment in appointments) {
        allEvents.add({
          'type': 'appointment',
          'id': appointment['id'],
          'title': appointment['title'],
          'description': appointment['description'],
          'date': DateTime.parse(appointment['appointment_date']),
          'event_type': 'appointment',
          'doctor_name': appointment['healthcare_provider'],
          'location': appointment['location'],
          'status': appointment['status'],
          'is_critical': false,
          'icon': 'calendar',
          'color': '#2196F3',
          'data': appointment,
        });
      }

      // Add significant health metric events (e.g., abnormal values)
      for (final metric in healthMetrics) {
        if (_isSignificantMetric(metric)) {
          allEvents.add({
            'type': 'health_metric',
            'id': metric['id'],
            'title': '${_getMetricDisplayName(metric['metric_type'])} Recorded',
            'description': '${metric['value']} ${metric['unit']}',
            'date': DateTime.parse(metric['recorded_at']),
            'event_type': 'health_metric',
            'is_critical': _isCriticalMetric(metric),
            'icon': _getMetricIcon(metric['metric_type']),
            'color': _getMetricColor(metric),
            'data': metric,
          });
        }
      }

      // Sort by date (most recent first)
      allEvents.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      return allEvents;
    } catch (error) {
      throw Exception('Failed to get complete timeline: $error');
    }
  }

  // Get timeline events filtered by type
  Future<List<Map<String, dynamic>>> getTimelineByType(
      String userId, String eventType) async {
    try {
      final completeTimeline = await getCompleteTimeline(userId);
      return completeTimeline
          .where((event) => event['event_type'] == eventType)
          .toList();
    } catch (error) {
      throw Exception('Failed to get timeline by type: $error');
    }
  }

  // Get timeline events within date range
  Future<List<Map<String, dynamic>>> getTimelineByDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final completeTimeline = await getCompleteTimeline(userId);
      return completeTimeline.where((event) {
        final eventDate = event['date'] as DateTime;
        return eventDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               eventDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (error) {
      throw Exception('Failed to get timeline by date range: $error');
    }
  }

  // Get timeline events by hospital/provider
  Future<List<Map<String, dynamic>>> getTimelineByProvider(
      String userId, String providerName) async {
    try {
      final completeTimeline = await getCompleteTimeline(userId);
      return completeTimeline.where((event) {
        final hospitalName = event['hospital_name']?.toString().toLowerCase();
        final doctorName = event['doctor_name']?.toString().toLowerCase();
        final searchTerm = providerName.toLowerCase();
        
        return (hospitalName?.contains(searchTerm) == true) ||
               (doctorName?.contains(searchTerm) == true);
      }).toList();
    } catch (error) {
      throw Exception('Failed to get timeline by provider: $error');
    }
  }

  // Search timeline events
  Future<List<Map<String, dynamic>>> searchTimeline(
      String userId, String query) async {
    try {
      final completeTimeline = await getCompleteTimeline(userId);
      final searchTerm = query.toLowerCase();
      
      return completeTimeline.where((event) {
        final title = event['title']?.toString().toLowerCase() ?? '';
        final description = event['description']?.toString().toLowerCase() ?? '';
        final tags = List<String>.from(event['tags'] ?? []);
        final tagString = tags.join(' ').toLowerCase();
        
        return title.contains(searchTerm) ||
               description.contains(searchTerm) ||
               tagString.contains(searchTerm);
      }).toList();
    } catch (error) {
      throw Exception('Failed to search timeline: $error');
    }
  }

  // Get critical events only
  Future<List<Map<String, dynamic>>> getCriticalEvents(String userId) async {
    try {
      final completeTimeline = await getCompleteTimeline(userId);
      return completeTimeline
          .where((event) => event['is_critical'] == true)
          .toList();
    } catch (error) {
      throw Exception('Failed to get critical events: $error');
    }
  }

  // Get recent events (last 30 days)
  Future<List<Map<String, dynamic>>> getRecentEvents(
      String userId, {int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      return await getTimelineByDateRange(userId, cutoffDate, DateTime.now());
    } catch (error) {
      throw Exception('Failed to get recent events: $error');
    }
  }

  // Get timeline statistics
  Future<Map<String, dynamic>> getTimelineStatistics(String userId) async {
    try {
      final completeTimeline = await getCompleteTimeline(userId);
      
      final stats = <String, dynamic>{
        'total_events': completeTimeline.length,
        'by_type': <String, int>{},
        'by_month': <String, int>{},
        'critical_events': 0,
        'recent_events': 0,
        'unique_providers': <String>{},
        'unique_hospitals': <String>{},
      };

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      for (final event in completeTimeline) {
        // Count by type
        final eventType = event['event_type'] as String;
        stats['by_type'][eventType] = (stats['by_type'][eventType] ?? 0) + 1;

        // Count by month
        final eventDate = event['date'] as DateTime;
        final monthKey = '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}';
        stats['by_month'][monthKey] = (stats['by_month'][monthKey] ?? 0) + 1;

        // Count critical events
        if (event['is_critical'] == true) {
          stats['critical_events']++;
        }

        // Count recent events
        if (eventDate.isAfter(thirtyDaysAgo)) {
          stats['recent_events']++;
        }

        // Track unique providers and hospitals
        if (event['doctor_name'] != null) {
          (stats['unique_providers'] as Set<String>).add(event['doctor_name']);
        }
        if (event['hospital_name'] != null) {
          (stats['unique_hospitals'] as Set<String>).add(event['hospital_name']);
        }
      }

      // Convert sets to counts
      stats['unique_providers'] = (stats['unique_providers'] as Set<String>).length;
      stats['unique_hospitals'] = (stats['unique_hospitals'] as Set<String>).length;

      return stats;
    } catch (error) {
      throw Exception('Failed to get timeline statistics: $error');
    }
  }

  // Helper methods for UI display
  String _getEventIcon(String eventType) {
    switch (eventType) {
      case 'diagnosis':
        return 'stethoscope';
      case 'treatment':
        return 'healing';
      case 'surgery':
        return 'surgical';
      case 'test':
        return 'lab_results';
      case 'vaccination':
        return 'vaccine';
      case 'hospital_visit':
        return 'hospital';
      case 'prescription':
        return 'prescription';
      case 'symptom':
        return 'warning';
      default:
        return 'medical_information';
    }
  }

  String _getEventColor(String eventType) {
    switch (eventType) {
      case 'diagnosis':
        return '#F44336'; // Red
      case 'treatment':
        return '#4CAF50'; // Green
      case 'surgery':
        return '#9C27B0'; // Purple
      case 'test':
        return '#2196F3'; // Blue
      case 'vaccination':
        return '#009688'; // Teal
      case 'hospital_visit':
        return '#FF9800'; // Orange
      case 'prescription':
        return '#4CAF50'; // Green
      case 'symptom':
        return '#FF5722'; // Deep Orange
      default:
        return '#607D8B'; // Blue Grey
    }
  }

  String _getMetricIcon(String metricType) {
    switch (metricType) {
      case 'blood_pressure':
        return 'heart_pulse';
      case 'weight':
        return 'scale';
      case 'blood_sugar':
        return 'glucose';
      case 'heart_rate':
        return 'heart_rate';
      case 'temperature':
        return 'thermometer';
      case 'cholesterol':
        return 'cholesterol';
      case 'bmi':
        return 'body_composition';
      default:
        return 'health_metrics';
    }
  }

  String _getMetricColor(Map<String, dynamic> metric) {
    // Implement logic to determine if metric is normal, warning, or critical
    // This would be based on normal ranges for each metric type
    if (_isCriticalMetric(metric)) {
      return '#F44336'; // Red for critical
    } else if (_isWarningMetric(metric)) {
      return '#FF9800'; // Orange for warning
    } else {
      return '#4CAF50'; // Green for normal
    }
  }

  String _getMetricDisplayName(String metricType) {
    switch (metricType) {
      case 'blood_pressure':
        return 'Blood Pressure';
      case 'weight':
        return 'Weight';
      case 'blood_sugar':
        return 'Blood Sugar';
      case 'heart_rate':
        return 'Heart Rate';
      case 'temperature':
        return 'Temperature';
      case 'cholesterol':
        return 'Cholesterol';
      case 'bmi':
        return 'BMI';
      default:
        return metricType.replaceAll('_', ' ').toUpperCase();
    }
  }

  bool _isSignificantMetric(Map<String, dynamic> metric) {
    // Only include metrics that are outside normal ranges or manually marked as significant
    return _isCriticalMetric(metric) || _isWarningMetric(metric);
  }

  bool _isCriticalMetric(Map<String, dynamic> metric) {
    final type = metric['metric_type'] as String;
    final value = metric['value'] as num;
    
    // Define critical ranges for Indian population (you may want to make this configurable)
    switch (type) {
      case 'blood_pressure':
        // Systolic > 180 or < 90, Diastolic > 120 or < 60
        final unit = metric['unit'] as String;
        if (unit.contains('systolic')) {
          return value > 180 || value < 90;
        } else if (unit.contains('diastolic')) {
          return value > 120 || value < 60;
        }
        break;
      case 'blood_sugar':
        // Critical if > 300 mg/dL or < 70 mg/dL
        return value > 300 || value < 70;
      case 'heart_rate':
        // Critical if > 120 bpm or < 50 bpm
        return value > 120 || value < 50;
      case 'temperature':
        // Critical if > 39°C or < 35°C
        return value > 39 || value < 35;
      default:
        return false;
    }
    return false;
  }

  bool _isWarningMetric(Map<String, dynamic> metric) {
    final type = metric['metric_type'] as String;
    final value = metric['value'] as num;
    
    // Define warning ranges
    switch (type) {
      case 'blood_pressure':
        final unit = metric['unit'] as String;
        if (unit.contains('systolic')) {
          return (value >= 140 && value <= 180) || (value >= 90 && value < 120);
        } else if (unit.contains('diastolic')) {
          return (value >= 90 && value <= 120) || (value >= 60 && value < 80);
        }
        break;
      case 'blood_sugar':
        // Warning if 140-300 mg/dL or 70-100 mg/dL
        return (value >= 140 && value <= 300) || (value >= 70 && value < 100);
      case 'heart_rate':
        // Warning if 100-120 bpm or 50-60 bpm
        return (value >= 100 && value <= 120) || (value >= 50 && value < 60);
      default:
        return false;
    }
    return false;
  }

  // Get available event types for filtering
  List<Map<String, dynamic>> getEventTypes() {
    return [
      {'id': 'diagnosis', 'name': 'Diagnosis', 'icon': 'stethoscope', 'color': '#F44336'},
      {'id': 'treatment', 'name': 'Treatment', 'icon': 'healing', 'color': '#4CAF50'},
      {'id': 'surgery', 'name': 'Surgery', 'icon': 'surgical', 'color': '#9C27B0'},
      {'id': 'test', 'name': 'Tests', 'icon': 'lab_results', 'color': '#2196F3'},
      {'id': 'vaccination', 'name': 'Vaccination', 'icon': 'vaccine', 'color': '#009688'},
      {'id': 'hospital_visit', 'name': 'Hospital Visit', 'icon': 'hospital', 'color': '#FF9800'},
      {'id': 'prescription', 'name': 'Prescription', 'icon': 'prescription', 'color': '#4CAF50'},
      {'id': 'symptom', 'name': 'Symptom', 'icon': 'warning', 'color': '#FF5722'},
      {'id': 'appointment', 'name': 'Appointment', 'icon': 'calendar', 'color': '#2196F3'},
      {'id': 'medication_start', 'name': 'Medication Started', 'icon': 'medication', 'color': '#4CAF50'},
      {'id': 'medication_end', 'name': 'Medication Stopped', 'icon': 'medication_off', 'color': '#FF5722'},
      {'id': 'health_metric', 'name': 'Health Metric', 'icon': 'health_metrics', 'color': '#607D8B'},
    ];
  }
}