import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

class SmartRemindersService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Timer? _reminderCheckTimer;

  // Initialize notifications
  Future<void> initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(initSettings);
    
    // Start periodic reminder checks
    _startReminderChecks();
  }

  // Start periodic checks for due reminders
  void _startReminderChecks() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(
      const Duration(minutes: 1), // Check every minute
      (timer) => _checkAndSendDueReminders(),
    );
  }

  // Create a new reminder
  Future<Map<String, dynamic>?> createReminder({
    required String title,
    String? description,
    required String reminderType, // 'medication', 'appointment', 'test_due', 'vaccination', 'custom'
    String? relatedMedicationId,
    String? relatedAppointmentId,
    required DateTime scheduledTime,
    Map<String, dynamic>? repeatPattern,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      final response = await _supabase.from('reminders').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'reminder_type': reminderType,
        'related_medication_id': relatedMedicationId,
        'related_appointment_id': relatedAppointmentId,
        'scheduled_time': scheduledTime.toIso8601String(),
        'repeat_pattern': repeatPattern,
        'is_active': true,
        'is_completed': false,
      }).select().single();

      // Schedule local notification
      await _scheduleLocalNotification(response);

      return response;
    } catch (e) {
      print('Error creating reminder: $e');
      return null;
    }
  }

  // Get user's reminders
  Future<List<Map<String, dynamic>>> getUserReminders({
    bool activeOnly = true,
    String? reminderType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _supabase
          .from('reminders')
          .select('''
            *,
            medications:related_medication_id (
              id,
              name,
              dosage,
              frequency
            ),
            appointments:related_appointment_id (
              id,
              doctor_name,
              hospital_name,
              purpose
            )
          ''')
          .eq('user_id', userId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (reminderType != null) {
        query = query.eq('reminder_type', reminderType);
      }

      final response = await query.order('scheduled_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }

  // Get today's reminders
  Future<List<Map<String, dynamic>>> getTodaysReminders() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('reminders')
          .select('''
            *,
            medications:related_medication_id (
              id,
              name,
              dosage,
              frequency
            ),
            appointments:related_appointment_id (
              id,
              doctor_name,
              hospital_name,
              purpose
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gte('scheduled_time', startOfDay.toIso8601String())
          .lt('scheduled_time', endOfDay.toIso8601String())
          .order('scheduled_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching today\'s reminders: $e');
      return [];
    }
  }

  // Get upcoming reminders (next 7 days)
  Future<List<Map<String, dynamic>>> getUpcomingReminders() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      final response = await _supabase
          .from('reminders')
          .select('''
            *,
            medications:related_medication_id (
              id,
              name,
              dosage,
              frequency
            ),
            appointments:related_appointment_id (
              id,
              doctor_name,
              hospital_name,
              purpose
            )
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gte('scheduled_time', now.toIso8601String())
          .lte('scheduled_time', nextWeek.toIso8601String())
          .order('scheduled_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching upcoming reminders: $e');
      return [];
    }
  }

  // Mark reminder as completed
  Future<bool> markReminderCompleted(String reminderId, {bool completed = true}) async {
    try {
      await _supabase
          .from('reminders')
          .update({
            'is_completed': completed,
            'notification_sent': completed,
          })
          .eq('id', reminderId);

      // If marking as incomplete, reschedule notification
      if (!completed) {
        final reminder = await _getReminderById(reminderId);
        if (reminder != null) {
          await _scheduleLocalNotification(reminder);
        }
      }

      return true;
    } catch (e) {
      print('Error marking reminder as completed: $e');
      return false;
    }
  }

  // Snooze reminder (delay by specified minutes)
  Future<bool> snoozeReminder(String reminderId, int minutes) async {
    try {
      final reminder = await _getReminderById(reminderId);
      if (reminder == null) return false;

      final currentTime = DateTime.parse(reminder['scheduled_time']);
      final newTime = currentTime.add(Duration(minutes: minutes));

      await _supabase
          .from('reminders')
          .update({
            'scheduled_time': newTime.toIso8601String(),
            'notification_sent': false,
          })
          .eq('id', reminderId);

      // Reschedule notification
      final updatedReminder = await _getReminderById(reminderId);
      if (updatedReminder != null) {
        await _scheduleLocalNotification(updatedReminder);
      }

      return true;
    } catch (e) {
      print('Error snoozing reminder: $e');
      return false;
    }
  }

  // Delete reminder
  Future<bool> deleteReminder(String reminderId) async {
    try {
      await _supabase.from('reminders').delete().eq('id', reminderId);
      
      // Cancel local notification
      await _notificationsPlugin.cancel(reminderId.hashCode);
      
      return true;
    } catch (e) {
      print('Error deleting reminder: $e');
      return false;
    }
  }

  // Update reminder
  Future<Map<String, dynamic>?> updateReminder({
    required String reminderId,
    String? title,
    String? description,
    DateTime? scheduledTime,
    Map<String, dynamic>? repeatPattern,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (scheduledTime != null) {
        updateData['scheduled_time'] = scheduledTime.toIso8601String();
        updateData['notification_sent'] = false; // Reset notification flag
      }
      if (repeatPattern != null) updateData['repeat_pattern'] = repeatPattern;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _supabase
          .from('reminders')
          .update(updateData)
          .eq('id', reminderId)
          .select()
          .single();

      // Reschedule notification if time changed or reactivated
      if (scheduledTime != null || (isActive == true)) {
        await _scheduleLocalNotification(response);
      }

      return response;
    } catch (e) {
      print('Error updating reminder: $e');
      return null;
    }
  }

  // Create medication reminders automatically
  Future<List<String>> createMedicationReminders(Map<String, dynamic> medication) async {
    try {
      final reminderIds = <String>[];
      final frequency = medication['frequency'] as String;
      final startDate = DateTime.parse(medication['start_date']);
      final endDate = medication['end_date'] != null ? DateTime.parse(medication['end_date']) : null;

      // Parse frequency and create appropriate reminders
      final reminders = _generateMedicationReminderSchedule(
        medicationName: medication['name'],
        dosage: medication['dosage'],
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
      );

      for (final reminderData in reminders) {
        final reminder = await createReminder(
          title: 'Take ${medication['name']}',
          description: 'Dosage: ${medication['dosage']}\n${reminderData['instructions']}',
          reminderType: 'medication',
          relatedMedicationId: medication['id'],
          scheduledTime: reminderData['scheduledTime'],
          repeatPattern: reminderData['repeatPattern'],
        );

        if (reminder != null) {
          reminderIds.add(reminder['id']);
        }
      }

      return reminderIds;
    } catch (e) {
      print('Error creating medication reminders: $e');
      return [];
    }
  }

  // Generate medication reminder schedule based on frequency
  List<Map<String, dynamic>> _generateMedicationReminderSchedule({
    required String medicationName,
    required String dosage,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    final reminders = <Map<String, dynamic>>[];
    
    // Common reminder times
    const morningTime = TimeOfDay(hour: 8, minute: 0);
    const afternoonTime = TimeOfDay(hour: 14, minute: 0);
    const eveningTime = TimeOfDay(hour: 20, minute: 0);
    const nightTime = TimeOfDay(hour: 22, minute: 0);

    switch (frequency.toLowerCase()) {
      case 'once daily':
      case '1 time per day':
      case 'daily':
        reminders.add({
          'scheduledTime': _combineDateTime(startDate, morningTime),
          'instructions': 'Take once daily in the morning',
          'repeatPattern': {'type': 'daily', 'interval': 1},
        });
        break;

      case 'twice daily':
      case '2 times per day':
      case 'bid':
        reminders.addAll([
          {
            'scheduledTime': _combineDateTime(startDate, morningTime),
            'instructions': 'Morning dose',
            'repeatPattern': {'type': 'daily', 'interval': 1},
          },
          {
            'scheduledTime': _combineDateTime(startDate, eveningTime),
            'instructions': 'Evening dose',
            'repeatPattern': {'type': 'daily', 'interval': 1},
          },
        ]);
        break;

      case 'three times daily':
      case '3 times per day':
      case 'tid':
        reminders.addAll([
          {
            'scheduledTime': _combineDateTime(startDate, morningTime),
            'instructions': 'Morning dose',
            'repeatPattern': {'type': 'daily', 'interval': 1},
          },
          {
            'scheduledTime': _combineDateTime(startDate, afternoonTime),
            'instructions': 'Afternoon dose',
            'repeatPattern': {'type': 'daily', 'interval': 1},
          },
          {
            'scheduledTime': _combineDateTime(startDate, eveningTime),
            'instructions': 'Evening dose',
            'repeatPattern': {'type': 'daily', 'interval': 1},
          },
        ]);
        break;

      case 'four times daily':
      case '4 times per day':
      case 'qid':
        reminders.addAll([
          {
            'scheduledTime': _combineDateTime(startDate, morningTime),
            'instructions': 'Morning dose',
            'repeatPattern': {'type': 'daily', 'interval': 1},
          },
          {
            'scheduledTime': _combineDateTime(startDate, afternoonTime),
            'instructions': 'Afternoon dose',
            'repeatPattern': {'type': 'daily', 'interval': 1},
          },
          {
            'scheduledTime': _combineDateTime(startDate, eveningTime),
            'instructions': 'Evening dose',
            'repeatPattern': {'type': 'daily', 'interval': 1},
          },
          {
            'scheduledTime': _combineDateTime(startDate, nightTime),
            'instructions': 'Night dose',
            'repeatPattern': {'type': 'daily', 'interval': 1},
          },
        ]);
        break;

      default:
        // Default to once daily if frequency is not recognized
        reminders.add({
          'scheduledTime': _combineDateTime(startDate, morningTime),
          'instructions': 'Take as prescribed',
          'repeatPattern': {'type': 'daily', 'interval': 1},
        });
    }

    return reminders;
  }

  // Helper method to combine date and time
  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Schedule local notification
  Future<void> _scheduleLocalNotification(Map<String, dynamic> reminder) async {
    try {
      final scheduledTime = tz.TZDateTime.from(
        DateTime.parse(reminder['scheduled_time']),
        tz.local,
      );
      final now = DateTime.now();

      // Only schedule if the time is in the future
      if (scheduledTime.isAfter(now)) {
        final id = reminder['id'].hashCode;
        
        const androidDetails = AndroidNotificationDetails(
          'health_reminders',
          'Health Reminders',
          channelDescription: 'Medication and appointment reminders',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notificationsPlugin.zonedSchedule(
          id,
          reminder['title'],
          reminder['description'],
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Check for due reminders and send notifications
  Future<void> _checkAndSendDueReminders() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      // Get reminders that are due (within last 5 minutes) and not yet sent
      final dueReminders = await _supabase
          .from('reminders')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('is_completed', false)
          .eq('notification_sent', false)
          .gte('scheduled_time', fiveMinutesAgo.toIso8601String())
          .lte('scheduled_time', now.toIso8601String());

      for (final reminder in dueReminders) {
        // Mark as notification sent
        await _supabase
            .from('reminders')
            .update({'notification_sent': true})
            .eq('id', reminder['id']);

        // Handle recurring reminders
        await _handleRecurringReminder(reminder);
      }
    } catch (e) {
      print('Error checking due reminders: $e');
    }
  }

  // Handle recurring reminders
  Future<void> _handleRecurringReminder(Map<String, dynamic> reminder) async {
    try {
      final repeatPattern = reminder['repeat_pattern'] as Map<String, dynamic>?;
      if (repeatPattern == null) return;

      final currentTime = DateTime.parse(reminder['scheduled_time']);
      DateTime? nextTime;

      switch (repeatPattern['type']) {
        case 'daily':
          final interval = repeatPattern['interval'] as int? ?? 1;
          nextTime = currentTime.add(Duration(days: interval));
          break;
        
        case 'weekly':
          final interval = repeatPattern['interval'] as int? ?? 1;
          nextTime = currentTime.add(Duration(days: 7 * interval));
          break;
          
        case 'monthly':
          final interval = repeatPattern['interval'] as int? ?? 1;
          nextTime = DateTime(
            currentTime.year,
            currentTime.month + interval,
            currentTime.day,
            currentTime.hour,
            currentTime.minute,
          );
          break;
      }

      if (nextTime != null) {
        // Create next occurrence
        await createReminder(
          title: reminder['title'],
          description: reminder['description'],
          reminderType: reminder['reminder_type'],
          relatedMedicationId: reminder['related_medication_id'],
          relatedAppointmentId: reminder['related_appointment_id'],
          scheduledTime: nextTime,
          repeatPattern: repeatPattern,
        );
      }
    } catch (e) {
      print('Error handling recurring reminder: $e');
    }
  }

  // Get reminder by ID
  Future<Map<String, dynamic>?> _getReminderById(String reminderId) async {
    try {
      final response = await _supabase
          .from('reminders')
          .select('*')
          .eq('id', reminderId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching reminder by ID: $e');
      return null;
    }
  }

  // Get reminder statistics
  Future<Map<String, dynamic>> getReminderStatistics() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      // Get all reminders for current month
      final reminders = await _supabase
          .from('reminders')
          .select('*')
          .eq('user_id', userId)
          .gte('scheduled_time', startOfMonth.toIso8601String());

      final totalReminders = reminders.length;
      final completedReminders = reminders.where((r) => r['is_completed'] == true).length;
      final medicationReminders = reminders.where((r) => r['reminder_type'] == 'medication').length;
      final appointmentReminders = reminders.where((r) => r['reminder_type'] == 'appointment').length;

      final adherenceRate = totalReminders > 0 ? (completedReminders / totalReminders * 100).round() : 0;

      return {
        'total_reminders': totalReminders,
        'completed_reminders': completedReminders,
        'medication_reminders': medicationReminders,
        'appointment_reminders': appointmentReminders,
        'adherence_rate': adherenceRate,
        'missed_reminders': totalReminders - completedReminders,
      };
    } catch (e) {
      print('Error getting reminder statistics: $e');
      return {};
    }
  }

  // Dispose resources
  void dispose() {
    _reminderCheckTimer?.cancel();
  }
}