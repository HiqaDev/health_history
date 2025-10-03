import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:math';

class QRCodeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Generate emergency QR code data
  Future<Map<String, dynamic>> generateEmergencyQRCode() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user profile and emergency data
      final userProfile = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      final emergencyContacts = await _supabase
          .from('emergency_contacts')
          .select('*')
          .eq('user_id', user.id)
          .order('priority')
          .limit(3);

      final criticalMedications = await _supabase
          .from('medications')
          .select('*')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .eq('is_critical', true)
          .limit(5);

      final allergies = await _supabase
          .from('health_events')
          .select('*')
          .eq('user_id', user.id)
          .eq('event_type', 'allergy')
          .order('event_date', ascending: false)
          .limit(5);

      final medicalAlerts = await _supabase
          .from('health_events')
          .select('*')
          .eq('user_id', user.id)
          .inFilter('event_type', ['medical_alert', 'chronic_condition'])
          .order('event_date', ascending: false)
          .limit(3);

      final healthInsurance = await _supabase
          .from('health_insurance')
          .select('*')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .single();

      // Generate unique QR code ID
      final qrCodeId = _generateQRCodeId();

      // Prepare emergency data
      final emergencyData = {
        'type': 'emergency_health_data',
        'version': '1.0',
        'generated_at': DateTime.now().toIso8601String(),
        'qr_code_id': qrCodeId,
        'patient': {
          'name': userProfile['full_name'],
          'age': _calculateAge(userProfile['date_of_birth']),
          'blood_group': userProfile['blood_group'],
          'gender': userProfile['gender'],
          'phone': userProfile['phone_number'],
        },
        'emergency_contacts': emergencyContacts.map((contact) => {
          'name': contact['name'],
          'relationship': contact['relationship'],
          'phone': contact['phone_number'],
          'is_primary': contact['is_primary'] ?? false,
        }).toList(),
        'medical_info': {
          'allergies': allergies.map((allergy) => {
            'allergen': allergy['description'],
            'severity': allergy['severity'],
            'reaction': allergy['notes'],
          }).toList(),
          'critical_medications': criticalMedications.map((med) => {
            'name': med['medication_name'],
            'dosage': med['dosage'],
            'frequency': med['frequency'],
            'purpose': med['purpose'],
          }).toList(),
          'medical_alerts': medicalAlerts.map((alert) => {
            'condition': alert['description'],
            'severity': alert['severity'],
            'notes': alert['notes'],
          }).toList(),
        },
        'insurance': healthInsurance != null ? {
          'provider': healthInsurance['provider_name'],
          'policy_number': healthInsurance['policy_number'],
          'scheme_type': healthInsurance['scheme_type'],
        } : null,
        'emergency_instructions': _getEmergencyInstructions(),
      };

      // Store QR code in database
      final qrRecord = await _supabase.from('qr_codes').insert({
        'user_id': user.id,
        'qr_code_id': qrCodeId,
        'qr_type': 'emergency',
        'data': emergencyData,
        'is_active': true,
        'expires_at': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      }).select().single();

      return {
        'qr_data': jsonEncode(emergencyData),
        'qr_record': qrRecord,
        'display_data': emergencyData,
      };
    } catch (e) {
      throw Exception('Failed to generate emergency QR code: $e');
    }
  }

  // Generate medical summary QR code
  Future<Map<String, dynamic>> generateMedicalSummaryQRCode({
    required List<String> includeTypes,
    int? expiryDays = 30,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final qrCodeId = _generateQRCodeId();
      Map<String, dynamic> summaryData = {
        'type': 'medical_summary',
        'version': '1.0',
        'generated_at': DateTime.now().toIso8601String(),
        'qr_code_id': qrCodeId,
        'expires_at': DateTime.now().add(Duration(days: expiryDays!)).toIso8601String(),
      };

      // Include different types of medical data based on selection
      if (includeTypes.contains('profile')) {
        final profile = await _supabase
            .from('user_profiles')
            .select('*')
            .eq('id', user.id)
            .single();
        summaryData['profile'] = {
          'name': profile['full_name'],
          'age': _calculateAge(profile['date_of_birth']),
          'blood_group': profile['blood_group'],
          'height': profile['height'],
          'weight': profile['weight'],
        };
      }

      if (includeTypes.contains('medications')) {
        final medications = await _supabase
            .from('medications')
            .select('*')
            .eq('user_id', user.id)
            .eq('is_active', true)
            .limit(10);
        summaryData['medications'] = medications;
      }

      if (includeTypes.contains('allergies')) {
        final allergies = await _supabase
            .from('health_events')
            .select('*')
            .eq('user_id', user.id)
            .eq('event_type', 'allergy')
            .limit(10);
        summaryData['allergies'] = allergies;
      }

      if (includeTypes.contains('conditions')) {
        final conditions = await _supabase
            .from('health_events')
            .select('*')
            .eq('user_id', user.id)
            .inFilter('event_type', ['chronic_condition', 'diagnosis'])
            .limit(10);
        summaryData['conditions'] = conditions;
      }

      if (includeTypes.contains('vaccinations')) {
        final vaccinations = await _supabase
            .from('vaccinations')
            .select('*')
            .eq('user_id', user.id)
            .order('vaccination_date', ascending: false)
            .limit(10);
        summaryData['vaccinations'] = vaccinations;
      }

      // Store QR code
      final qrRecord = await _supabase.from('qr_codes').insert({
        'user_id': user.id,
        'qr_code_id': qrCodeId,
        'qr_type': 'medical_summary',
        'data': summaryData,
        'is_active': true,
        'expires_at': expiryDays != null 
            ? DateTime.now().add(Duration(days: expiryDays)).toIso8601String()
            : null,
      }).select().single();

      return {
        'qr_data': jsonEncode(summaryData),
        'qr_record': qrRecord,
        'display_data': summaryData,
      };
    } catch (e) {
      throw Exception('Failed to generate medical summary QR code: $e');
    }
  }

  // Scan and decode QR code
  Future<Map<String, dynamic>> scanQRCode(String qrData) async {
    try {
      final decodedData = jsonDecode(qrData);
      
      if (decodedData['type'] == 'emergency_health_data' || 
          decodedData['type'] == 'medical_summary') {
        // Verify QR code exists and is active
        final qrRecord = await _supabase
            .from('qr_codes')
            .select('*')
            .eq('qr_code_id', decodedData['qr_code_id'])
            .eq('is_active', true)
            .single();

        // Check expiry
        if (qrRecord['expires_at'] != null) {
          final expiryDate = DateTime.parse(qrRecord['expires_at']);
          if (DateTime.now().isAfter(expiryDate)) {
            throw Exception('QR code has expired');
          }
        }

        // Log scan
        await _logQRScan(qrRecord['id']);

        return {
          'is_valid': true,
          'data': decodedData,
          'scanned_at': DateTime.now().toIso8601String(),
        };
      } else {
        throw Exception('Invalid QR code format');
      }
    } catch (e) {
      return {
        'is_valid': false,
        'error': 'Invalid or expired QR code: $e',
      };
    }
  }

  // Get user's QR codes
  Future<List<Map<String, dynamic>>> getUserQRCodes() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final qrCodes = await _supabase
          .from('qr_codes')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(qrCodes);
    } catch (e) {
      throw Exception('Failed to get QR codes: $e');
    }
  }

  // Update QR code status
  Future<void> updateQRCodeStatus(String qrCodeId, bool isActive) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('qr_codes')
          .update({'is_active': isActive})
          .eq('qr_code_id', qrCodeId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to update QR code status: $e');
    }
  }

  // Delete QR code
  Future<void> deleteQRCode(String qrCodeId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('qr_codes')
          .delete()
          .eq('qr_code_id', qrCodeId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete QR code: $e');
    }
  }

  // Get QR code statistics
  Future<Map<String, dynamic>> getQRCodeStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final stats = await _supabase
          .from('qr_codes')
          .select('id, qr_type, scan_count, is_active, created_at')
          .eq('user_id', user.id);

      final totalCodes = stats.length;
      final activeCodes = stats.where((qr) => qr['is_active'] == true).length;
      final totalScans = stats.fold<int>(0, (sum, qr) => sum + (qr['scan_count'] as int? ?? 0));
      final emergencyCodes = stats.where((qr) => qr['qr_type'] == 'emergency').length;
      final summaryCodes = stats.where((qr) => qr['qr_type'] == 'medical_summary').length;

      return {
        'total_codes': totalCodes,
        'active_codes': activeCodes,
        'total_scans': totalScans,
        'emergency_codes': emergencyCodes,
        'summary_codes': summaryCodes,
      };
    } catch (e) {
      throw Exception('Failed to get QR code statistics: $e');
    }
  }

  // Private helper methods
  String _generateQRCodeId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  int _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 0;
    final birthDate = DateTime.parse(dateOfBirth);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  List<String> _getEmergencyInstructions() {
    return [
      'Call 102 for medical emergency in India',
      'Show this QR code to medical professionals',
      'Contact emergency contacts listed above',
      'Check for medical alerts and allergies',
      'Verify critical medications before treatment',
    ];
  }

  Future<void> _logQRScan(String qrRecordId) async {
    try {
      // Increment scan count
      await _supabase.rpc('increment_qr_scan_count', params: {
        'qr_record_id': qrRecordId,
      });
    } catch (e) {
      // Log error but don't fail the scan
      print('Failed to log QR scan: $e');
    }
  }


}