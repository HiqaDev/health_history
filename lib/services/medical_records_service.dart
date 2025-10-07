import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/health_service.dart';

class MedicalRecordsService {
  final SupabaseClient _client;
  final HealthService _healthService;

  MedicalRecordsService({SupabaseClient? client, HealthService? healthService})
      : _client = client ?? SupabaseService.instance.client,
        _healthService = healthService ?? HealthService();

  // File upload with enhanced categorization
  Future<Map<String, dynamic>> uploadMedicalFile({
    required String userId,
    required File file,
    required String title,
    required String fileCategory,
    required DateTime documentDate,
    String? description,
    String? doctorId,
    String? hospitalName,
    String? doctorName,
    String? department,
    List<String>? tags,
    bool isCritical = false,
    String? timelineEventId,
  }) async {
    try {
      // Generate unique file path
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = '$userId/medical-documents/$fileName';

      // Upload file to Supabase Storage
      final uploadResponse = await _client.storage
          .from('medical-documents')
          .upload(filePath, file);

      if (uploadResponse.isEmpty) {
        throw Exception('Failed to upload file');
      }

      // Get file size
      final fileSize = await file.length();
      final mimeType = _getMimeType(file.path);

      // Create document record aligned to 'medical_documents' schema
      final documentData = {
        'user_id': userId,
        'title': title,
        'description': description,
        'document_type': _mapCategoryToDocumentType(fileCategory),
        'file_path': filePath,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
        // 'tags' omitted to avoid unknown column on minimal schema
        'document_date': documentDate.toIso8601String().split('T')[0],
        'healthcare_provider': hospitalName ?? doctorName,
      };

      final documentResponse = await _healthService.uploadMedicalDocument(documentData);

      // Queue for offline sync
      await _healthService.queueForOfflineSync(
        userId: userId,
        tableName: 'medical_documents',
        recordId: documentResponse['id'],
        action: 'INSERT',
        data: documentData,
      );

      return documentResponse;
    } catch (error) {
      throw Exception('Failed to upload medical file: $error');
    }
  }

  // Get file download URL
  Future<String> getFileDownloadUrl(String filePath) async {
    try {
      // Buckets are private by default; create a short-lived signed URL
      final signed = await _client.storage
          .from('medical-documents')
          .createSignedUrl(filePath, 60 * 60); // 1 hour
      return signed;
    } catch (error) {
      throw Exception('Failed to get download URL: $error');
    }
  }

  // Get documents by category with filters
  Future<List<Map<String, dynamic>>> getDocumentsByCategory({
    required String userId,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    String? hospitalName,
    String? doctorName,
    bool? isCritical,
    List<String>? tags,
  }) async {
    try {
      var docs = await _healthService.getMedicalDocuments(userId);

      // Map DB schema to UI schema used by widgets/screens
      List<Map<String, dynamic>> documents = await Future.wait(docs.map((doc) async {
        final filePath = doc['file_path'] as String?;
        String? url;
        if (filePath != null && filePath.isNotEmpty) {
          url = await getFileDownloadUrl(filePath);
        }
    final dateString = (doc['date_of_document'] as String?)
      ?? (doc['document_date'] as String?)
      ?? (doc['created_at'] as String);
        return {
          'id': doc['id'] as String,
          'title': doc['title'] as String,
          'description': doc['description'],
          'type': _mapDocumentTypeToUi(doc['document_type'] as String),
          'date': dateString,
          'provider': doc['healthcare_provider'],
          'tags': (doc['tags'] as List?)?.cast<String>() ?? <String>[],
          'isFavorite': (doc['is_favorite'] as bool?) ?? false,
          'fileUrl': url,
        };
      }));

      // Apply additional filters
      if (fromDate != null) {
        final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
        documents = documents.where((doc) {
          DateTime docDate;
          try { docDate = DateTime.parse(doc['date']); } catch (_) { return false; }
          return !docDate.isBefore(start); // >= start of day
        }).toList();
      }

      if (toDate != null) {
        final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
        documents = documents.where((doc) {
          DateTime docDate;
          try { docDate = DateTime.parse(doc['date']); } catch (_) { return false; }
          return !docDate.isAfter(end); // <= end of day
        }).toList();
      }

      if (hospitalName != null) {
        documents = documents.where((doc) =>
            doc['provider']?.toString().toLowerCase().contains(hospitalName.toLowerCase()) == true
        ).toList();
      }

      if (doctorName != null) {
        // Fallback: if provider string contains doctor name
        documents = documents.where((doc) =>
            doc['provider']?.toString().toLowerCase().contains(doctorName.toLowerCase()) == true
        ).toList();
      }

      if (tags != null && tags.isNotEmpty) {
        documents = documents.where((doc) {
          final docTags = List<String>.from(doc['tags'] ?? []);
          return tags.any((tag) => docTags.contains(tag));
        }).toList();
      }

      return documents;
    } catch (error) {
      throw Exception('Failed to get documents by category: $error');
    }
  }

