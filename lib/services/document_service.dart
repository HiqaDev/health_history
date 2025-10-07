import 'dart:io';
import 'dart:typed_data';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentService {
  final SupabaseClient _client;

  DocumentService({SupabaseClient? client}) : _client = client ?? SupabaseService.instance.client;

  // Get all documents for user
  Future<List<Map<String, dynamic>>> getUserDocuments(String userId) async {
    try {
      final response = await _client
          .from('medical_documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch documents: $error');
    }
  }

  // Get documents by type
  Future<List<Map<String, dynamic>>> getDocumentsByType(
      String userId, String documentType) async {
    try {
      final response = await _client
          .from('medical_documents')
          .select()
          .eq('user_id', userId)
          .eq('document_type', documentType)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch documents by type: $error');
    }
  }

  // Search documents
  Future<List<Map<String, dynamic>>> searchDocuments(
      String userId, String query) async {
    try {
      final response = await _client
          .from('medical_documents')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,description.ilike.%$query%,healthcare_provider.ilike.%$query%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to search documents: $error');
    }
  }

  // Get recent documents
  Future<List<Map<String, dynamic>>> getRecentDocuments(String userId,
      {int limit = 5}) async {
    try {
      final response = await _client
          .from('medical_documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch recent documents: $error');
    }
  }

  // Get favorite documents
  Future<List<Map<String, dynamic>>> getFavoriteDocuments(String userId) async {
    try {
      final response = await _client
          .from('medical_documents')
          .select()
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch favorite documents: $error');
    }
  }

  // Upload document
  Future<String> uploadDocument(
      String userId, String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = _sanitizeFileName(fileName);
      final storagePath = '$userId/$timestamp-$safeName';
      final contentType = _guessMimeType(safeName);

      // Debug: log planned upload details for troubleshooting
      // Note: prints only assist during development; remove or gate if too verbose
      // ignore: avoid_print
      print('[DocumentService] uploadDocument → bucket=medical-documents, path=' 
          '$storagePath, contentType=$contentType, bytes=${fileBytes.length}');

      await _client.storage
          .from('medical-documents')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      // ignore: avoid_print
      print('[DocumentService] uploadDocument ✔ success path=$storagePath');

      // Some platforms of supabase_dart ignore contentType in const; set via update if supported
      // Fallback: ignore since most view paths use signed URL that infers type

      return storagePath;
    } catch (error) {
      // ignore: avoid_print
      print('[DocumentService] uploadDocument ✖ error: $error');
      throw Exception('Failed to upload document: $error');
    }
  }

  // Upload document from bytes (for web)
  Future<String> uploadDocumentFromBytes(
      String userId, Uint8List fileBytes, String fileName) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = _sanitizeFileName(fileName);
      final storagePath = '$userId/$timestamp-$safeName';
      final contentType = _guessMimeType(safeName);

      // Debug: log planned upload details for troubleshooting
      // ignore: avoid_print
      print('[DocumentService] uploadDocumentFromBytes → bucket=medical-documents, path=' 
          '$storagePath, contentType=$contentType, bytes=${fileBytes.length}');

      await _client.storage
          .from('medical-documents')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      // ignore: avoid_print
      print('[DocumentService] uploadDocumentFromBytes ✔ success path=$storagePath');

      return storagePath;
    } catch (error) {
      // ignore: avoid_print
      print('[DocumentService] uploadDocumentFromBytes ✖ error: $error');
      throw Exception('Failed to upload document: $error');
    }
  }

  // Get public URL for uploaded file
  String getPublicUrl(String bucket, String path) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // Add document record
  Future<Map<String, dynamic>> addDocumentRecord(
      Map<String, dynamic> documentData) async {
    try {
      final response = await _client
          .from('medical_documents')
          .insert(documentData)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add document record: $error');
    }
  }

  // Update document
  Future<Map<String, dynamic>> updateDocument(
      String documentId, Map<String, dynamic> updates) async {
    try {
      final response = await _client
          .from('medical_documents')
          .update(updates)
          .eq('id', documentId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update document: $error');
    }
  }

  // Toggle favorite status
  Future<Map<String, dynamic>> toggleFavorite(
      String documentId, bool isFavorite) async {
    try {
      final response = await _client
          .from('medical_documents')
          .update({'is_favorite': isFavorite})
          .eq('id', documentId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update favorite status: $error');
    }
  }

  // Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      // Get document info first
      final doc = await _client
          .from('medical_documents')
          .select('file_path')
          .eq('id', documentId)
          .single();

      // Delete file from storage
      await _client.storage
          .from('medical-documents')
          .remove([doc['file_path']]);

      // Delete document record
      await _client.from('medical_documents').delete().eq('id', documentId);
    } catch (error) {
      throw Exception('Failed to delete document: $error');
    }
  }

  // Get document download URL
  Future<String> getDocumentDownloadUrl(String filePath) async {
    try {
      final response = await _client.storage
          .from('medical-documents')
          .createSignedUrl(filePath, 3600); // 1 hour expiry

      return response;
    } catch (error) {
      throw Exception('Failed to get download URL: $error');
    }
  }

  // Download document
  Future<Uint8List> downloadDocument(String filePath) async {
    try {
      final response =
          await _client.storage.from('medical-documents').download(filePath);

      return response;
    } catch (error) {
      throw Exception('Failed to download document: $error');
    }
  }

  // Get documents statistics
  Future<Map<String, dynamic>> getDocumentStats(String userId) async {
    try {
      final totalDocs = await _client
          .from('medical_documents')
          .select('id')
          .eq('user_id', userId)
          .count();

      final recentDocs = await _client
          .from('medical_documents')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at',
              DateTime.now().subtract(Duration(days: 30)).toIso8601String())
          .count();

      final favoriteDocs = await _client
          .from('medical_documents')
          .select('id')
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .count();

      // Get document types distribution
      final typeStats = await _client
          .from('medical_documents')
          .select('document_type')
          .eq('user_id', userId);

      Map<String, int> typeDistribution = {};
      for (var doc in typeStats) {
        String type = doc['document_type'];
        typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
      }

      return {
        'total': totalDocs.count ?? 0,
        'recent': recentDocs.count ?? 0,
        'favorites': favoriteDocs.count ?? 0,
        'types': typeDistribution,
      };
    } catch (error) {
      throw Exception('Failed to fetch document statistics: $error');
    }
  }

  // Share document
  Future<Map<String, dynamic>> shareDocument({
    required String documentId,
    required String sharedWithEmail,
    String? sharedWithName,
    String permission = 'view',
    DateTime? expiresAt,
  }) async {
    try {
      final shareData = {
        'document_id': documentId,
        'shared_with_email': sharedWithEmail,
        'shared_with_name': sharedWithName,
        'permission': permission,
        'expires_at': expiresAt?.toIso8601String(),
        'access_code': _generateAccessCode(),
      };

      final response = await _client
          .from('document_shares')
          .insert(shareData)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to share document: $error');
    }
  }

  // Get shared documents
  Future<List<Map<String, dynamic>>> getSharedDocuments() async {
    try {
      final response = await _client.from('document_shares').select('''
            *,
            medical_documents (
              id,
              title,
              document_type,
              created_at
            )
          ''');

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch shared documents: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getShareRequests() async {
    try {
      // This would typically come from a separate share_requests table
      // For now, return empty list as a placeholder
      return [];
    } catch (error) {
      throw Exception('Failed to fetch share requests: $error');
    }
  }

  // Generate access code for sharing
  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (index) => chars[random % chars.length]).join();
  }

  // Sanitize file name for storage paths
  String _sanitizeFileName(String input) {
    // Keep alphanumerics, dash, underscore, dot; replace spaces with '-'
    final replaced = input.replaceAll(' ', '-');
    final cleaned = replaced.replaceAll(RegExp(r'[^A-Za-z0-9\-_.]'), '');
    // Avoid leading dots or empty names
    final normalized = cleaned.isEmpty ? 'file' : cleaned;
    return normalized;
  }

  String _guessMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}