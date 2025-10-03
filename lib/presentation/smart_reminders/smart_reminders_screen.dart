import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/smart_reminders_service.dart';
import '../../services/auth_service.dart';

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({Key? key}) : super(key: key);

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen> with TickerProviderStateMixin {
  final SmartRemindersService _remindersService = SmartRemindersService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  List<Map<String, dynamic>> _todaysReminders = [];
  List<Map<String, dynamic>> _upcomingReminders = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    await _remindersService.initializeNotifications();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _remindersService.getTodaysReminders(),
        _remindersService.getUpcomingReminders(),
        _remindersService.getReminderStatistics(),
      ]);

      setState(() {
        _todaysReminders = results[0] as List<Map<String, dynamic>>;
        _upcomingReminders = results[1] as List<Map<String, dynamic>>;
        _statistics = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remindersService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Reminders'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Statistics'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodaysTab(),
                _buildUpcomingTab(),
                _buildStatisticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateReminderDialog(),
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTodaysTab() {
    if (_todaysReminders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No reminders today',
        subtitle: 'You\'re all set for today!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _todaysReminders.length,
        itemBuilder: (context, index) {
          final reminder = _todaysReminders[index];
          return _buildReminderCard(reminder, isToday: true);
        },
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingReminders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_note,
        title: 'No upcoming reminders',
        subtitle: 'Your schedule is clear for the next week',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingReminders.length,
        itemBuilder: (context, index) {
          final reminder = _upcomingReminders[index];
          return _buildReminderCard(reminder, isToday: false);
        },
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Adherence rate card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Monthly Adherence Rate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_statistics['adherence_rate'] ?? 0}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_statistics['completed_reminders'] ?? 0} of ${_statistics['total_reminders'] ?? 0} completed',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Statistics grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Medication',
                '${_statistics['medication_reminders'] ?? 0}',
                Icons.medication,
                Colors.green,
              ),
              _buildStatCard(
                'Appointments',
                '${_statistics['appointment_reminders'] ?? 0}',
                Icons.calendar_today,
                Colors.orange,
              ),
              _buildStatCard(
                'Completed',
                '${_statistics['completed_reminders'] ?? 0}',
                Icons.check_circle,
                Colors.blue,
              ),
              _buildStatCard(
                'Missed',
                '${_statistics['missed_reminders'] ?? 0}',
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder, {required bool isToday}) {
    final scheduledTime = DateTime.parse(reminder['scheduled_time']);
    final isCompleted = reminder['is_completed'] ?? false;
    final reminderType = reminder['reminder_type'] as String;
    
    IconData icon;
    Color iconColor;
    
    switch (reminderType) {
      case 'medication':
        icon = Icons.medication;
        iconColor = Colors.green[600]!;
        break;
      case 'appointment':
        icon = Icons.calendar_today;
        iconColor = Colors.orange[600]!;
        break;
      case 'test_due':
        icon = Icons.biotech;
        iconColor = Colors.purple[600]!;
        break;
      case 'vaccination':
        icon = Icons.vaccines;
        iconColor = Colors.blue[600]!;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey[600]!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.grey[200] : iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted ? Colors.grey[600] : iconColor,
            size: 24,
          ),
        ),
        title: Text(
          reminder['title'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey[600] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder['description'] != null)
              Text(
                reminder['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isCompleted ? Colors.grey[500] : Colors.grey[700],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              isToday
                  ? '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}'
                  : '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year} at ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: isToday && !isCompleted ? Colors.blue[600] : Colors.grey[500],
                fontWeight: isToday && !isCompleted ? FontWeight.w500 : null,
              ),
            ),
          ],
        ),
        trailing: isToday && !isCompleted
            ? PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Mark Complete'),
                    onTap: () => _markComplete(reminder['id']),
                  ),
                  PopupMenuItem(
                    child: const Text('Snooze 15 min'),
                    onTap: () => _snoozeReminder(reminder['id'], 15),
                  ),
                  PopupMenuItem(
                    child: const Text('Snooze 1 hour'),
                    onTap: () => _snoozeReminder(reminder['id'], 60),
                  ),
                ],
              )
            : null,
        onTap: isCompleted ? null : () => _showReminderDetails(reminder),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _markComplete(String reminderId) async {
    final success = await _remindersService.markReminderCompleted(reminderId);
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _snoozeReminder(String reminderId, int minutes) async {
    final success = await _remindersService.snoozeReminder(reminderId, minutes);
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder snoozed for $minutes minutes'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showReminderDetails(Map<String, dynamic> reminder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReminderDetailsSheet(
        reminder: reminder,
        onUpdate: _loadData,
        remindersService: _remindersService,
      ),
    );
  }

  void _showCreateReminderDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreateReminderSheet(
        onCreated: _loadData,
        remindersService: _remindersService,
      ),
    );
  }
}

class ReminderDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onUpdate;
  final SmartRemindersService remindersService;

  const ReminderDetailsSheet({
    Key? key,
    required this.reminder,
    required this.onUpdate,
    required this.remindersService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheduledTime = DateTime.parse(reminder['scheduled_time']);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          
          Text(
            reminder['title'],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (reminder['description'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(reminder['description']),
                const SizedBox(height: 16),
              ],
            ),
          
          Text(
            'Scheduled Time:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year} at ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _markComplete(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark Complete'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteReminder(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  void _markComplete(BuildContext context) async {
    final success = await remindersService.markReminderCompleted(reminder['id']);
    if (success) {
      onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteReminder(BuildContext context) async {
    final success = await remindersService.deleteReminder(reminder['id']);
    if (success) {
      onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class CreateReminderSheet extends StatefulWidget {
  final VoidCallback onCreated;
  final SmartRemindersService remindersService;

  const CreateReminderSheet({
    Key? key,
    required this.onCreated,
    required this.remindersService,
  }) : super(key: key);

  @override
  State<CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends State<CreateReminderSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'medication';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          
          Text(
            'Create Reminder',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'medication', child: Text('Medication')),
              DropdownMenuItem(value: 'appointment', child: Text('Appointment')),
              DropdownMenuItem(value: 'test_due', child: Text('Test Due')),
              DropdownMenuItem(value: 'vaccination', child: Text('Vaccination')),
              DropdownMenuItem(value: 'custom', child: Text('Custom')),
            ],
            onChanged: (value) => setState(() => _selectedType = value!),
          ),
          
          const SizedBox(height: 16),
          
          ListTile(
            title: const Text('Date & Time'),
            subtitle: Text(
              '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} at ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.edit),
            onTap: _selectDateTime,
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create Reminder'),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _createReminder() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reminder = await widget.remindersService.createReminder(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      reminderType: _selectedType,
      scheduledTime: _selectedDateTime,
    );

    if (reminder != null) {
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create reminder'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}