  // Search documents with full-text search
  Future<List<Map<String, dynamic>>> searchDocuments({
    required String userId,
    required String query,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var results = await _healthService.searchMedicalRecords(userId, query);

      // If a category filter is provided, first filter by the raw DB enum/type if present
      if (category != null) {
        final wanted = category.toLowerCase();
        results = results.where((doc) {
          final raw = (doc['document_type'] as String?)?.toLowerCase();
          if (raw != null && raw.isNotEmpty) {
            return raw == wanted || raw.contains(wanted);
          }
          return true; // if schema lacks type, don't exclude
        }).toList();
      }
      // Map to UI shape
      final mapped = await Future.wait(results.map((doc) async {
        final filePath = doc['file_path'] as String?;
        String? url;
        if (filePath != null && filePath.isNotEmpty) {
          url = await getFileDownloadUrl(filePath);
        }
    final dateString = (doc['date_of_document'] as String?)
      ?? (doc['document_date'] as String?)
      ?? (doc['created_at'] as String);
        return {
          'id': doc['id'] as String,
          'title': doc['title'] as String,
          'description': doc['description'],
          'type': _mapDocumentTypeToUi(doc['document_type'] as String),
          'rawType': (doc['document_type'] as String?)?.toLowerCase(),
          'date': dateString,
          'provider': doc['healthcare_provider'],
          'tags': (doc['tags'] as List?)?.cast<String>() ?? <String>[],
          'isFavorite': (doc['is_favorite'] as bool?) ?? false,
          'fileUrl': url,
        };
      }));

      // Apply optional filters locally
      List<Map<String, dynamic>> documents = mapped;
      if (category != null) {
        final wanted = category.toLowerCase();
        final expectedUi = _categoryIdToUiType(wanted);
        final beforeCount = documents.length;
        documents = documents.where((doc) {
          final uiType = (doc['type'] as String?)?.toLowerCase() ?? '';
          final raw = ((doc['rawType'] as String?) ?? '').toLowerCase();
          return raw == wanted || uiType == expectedUi;
        }).toList();
        if (documents.isEmpty && beforeCount > 0) {
          // Fallback: partial contains match to be more permissive
          documents = mapped.where((doc) {
            final uiType = (doc['type'] as String?)?.toLowerCase() ?? '';
            final raw = ((doc['rawType'] as String?) ?? '').toLowerCase();
            return raw.contains(wanted) || uiType.contains(expectedUi);
          }).toList();
        }
      }

      if (fromDate != null) {
        final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
        documents = documents.where((doc) {
          final docDate = DateTime.parse(doc['date']);
          return !docDate.isBefore(start);
        }).toList();
      }

      if (toDate != null) {
        final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
        documents = documents.where((doc) {
          final docDate = DateTime.parse(doc['date']);
          return !docDate.isAfter(end);
        }).toList();
      }

      return documents;
    } catch (error) {
      throw Exception('Failed to search documents: $error');
    }
  }

  String _categoryIdToUiType(String id) {
    switch (id) {
      case 'medical_image':
        return 'imaging';
      case 'lab_report':
        return 'lab report';
      case 'prescription':
        return 'prescription';
      case 'insurance':
        return 'insurance';
      case 'vaccination':
      case 'vaccination_record':
        return 'vaccination';
      default:
        return id;
    }
  }

  // Get critical documents for emergency access
  Future<List<Map<String, dynamic>>> getCriticalDocuments(String userId) async {
    try {
      return await _healthService.getMedicalDocuments(userId, isCritical: true);
    } catch (error) {
      throw Exception('Failed to get critical documents: $error');
    }
  }

  // Mark document as favorite
  Future<void> toggleDocumentFavorite(String documentId, bool isFavorite) async {
    try {
      await _client
          .from('medical_documents')
          .update({'is_favorite': isFavorite})
          .eq('id', documentId);
    } catch (error) {
      throw Exception('Failed to toggle document favorite: $error');
    }
  }

  // Update document tags
  Future<void> updateDocumentTags(String documentId, List<String> tags) async {
    try {
      await _client
          .from('medical_documents')
          .update({'tags': tags})
          .eq('id', documentId);
    } catch (error) {
      throw Exception('Failed to update document tags: $error');
    }
  }

  // Delete document
  Future<void> deleteDocument(String documentId, String filePath) async {
    try {
      // Delete file from storage
      await _client.storage
          .from('medical-documents')
          .remove([filePath]);

      // Delete document record
      await _client
          .from('medical_documents')
          .delete()
          .eq('id', documentId);
    } catch (error) {
      throw Exception('Failed to delete document: $error');
    }
  }

