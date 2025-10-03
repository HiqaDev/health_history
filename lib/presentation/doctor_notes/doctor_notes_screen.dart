import 'package:flutter/material.d      final userProfile = await _authService.getUserProfile();rt';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/doctor_notes_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';
import '../../core/app_export.dart';

class DoctorNotesScreen extends StatefulWidget {
  const DoctorNotesScreen({Key? key}) : super(key: key);

  @override
  State<DoctorNotesScreen> createState() => _DoctorNotesScreenState();
}

class _DoctorNotesScreenState extends State<DoctorNotesScreen> {
  final DoctorNotesService _doctorNotesService = DoctorNotesService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndNotes();
  }

  Future<void> _loadUserRoleAndNotes() async {
    setState(() => _isLoading = true);
    
    // Check user role
    final userProfile = await _authService.getCurrentUserProfile();
    if (userProfile != null) {
      _isDoctor = userProfile['user_role'] == 'doctor';
    }
    
    await _loadNotes();
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotes() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    List<Map<String, dynamic>> notes;
    if (_searchQuery.isNotEmpty) {
      notes = await _doctorNotesService.searchDoctorNotes(
        userId: userId,
        query: _searchQuery,
        isDoctor: _isDoctor,
      );
    } else {
      if (_isDoctor) {
        notes = await _doctorNotesService.getDoctorNotes(userId);
      } else {
        notes = await _doctorNotesService.getPatientNotes(userId);
      }
    }

    setState(() {
      _notes = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDoctor ? 'My Patient Notes' : 'Doctor Notes'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadNotes();
              },
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? _buildEmptyState()
                    : _buildNotesList(),
          ),
        ],
      ),
      floatingActionButton: _isDoctor
          ? FloatingActionButton(
              onPressed: () => _showCreateNoteDialog(),
              backgroundColor: Colors.blue[600],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No notes found for "$_searchQuery"'
                : _isDoctor
                    ? 'No patient notes yet'
                    : 'No doctor notes available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isDoctor
                ? 'Start by creating your first patient note'
                : 'Doctor notes will appear here when shared with you',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final visitDate = DateTime.parse(note['visit_date']);
    final patientName = _isDoctor 
        ? note['user_profiles']?['full_name'] ?? 'Unknown Patient'
        : 'You';
    final doctorInfo = note['doctor_profiles'];
    final specialization = doctorInfo?['specialization']?[0] ?? 'General';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showNoteDetails(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    Icons.medical_information,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDoctor ? 'Patient: $patientName' : 'Dr. ${doctorInfo?['qualification'] ?? 'Dr.'} Visit',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _isDoctor ? specialization : specialization.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${visitDate.day}/${visitDate.month}/${visitDate.year}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (note['voice_note_url'] != null)
                        Icon(
                          Icons.mic,
                          color: Colors.orange[600],
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Chief complaint
              if (note['chief_complaint'] != null && note['chief_complaint'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chief Complaint:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note['chief_complaint'],
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              
              // Assessment preview
              if (note['assessment'] != null && note['assessment'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note['assessment'],
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              
              // Footer actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to view full note',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  if (_isDoctor)
                    Row(
                      children: [
                        if (!note['is_shared_with_patient'])
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Private',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDetails(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DragScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return DoctorNoteDetailsView(
            note: note,
            isDoctor: _isDoctor,
            scrollController: scrollController,
            onNoteUpdated: _loadNotes,
          );
        },
      ),
    );
  }

  void _showCreateNoteDialog() {
    // Implementation for creating new note
    // This would typically navigate to a separate screen or show a dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create Note feature - to be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class DoctorNoteDetailsView extends StatelessWidget {
  final Map<String, dynamic> note;
  final bool isDoctor;
  final ScrollController scrollController;
  final VoidCallback onNoteUpdated;

  const DoctorNoteDetailsView({
    Key? key,
    required this.note,
    required this.isDoctor,
    required this.scrollController,
    required this.onNoteUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visitDate = DateTime.parse(note['visit_date']);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Row(
            children: [
              Icon(
                Icons.medical_information,
                color: Colors.blue[600],
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor Note',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${visitDate.day}/${visitDate.month}/${visitDate.year}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDoctor)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Edit Note'),
                      onTap: () => _editNote(context),
                    ),
                    PopupMenuItem(
                      child: Text(note['is_shared_with_patient'] ? 'Make Private' : 'Share with Patient'),
                      onTap: () => _toggleSharing(context),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Note sections
          if (note['chief_complaint'] != null && note['chief_complaint'].isNotEmpty)
            _buildSection('Chief Complaint', note['chief_complaint']),
          
          if (note['history_of_present_illness'] != null && note['history_of_present_illness'].isNotEmpty)
            _buildSection('History of Present Illness', note['history_of_present_illness']),
          
          if (note['physical_examination'] != null && note['physical_examination'].isNotEmpty)
            _buildSection('Physical Examination', note['physical_examination']),
          
          if (note['assessment'] != null && note['assessment'].isNotEmpty)
            _buildSection('Assessment', note['assessment']),
          
          if (note['plan'] != null && note['plan'].isNotEmpty)
            _buildSection('Plan', note['plan']),
          
          // Voice note section
          if (note['voice_note_url'] != null)
            _buildVoiceNoteSection(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVoiceNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Voice Note',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.mic, color: Colors.orange[600]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Voice note available',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Play voice note implementation
                },
                icon: Icon(Icons.play_arrow, color: Colors.orange[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _editNote(BuildContext context) {
    // Implementation for editing note
  }

  void _toggleSharing(BuildContext context) {
    // Implementation for toggling sharing
  }
}