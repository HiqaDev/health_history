import 'package:flutter/material.dart';

enum MedicationStatus {
  taken,
  missed,
  upcoming,
}

class MedicationReminder {
  final String id;
  final String drugName;
  final String dosage;
  final String frequency;
  final String scheduledTime;
  final String? takenTime;
  final MedicationStatus status;
  final String? notes;
  final DateTime createdAt;

  const MedicationReminder({
    required this.id,
    required this.drugName,
    required this.dosage,
    required this.frequency,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    this.notes,
    required this.createdAt,
  });
}

class AdherenceData {
  final int currentStreak;
  final double weeklyPercentage;
  final double monthlyPercentage;
  final List<double> weeklyData;
  final List<Achievement> achievements;

  const AdherenceData({
    required this.currentStreak,
    required this.weeklyPercentage,
    required this.monthlyPercentage,
    required this.weeklyData,
    required this.achievements,
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockedAt,
  });
}