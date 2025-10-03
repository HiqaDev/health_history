import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medication_models.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/add_medication_form_widget.dart';
import './widgets/adherence_tracking_widget.dart';
import './widgets/medication_card_widget.dart';

/// Medication Reminders screen with comprehensive scheduling and adherence tracking
/// Features intelligent notification system and medication management
class MedicationReminders extends StatefulWidget {
  const MedicationReminders({super.key});

  @override
  State<MedicationReminders> createState() => _MedicationRemindersState();
}

class _MedicationRemindersState extends State<MedicationReminders>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - replace with actual data management
  List<MedicationReminder> _medications = [
    MedicationReminder(
      id: '1',
      drugName: 'Metformin',
      dosage: '500 mg',
      frequency: 'Twice daily',
      scheduledTime: '08:00',
      status: MedicationStatus.taken,
      takenTime: '08:15',
      notes: 'Take with breakfast',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    MedicationReminder(
      id: '2',
      drugName: 'Lisinopril',
      dosage: '10 mg',
      frequency: 'Daily',
      scheduledTime: '12:00',
      status: MedicationStatus.upcoming,
      notes: 'Take before lunch',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    MedicationReminder(
      id: '3',
      drugName: 'Aspirin',
      dosage: '81 mg',
      frequency: 'Daily',
      scheduledTime: '09:00',
      status: MedicationStatus.missed,
      notes: 'Take with food',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    MedicationReminder(
      id: '4',
      drugName: 'Vitamin D3',
      dosage: '1000 IU',
      frequency: 'Daily',
      scheduledTime: '20:00',
      status: MedicationStatus.upcoming,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  final AdherenceData _adherenceData = const AdherenceData(
    currentStreak: 5,
    weeklyPercentage: 85.7,
    monthlyPercentage: 78.9,
    weeklyData: [90.0, 80.0, 95.0, 75.0, 85.0, 70.0, 100.0],
    achievements: [
      Achievement(
        id: 'streak_7',
        title: '7 Day Streak',
        description: 'Take medications for 7 consecutive days',
        icon: Icons.local_fire_department,
        isUnlocked: false,
      ),
      Achievement(
        id: 'perfect_week',
        title: 'Perfect Week',
        description: '100% adherence for a full week',
        icon: Icons.star,
        isUnlocked: true,
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Take morning medications on time',
        icon: Icons.wb_sunny,
        isUnlocked: true,
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todaysMedications =
        _medications.where((med) => _isToday(med)).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Medication Reminders',
        actions: [
          TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
            tabs: const [
              Tab(text: 'Today'),
              Tab(text: 'Tracking'),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(todaysMedications),
          _buildTrackingTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicationForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  Widget _buildTodayTab(List<MedicationReminder> todaysMedications) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr =
        '${_getWeekdayName(now.weekday)}, ${_getMonthName(now.month)} ${now.day}';

    return Column(
      children: [
        // Header with date and medication count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(128),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${todaysMedications.length} medications scheduled today',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Medications list
        Expanded(
          child: todaysMedications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: todaysMedications.length,
                  itemBuilder: (context, index) {
                    final medication = todaysMedications[index];
                    return MedicationCardWidget(
                      medication: medication,
                      onTakeNow: () => _markAsTaken(medication),
                      onSkipDose: () => _skipDose(medication),
                      onEdit: () => _editMedication(medication),
                      onDelete: () => _deleteMedication(medication),
                      onViewHistory: () => _viewHistory(medication),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AdherenceTrackingWidget(adherenceData: _adherenceData),
          const SizedBox(height: 16),
          _buildMedicationsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'No medications scheduled',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the "Add Medication" button to schedule your first medication reminder.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddMedicationForm,
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsList() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Medications',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._medications.map((medication) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(theme, medication.status)
                          .withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: _getStatusColor(theme, medication.status),
                    ),
                  ),
                  title: Text(
                    medication.drugName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      Text('${medication.dosage} • ${medication.frequency}'),
                  trailing: IconButton(
                    onPressed: () => _editMedication(medication),
                    icon: const Icon(Icons.more_vert),
                  ),
                  onTap: () => _viewHistory(medication),
                )),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return theme.colorScheme.tertiary;
      case MedicationStatus.missed:
        return theme.colorScheme.error;
      case MedicationStatus.upcoming:
        return theme.colorScheme.primary;
    }
  }

  bool _isToday(MedicationReminder medication) {
    // Simple implementation - in real app, check against actual scheduled dates
    return true;
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  void _showAddMedicationForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationFormWidget(
          onSave: (medicationData) {
            _addMedication(medicationData);
          },
        ),
      ),
    );
  }

  void _addMedication(MedicationFormData formData) {
    final newMedication = MedicationReminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      drugName: formData.drugName,
      dosage: formData.dosage,
      frequency: formData.frequencyType.label,
      scheduledTime: formData.scheduledTimes.isNotEmpty
          ? formData.scheduledTimes.first.format(context)
          : '08:00',
      status: MedicationStatus.upcoming,
      notes: formData.notes,
      createdAt: DateTime.now(),
    );

    setState(() {
      _medications.add(newMedication);
    });

    _showSuccessSnackBar('Medication added successfully');
  }

  void _markAsTaken(MedicationReminder medication) {
    setState(() {
      final index = _medications.indexWhere((med) => med.id == medication.id);
      if (index != -1) {
        _medications[index] = MedicationReminder(
          id: medication.id,
          drugName: medication.drugName,
          dosage: medication.dosage,
          frequency: medication.frequency,
          scheduledTime: medication.scheduledTime,
          takenTime: TimeOfDay.now().format(context),
          status: MedicationStatus.taken,
          notes: medication.notes,
          createdAt: medication.createdAt,
        );
      }
    });
    _showSuccessSnackBar('Medication marked as taken');
  }

  void _skipDose(MedicationReminder medication) {
    _showDialog(
      'Skip Dose',
      'Are you sure you want to skip this dose?',
      () {
        // Mark as skipped (could be a separate status)
        _showInfoSnackBar('Dose skipped');
      },
    );
  }

  void _editMedication(MedicationReminder medication) {
    _showInfoSnackBar('Edit medication feature coming soon');
  }

  void _deleteMedication(MedicationReminder medication) {
    _showDialog(
      'Delete Medication',
      'Are you sure you want to delete ${medication.drugName}?',
      () {
        setState(() {
          _medications.removeWhere((med) => med.id == medication.id);
        });
        _showInfoSnackBar('Medication deleted');
      },
    );
  }

  void _viewHistory(MedicationReminder medication) {
    _showInfoSnackBar('View history feature coming soon');
  }

  void _showDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}