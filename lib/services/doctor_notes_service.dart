import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorNotesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new doctor note
  Future<Map<String, dynamic>?> createDoctorNote({
    required String patientId,
    required String doctorId,
    String? timelineEventId,
    required DateTime visitDate,
    String? chiefComplaint,
    String? historyOfPresentIllness,
    String? physicalExamination,
    String? assessment,
    String? plan,
    String? voiceNoteUrl,
    bool isSharedWithPatient = true,
  }) async {
    try {
      final response = await _supabase.from('doctor_notes').insert({
        'patient_id': patientId,
        'doctor_id': doctorId,
        'timeline_event_id': timelineEventId,
        'visit_date': visitDate.toIso8601String().split('T')[0],
        'chief_complaint': chiefComplaint,
        'history_of_present_illness': historyOfPresentIllness,
        'physical_examination': physicalExamination,
        'assessment': assessment,
        'plan': plan,
        'voice_note_url': voiceNoteUrl,
        'is_shared_with_patient': isSharedWithPatient,
      }).select().single();

      return response;
    } catch (e) {
      print('Error creating doctor note: $e');
      return null;
    }
  }

  // Get doctor notes for a patient (patient's perspective)
  Future<List<Map<String, dynamic>>> getPatientNotes(String patientId) async {
    try {
      final response = await _supabase
          .from('doctor_notes')
          .select('''
            *,
            doctor_profiles:doctor_id (
              id,
              medical_license_number,
              specialization,
              qualification
            ),
            timeline_events:timeline_event_id (
              id,
              title,
              event_type,
              hospital_name
            )
          ''')
          .eq('patient_id', patientId)
          .eq('is_shared_with_patient', true)
          .order('visit_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching patient notes: $e');
      return [];
    }
  }

  // Get doctor notes created by a specific doctor (doctor's perspective)
  Future<List<Map<String, dynamic>>> getDoctorNotes(String doctorId) async {
    try {
      final response = await _supabase
          .from('doctor_notes')
          .select('''
            *,
            user_profiles:patient_id (
              id,
              full_name,
              date_of_birth,
              blood_group
            ),
            timeline_events:timeline_event_id (
              id,
              title,
              event_type,
              hospital_name
            )
          ''')
          .eq('doctor_id', doctorId)
          .order('visit_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching doctor notes: $e');
      return [];
    }
  }

  // Update an existing doctor note
  Future<Map<String, dynamic>?> updateDoctorNote({
    required String noteId,
    String? chiefComplaint,
    String? historyOfPresentIllness,
    String? physicalExamination,
    String? assessment,
    String? plan,
    String? voiceNoteUrl,
    bool? isSharedWithPatient,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (chiefComplaint != null) updateData['chief_complaint'] = chiefComplaint;
      if (historyOfPresentIllness != null) updateData['history_of_present_illness'] = historyOfPresentIllness;
      if (physicalExamination != null) updateData['physical_examination'] = physicalExamination;
      if (assessment != null) updateData['assessment'] = assessment;
      if (plan != null) updateData['plan'] = plan;
      if (voiceNoteUrl != null) updateData['voice_note_url'] = voiceNoteUrl;
      if (isSharedWithPatient != null) updateData['is_shared_with_patient'] = isSharedWithPatient;

      final response = await _supabase
          .from('doctor_notes')
          .update(updateData)
          .eq('id', noteId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error updating doctor note: $e');
      return null;
    }
  }

  // Get a specific doctor note by ID
  Future<Map<String, dynamic>?> getDoctorNoteById(String noteId) async {
    try {
      final response = await _supabase
          .from('doctor_notes')
          .select('''
            *,
            user_profiles:patient_id (
              id,
              full_name,
              date_of_birth,
              blood_group,
              allergies,
              medical_conditions
            ),
            doctor_profiles:doctor_id (
              id,
              medical_license_number,
              specialization,
              qualification,
              hospital_affiliations
            ),
            timeline_events:timeline_event_id (
              id,
              title,
              event_type,
              event_date,
              hospital_name,
              department
            )
          ''')
          .eq('id', noteId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching doctor note: $e');
      return null;
    }
  }

  // Search doctor notes by content
  Future<List<Map<String, dynamic>>> searchDoctorNotes({
    required String userId,
    required String query,
    bool isDoctor = false,
  }) async {
    try {
      var baseQuery = _supabase
          .from('doctor_notes')
          .select('''
            *,
            user_profiles:patient_id (
              id,
              full_name
            ),
            doctor_profiles:doctor_id (
              id,
              medical_license_number,
              specialization,
              qualification
            )
          ''');

      // Apply user filter based on role
      if (isDoctor) {
        baseQuery = baseQuery.eq('doctor_id', userId);
      } else {
        baseQuery = baseQuery.eq('patient_id', userId).eq('is_shared_with_patient', true);
      }

      // Apply text search
      final response = await baseQuery
          .or('chief_complaint.ilike.%$query%,history_of_present_illness.ilike.%$query%,physical_examination.ilike.%$query%,assessment.ilike.%$query%,plan.ilike.%$query%')
          .order('visit_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching doctor notes: $e');
      return [];
    }
  }

  // Upload voice note to storage
  Future<String?> uploadVoiceNote({
    required String noteId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final voiceNoteStorage = _supabase.storage.from('voice-notes');
      
      final fileExt = fileName.split('.').last;
      final storageFileName = '${noteId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      await voiceNoteStorage.upload(storageFileName, File(filePath));
      
      final publicUrl = voiceNoteStorage.getPublicUrl(storageFileName);
      
      // Update the doctor note with voice note URL
      await updateDoctorNote(noteId: noteId, voiceNoteUrl: publicUrl);
      
      return publicUrl;
    } catch (e) {
      print('Error uploading voice note: $e');
      return null;
    }
  }

  // Delete voice note
  Future<bool> deleteVoiceNote(String noteId, String voiceNoteUrl) async {
    try {
      // Extract file name from URL
      final fileName = voiceNoteUrl.split('/').last;
      
      // Delete from storage
      await _supabase.storage.from('voice-notes').remove([fileName]);
      
      // Remove URL from doctor note
      await updateDoctorNote(noteId: noteId, voiceNoteUrl: null);
      
      return true;
    } catch (e) {
      print('Error deleting voice note: $e');
      return false;
    }
  }

  // Get notes statistics for a doctor
  Future<Map<String, dynamic>> getDoctorNotesStatistics(String doctorId) async {
    try {
      final response = await _supabase
          .from('doctor_notes')
          .select('id, visit_date, patient_id')
          .eq('doctor_id', doctorId);

      final notes = List<Map<String, dynamic>>.from(response);
      
      final totalNotes = notes.length;
      final uniquePatients = notes.map((note) => note['patient_id']).toSet().length;
      
      // Calculate notes in last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentNotes = notes.where((note) {
        final visitDate = DateTime.parse(note['visit_date']);
        return visitDate.isAfter(thirtyDaysAgo);
      }).length;

      return {
        'total_notes': totalNotes,
        'unique_patients': uniquePatients,
        'recent_notes_30_days': recentNotes,
        'average_notes_per_patient': uniquePatients > 0 ? (totalNotes / uniquePatients).toStringAsFixed(1) : '0',
      };
    } catch (e) {
      print('Error getting doctor notes statistics: $e');
      return {
        'total_notes': 0,
        'unique_patients': 0,
        'recent_notes_30_days': 0,
        'average_notes_per_patient': '0',
      };
    }
  }

  // Get patient visit history with notes
  Future<List<Map<String, dynamic>>> getPatientVisitHistory(String patientId) async {
    try {
      final response = await _supabase
          .from('doctor_notes')
          .select('''
            *,
            doctor_profiles:doctor_id (
              id,
              medical_license_number,
              specialization,
              qualification
            )
          ''')
          .eq('patient_id', patientId)
          .eq('is_shared_with_patient', true)
          .order('visit_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching patient visit history: $e');
      return [];
    }
  }

  // Share/unshare note with patient
  Future<bool> toggleNoteSharing(String noteId, bool shareWithPatient) async {
    try {
      await _supabase
          .from('doctor_notes')
          .update({'is_shared_with_patient': shareWithPatient})
          .eq('id', noteId);
      
      return true;
    } catch (e) {
      print('Error toggling note sharing: $e');
      return false;
    }
  }
}