import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../secure_sharing_screen.dart';
import '../../services/secure_sharing_service.dart';
import '../../theme/app_theme.dart';

class CreateShareDialog extends StatefulWidget {
  const CreateShareDialog({Key? key}) : super(key: key);

  @override
  State<CreateShareDialog> createState() => _CreateShareDialogState();
}

class _CreateShareDialogState extends State<CreateShareDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final SecureSharingService _sharingService = SecureSharingService();

  String _selectedResourceType = 'health_summary';
  String? _selectedResourceId;
  DateTime? _expiresAt;
  List<String> _permissions = ['read'];
  bool _isLoading = false;

  final Map<String, String> _resourceTypes = {
    'health_summary': 'Complete Health Summary',
    'medical_document': 'Specific Medical Document',
    'health_event': 'Health Event',
    'medication': 'Medication',
    'doctor_note': 'Doctor Note',
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.share, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Create Secure Share',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resource Type Selection
                      const Text(
                        'What would you like to share?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedResourceType,
                        decoration: const InputDecoration(
                          labelText: 'Select resource type',
                          border: OutlineInputBorder(),
                        ),
                        items: _resourceTypes.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedResourceType = value!;
                            _selectedResourceId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Share with email
                      const Text(
                        'Share with',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'doctor@hospital.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email address';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Permissions
                      const Text(
                        'Permissions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Read'),
                            selected: _permissions.contains('read'),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _permissions.add('read');
                                } else {
                                  _permissions.remove('read');
                                }
                              });
                            },
                          ),
                          FilterChip(
                            label: const Text('Download'),
                            selected: _permissions.contains('download'),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _permissions.add('download');
                                } else {
                                  _permissions.remove('download');
                                }
                              });
                            },
                          ),
                          FilterChip(
                            label: const Text('Print'),
                            selected: _permissions.contains('print'),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _permissions.add('print');
                                } else {
                                  _permissions.remove('print');
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Expiry date
                      const Text(
                        'Access Duration',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _selectExpiryDate(),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _expiresAt == null
                                    ? 'Never expires'
                                    : 'Expires: ${_formatDate(_expiresAt!)}',
                              ),
                            ),
                          ),
                          if (_expiresAt != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => setState(() => _expiresAt = null),
                              icon: const Icon(Icons.clear),
                              tooltip: 'Remove expiry',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Message
                      const Text(
                        'Message (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Add a message',
                          hintText: 'Please review my latest lab reports...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createShare,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Share'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _expiresAt = date);
    }
  }

  Future<void> _createShare() async {
    if (!_formKey.currentState!.validate()) return;
    if (_permissions.isEmpty) {
      _showError('Please select at least one permission');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _sharingService.createSecureShare(
        resourceType: _selectedResourceType,
        resourceId: _selectedResourceId ?? 'default',
        shareWithEmail: _emailController.text.trim(),
        permissions: _permissions,
        expiresAt: _expiresAt,
        message: _messageController.text.trim().isEmpty 
            ? null 
            : _messageController.text.trim(),
      );

      Navigator.of(context).pop(true);

      // Show success dialog with share details
      showDialog(
        context: context,
        builder: (context) => ShareCreatedDialog(
          shareLink: result['shareLink'],
          accessCode: result['accessCode'],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to create share: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class ShareCreatedDialog extends StatelessWidget {
  final String shareLink;
  final String accessCode;

  const ShareCreatedDialog({
    Key? key,
    required this.shareLink,
    required this.accessCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Created Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Access Code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    accessCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: accessCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Access code copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share(
                        'Access my medical records securely:\n\nAccess Code: $accessCode\nLink: $shareLink',
                        subject: 'Secure Health Records Access',
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class ShareDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> share;

  const ShareDetailsDialog({
    Key? key,
    required this.share,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      'type': 'health_share',
      'access_code': share['access_code'],
      'app': 'health_history',
    });

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code),
                const SizedBox(width: 8),
                const Text(
                  'QR Code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Access Code',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          share['access_code'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: share['access_code']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Access code copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Others can scan this QR code or enter the access code to view your shared medical records.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ShareOptionsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> share;
  final VoidCallback onUpdate;

  const ShareOptionsBottomSheet({
    Key? key,
    required this.share,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SecureSharingService sharingService = SecureSharingService();
    final isActive = share['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Share Options',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(
              isActive ? Icons.pause_circle : Icons.play_circle,
              color: isActive ? Colors.orange : Colors.green,
            ),
            title: Text(isActive ? 'Deactivate Share' : 'Activate Share'),
            subtitle: Text(
              isActive 
                  ? 'Others will no longer be able to access this share'
                  : 'Reactivate this share for access',
            ),
            onTap: () async {
              try {
                await sharingService.updateShareStatus(share['id'], !isActive);
                Navigator.of(context).pop();
                onUpdate();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isActive ? 'Share deactivated' : 'Share activated',
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update share: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Share'),
            subtitle: const Text('Permanently remove this share'),
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(context, sharingService);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SecureSharingService sharingService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Share'),
        content: const Text(
          'Are you sure you want to delete this share? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await sharingService.deleteShare(share['id']);
                Navigator.of(context).pop();
                onUpdate();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete share: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class SharedResourceViewer extends StatelessWidget {
  final Map<String, dynamic> share;
  final Map<String, dynamic> resource;

  const SharedResourceViewer({
    Key? key,
    required this.share,
    required this.resource,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared ${_getResourceTypeTitle(share['resource_type'])}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Share info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.share, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shared by ${share['shared_by_profile']?['full_name'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                share['shared_by_profile']?['email'] ?? '',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (share['message'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          share['message'],
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resource content
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildResourceContent(share['resource_type'], resource),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceContent(String resourceType, Map<String, dynamic> resource) {
    switch (resourceType) {
      case 'health_summary':
        return _buildHealthSummary(resource);
      case 'medical_document':
        return _buildMedicalDocument(resource);
      case 'health_event':
        return _buildHealthEvent(resource);
      case 'medication':
        return _buildMedication(resource);
      case 'doctor_note':
        return _buildDoctorNote(resource);
      default:
        return Text('Resource content for $resourceType');
    }
  }

  Widget _buildHealthSummary(Map<String, dynamic> summary) {
    final profile = summary['profile'] as Map<String, dynamic>?;
    final emergencyContacts = summary['emergency_contacts'] as List?;
    final medications = summary['current_medications'] as List?;
    final insurance = summary['insurance'] as Map<String, dynamic>?;
    final allergies = summary['allergies'] as List?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (profile != null) ...[
          _buildSectionHeader('Patient Information'),
          _buildInfoRow('Name', profile['full_name'] ?? 'N/A'),
          _buildInfoRow('Date of Birth', profile['date_of_birth'] ?? 'N/A'),
          _buildInfoRow('Blood Group', profile['blood_group'] ?? 'N/A'),
          _buildInfoRow('Height', profile['height']?.toString() ?? 'N/A'),
          _buildInfoRow('Weight', profile['weight']?.toString() ?? 'N/A'),
          const SizedBox(height: 16),
        ],

        if (emergencyContacts?.isNotEmpty == true) ...[
          _buildSectionHeader('Emergency Contacts'),
          ...emergencyContacts!.map((contact) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${contact['relationship']} - ${contact['phone_number']}'),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
        ],

        if (medications?.isNotEmpty == true) ...[
          _buildSectionHeader('Current Medications'),
          ...medications!.map((med) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med['medication_name'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${med['dosage']} - ${med['frequency']}'),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
        ],

        if (allergies?.isNotEmpty == true) ...[
          _buildSectionHeader('Allergies'),
          ...allergies!.map((allergy) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                allergy['description'] ?? 'N/A',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildMedicalDocument(Map<String, dynamic> document) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          document['title'] ?? 'Medical Document',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Type', document['document_type'] ?? 'N/A'),
        _buildInfoRow('Date', document['document_date'] ?? 'N/A'),
        _buildInfoRow('Doctor/Hospital', document['doctor_name'] ?? 'N/A'),
        if (document['notes'] != null) ...[
          const SizedBox(height: 12),
          const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(document['notes']),
        ],
      ],
    );
  }

  Widget _buildHealthEvent(Map<String, dynamic> event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event['event_type']?.toString().toUpperCase() ?? 'Health Event',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Date', event['event_date'] ?? 'N/A'),
        _buildInfoRow('Severity', event['severity'] ?? 'N/A'),
        if (event['description'] != null) ...[
          const SizedBox(height: 12),
          const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(event['description']),
        ],
      ],
    );
  }

  Widget _buildMedication(Map<String, dynamic> medication) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medication['medication_name'] ?? 'Medication',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Dosage', medication['dosage'] ?? 'N/A'),
        _buildInfoRow('Frequency', medication['frequency'] ?? 'N/A'),
        _buildInfoRow('Start Date', medication['start_date'] ?? 'N/A'),
        if (medication['end_date'] != null)
          _buildInfoRow('End Date', medication['end_date']),
        if (medication['notes'] != null) ...[
          const SizedBox(height: 12),
          const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(medication['notes']),
        ],
      ],
    );
  }

  Widget _buildDoctorNote(Map<String, dynamic> note) {
    final doctor = note['doctor'] as Map<String, dynamic>?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doctor Note',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (doctor != null) ...[
          _buildInfoRow('Doctor', doctor['full_name'] ?? 'N/A'),
          _buildInfoRow('Specialization', doctor['specialization'] ?? 'N/A'),
          _buildInfoRow('License', doctor['license_number'] ?? 'N/A'),
          const SizedBox(height: 12),
        ],
        _buildInfoRow('Date', note['created_at'] ?? 'N/A'),
        _buildInfoRow('Type', note['note_type'] ?? 'N/A'),
        if (note['diagnosis'] != null) ...[
          const SizedBox(height: 12),
          const Text('Diagnosis:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(note['diagnosis']),
        ],
        if (note['treatment_plan'] != null) ...[
          const SizedBox(height: 12),
          const Text('Treatment Plan:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(note['treatment_plan']),
        ],
        if (note['notes'] != null) ...[
          const SizedBox(height: 12),
          const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(note['notes']),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getResourceTypeTitle(String resourceType) {
    switch (resourceType) {
      case 'medical_document':
        return 'Medical Document';
      case 'health_event':
        return 'Health Event';
      case 'medication':
        return 'Medication';
      case 'doctor_note':
        return 'Doctor Note';
      case 'health_summary':
        return 'Health Summary';
      default:
        return 'Shared Item';
    }
  }
}