  // Get document statistics
  Future<Map<String, dynamic>> getDocumentStatistics(String userId) async {
    try {
  final documents = await _healthService.getMedicalDocuments(userId);
      
      final stats = <String, dynamic>{
        'total_documents': documents.length,
        'by_category': <String, int>{},
        'by_month': <String, int>{},
        'total_size_mb': 0.0,
        'critical_documents': 0,
        'recent_uploads': 0,
      };

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      for (final doc in documents) {
        // Count by category
  final category = _mapDocumentTypeToUi(doc['document_type'] as String);
  stats['by_category'][category] = (stats['by_category'][category] ?? 0) + 1;

    // Count by month
    final dateStr = (doc['date_of_document'] as String?)
      ?? (doc['document_date'] as String?)
      ?? (doc['created_at'] as String);
    final docDate = DateTime.parse(dateStr);
        final monthKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}';
        stats['by_month'][monthKey] = (stats['by_month'][monthKey] ?? 0) + 1;

        // Calculate total size
        if (doc['file_size'] != null) {
          stats['total_size_mb'] += (doc['file_size'] as int) / (1024 * 1024);
        }

        // Count critical documents
        // No critical flag in base schema; skip

    // Count recent uploads
    final createdAt = DateTime.parse(doc['created_at']);
        if (createdAt.isAfter(thirtyDaysAgo)) {
          stats['recent_uploads']++;
        }
      }

      // Round total size
      stats['total_size_mb'] = double.parse(stats['total_size_mb'].toStringAsFixed(2));

      return stats;
    } catch (error) {
      throw Exception('Failed to get document statistics: $error');
    }
  }

  // Helper method to determine MIME type
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'dcm':
        return 'application/dicom';
      default:
        return 'application/octet-stream';
    }
  }

  // Get supported file categories for Indian medical system
  List<Map<String, dynamic>> getSupportedCategories() {
    return [
      {
        'id': 'prescription',
        'name': 'Prescriptions',
        'icon': 'prescription',
        'color': '#4CAF50',
        'description': 'Doctor prescriptions and medication details'
      },
      {
        'id': 'lab_report',
        'name': 'Lab Reports',
        'icon': 'lab_results',
        'color': '#2196F3',
        'description': 'Blood tests, urine tests, and other laboratory results'
      },
      {
        'id': 'xray',
        'name': 'X-Rays',
        'icon': 'xray',
        'color': '#FF9800',
        'description': 'X-ray images and radiologist reports'
      },
      {
        'id': 'mri',
        'name': 'MRI Scans',
        'icon': 'mri',
        'color': '#9C27B0',
        'description': 'MRI images and radiology reports'
      },
      {
        'id': 'ct_scan',
        'name': 'CT Scans',
        'icon': 'ct_scan',
        'color': '#607D8B',
        'description': 'CT scan images and reports'
      },
      {
        'id': 'ultrasound',
        'name': 'Ultrasound',
        'icon': 'ultrasound',
        'color': '#795548',
        'description': 'Ultrasound images and sonography reports'
      },
      {
        'id': 'ecg',
        'name': 'ECG/EKG',
        'icon': 'heart_monitor',
        'color': '#F44336',
        'description': 'Electrocardiogram reports and heart monitoring'
      },
      {
        'id': 'bill',
        'name': 'Medical Bills',
        'icon': 'receipt',
        'color': '#4CAF50',
        'description': 'Hospital bills, pharmacy receipts, and invoices'
      },
      {
        'id': 'insurance',
        'name': 'Insurance',
        'icon': 'shield',
        'color': '#3F51B5',
        'description': 'Insurance policies, claims, and related documents'
      },
      {
        'id': 'vaccination_record',
        'name': 'Vaccination Records',
        'icon': 'vaccine',
        'color': '#009688',
        'description': 'Vaccination certificates and immunization records'
      },
      {
        'id': 'discharge_summary',
        'name': 'Discharge Summary',
        'icon': 'hospital',
        'color': '#673AB7',
        'description': 'Hospital discharge summaries and treatment plans'
      },
    ];
  }

  // Map app UI category to DB enum document_type
  String _mapCategoryToDocumentType(String category) {
    switch (category) {
      case 'prescription':
        return 'prescription';
      case 'lab_report':
        return 'lab_report';
      case 'insurance':
        return 'insurance';
      case 'vaccination_record':
        return 'vaccination';
      case 'xray':
      case 'mri':
      case 'ct_scan':
      case 'ultrasound':
      case 'ecg':
        return 'medical_image';
      case 'bill':
        return 'other';
      default:
        return 'other';
    }
  }

  // Map DB enum to UI friendly type labels used by widgets
  String _mapDocumentTypeToUi(String dbType) {
    switch (dbType) {
      case 'prescription':
        return 'Prescription';
      case 'lab_report':
        return 'Lab Report';
      case 'medical_image':
        return 'Imaging';
      case 'insurance':
        return 'Insurance';
      case 'vaccination':
        return 'Vaccination';
      default:
        return 'Document';
    }
  }

  String _mapUiTypeToCategoryId(String uiType) {
    switch (uiType.toLowerCase()) {
      case 'prescription':
        return 'prescription';
      case 'lab report':
        return 'lab_report';
      case 'imaging':
        // generic bucket for various image-like categories
        return 'medical_image';
      case 'insurance':
        return 'insurance';
      case 'vaccination':
        return 'vaccination_record';
      default:
        return 'other';
    }
  }
}