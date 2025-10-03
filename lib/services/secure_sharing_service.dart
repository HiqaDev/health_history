import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class SecureSharingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a secure share
  Future<Map<String, dynamic>> createSecureShare({
    required String resourceType,
    required String resourceId,
    required String shareWithEmail,
    required List<String> permissions,
    DateTime? expiresAt,
    String? message,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate secure access code
      final accessCode = _generateAccessCode();
      
      // Create share record
      final response = await _supabase.from('secure_shares').insert({
        'shared_by': user.id,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'share_with_email': shareWithEmail,
        'access_code': accessCode,
        'permissions': permissions,
        'expires_at': expiresAt?.toIso8601String(),
        'message': message,
        'is_active': true,
      }).select().single();

      // Generate shareable link
      final shareLink = _generateShareLink(accessCode);

      return {
        'share': response,
        'shareLink': shareLink,
        'accessCode': accessCode,
      };
    } catch (e) {
      throw Exception('Failed to create secure share: $e');
    }
  }

  // Get all shares created by current user
  Future<List<Map<String, dynamic>>> getMyShares() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('secure_shares')
          .select('''
            *,
            shared_by_profile:user_profiles!secure_shares_shared_by_fkey(
              full_name,
              profile_picture_url
            )
          ''')
          .eq('shared_by', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get shares: $e');
    }
  }

  // Get shares that have been shared with current user
  Future<List<Map<String, dynamic>>> getSharedWithMe() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userProfile = await _supabase
          .from('user_profiles')
          .select('email')
          .eq('id', user.id)
          .single();

      final response = await _supabase
          .from('secure_shares')
          .select('''
            *,
            shared_by_profile:user_profiles!secure_shares_shared_by_fkey(
              full_name,
              profile_picture_url
            )
          ''')
          .eq('share_with_email', userProfile['email'])
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get shared items: $e');
    }
  }

  // Access shared resource using access code
  Future<Map<String, dynamic>> accessSharedResource(String accessCode) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get share details
      final share = await _supabase
          .from('secure_shares')
          .select('''
            *,
            shared_by_profile:user_profiles!secure_shares_shared_by_fkey(
              full_name,
              profile_picture_url,
              email
            )
          ''')
          .eq('access_code', accessCode)
          .eq('is_active', true)
          .single();

      // Check if expired
      if (share['expires_at'] != null) {
        final expiryDate = DateTime.parse(share['expires_at']);
        if (DateTime.now().isAfter(expiryDate)) {
          throw Exception('Share link has expired');
        }
      }

      // Get the actual resource based on type
      Map<String, dynamic> resource = {};
      switch (share['resource_type']) {
        case 'medical_document':
          resource = await _getMedicalDocument(share['resource_id']);
          break;
        case 'health_event':
          resource = await _getHealthEvent(share['resource_id']);
          break;
        case 'medication':
          resource = await _getMedication(share['resource_id']);
          break;
        case 'timeline_event':
          resource = await _getTimelineEvent(share['resource_id']);
          break;
        case 'doctor_note':
          resource = await _getDoctorNote(share['resource_id']);
          break;
        case 'health_summary':
          resource = await _getHealthSummary(share['shared_by']);
          break;
        default:
          throw Exception('Unknown resource type');
      }

      // Record access
      await _recordAccess(share['id']);

      return {
        'share': share,
        'resource': resource,
      };
    } catch (e) {
      throw Exception('Failed to access shared resource: $e');
    }
  }

  // Update share status (activate/deactivate)
  Future<void> updateShareStatus(String shareId, bool isActive) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('secure_shares')
          .update({'is_active': isActive})
          .eq('id', shareId)
          .eq('shared_by', user.id);
    } catch (e) {
      throw Exception('Failed to update share status: $e');
    }
  }

  // Delete share
  Future<void> deleteShare(String shareId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('secure_shares')
          .delete()
          .eq('id', shareId)
          .eq('shared_by', user.id);
    } catch (e) {
      throw Exception('Failed to delete share: $e');
    }
  }

  // Get sharing statistics
  Future<Map<String, dynamic>> getSharingStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final myShares = await _supabase
          .from('secure_shares')
          .select('id, access_count, created_at')
          .eq('shared_by', user.id);

      final sharedWithMe = await _supabase
          .from('secure_shares')
          .select('id')
          .eq('share_with_email', user.email ?? '');

      final totalAccess = myShares.fold<int>(
        0,
        (sum, share) => sum + (share['access_count'] as int? ?? 0),
      );

      final activeShares = myShares.where((share) => 
        share['expires_at'] == null || 
        DateTime.parse(share['expires_at']).isAfter(DateTime.now())
      ).length;

      return {
        'totalShares': myShares.length,
        'activeShares': activeShares,
        'totalAccess': totalAccess,
        'receivedShares': sharedWithMe.length,
      };
    } catch (e) {
      throw Exception('Failed to get sharing stats: $e');
    }
  }

  // Generate QR code data for sharing
  Map<String, String> generateQRData(String accessCode) {
    final shareLink = _generateShareLink(accessCode);
    return {
      'type': 'health_share',
      'access_code': accessCode,
      'share_link': shareLink,
      'app': 'health_history',
    };
  }

  // Private helper methods
  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateShareLink(String accessCode) {
    // In production, this would be your app's deep link
    return 'https://healthhistory.app/share/$accessCode';
  }

  Future<Map<String, dynamic>> _getMedicalDocument(String documentId) async {
    return await _supabase
        .from('medical_documents')
        .select('*')
        .eq('id', documentId)
        .single();
  }

  Future<Map<String, dynamic>> _getHealthEvent(String eventId) async {
    return await _supabase
        .from('health_events')
        .select('*')
        .eq('id', eventId)
        .single();
  }

  Future<Map<String, dynamic>> _getMedication(String medicationId) async {
    return await _supabase
        .from('medications')
        .select('*')
        .eq('id', medicationId)
        .single();
  }

  Future<Map<String, dynamic>> _getTimelineEvent(String eventId) async {
    return await _supabase
        .from('timeline_events')
        .select('*')
        .eq('id', eventId)
        .single();
  }

  Future<Map<String, dynamic>> _getDoctorNote(String noteId) async {
    return await _supabase
        .from('doctor_notes')
        .select('''
          *,
          doctor:doctor_profiles!doctor_notes_doctor_id_fkey(
            full_name,
            specialization,
            license_number
          )
        ''')
        .eq('id', noteId)
        .single();
  }

  Future<Map<String, dynamic>> _getHealthSummary(String userId) async {
    // Compile a comprehensive health summary
    final profile = await _supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single();

    final emergencyContacts = await _supabase
        .from('emergency_contacts')
        .select('*')
        .eq('user_id', userId)
        .limit(2);

    final recentMedications = await _supabase
        .from('medications')
        .select('*')
        .eq('user_id', userId)
        .eq('is_active', true)
        .limit(5);

    final healthInsurance = await _supabase
        .from('health_insurance')
        .select('*')
        .eq('user_id', userId)
        .eq('is_active', true)
        .limit(1);

    final allergies = await _supabase
        .from('health_events')
        .select('*')
        .eq('user_id', userId)
        .eq('event_type', 'allergy')
        .limit(5);

    return {
      'profile': profile,
      'emergency_contacts': emergencyContacts,
      'current_medications': recentMedications,
      'insurance': healthInsurance.isNotEmpty ? healthInsurance.first : null,
      'allergies': allergies,
      'summary_generated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _recordAccess(String shareId) async {
    await _supabase.rpc('increment_access_count', params: {
      'share_id': shareId,
    });
  }
}