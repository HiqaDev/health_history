import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/medication_models.dart';

/// Individual medication card with status indicators and quick actions
/// Displays medication details and provides swipe gestures for additional options
class MedicationCardWidget extends StatelessWidget {
  final MedicationReminder medication;
  final VoidCallback onTakeNow;
  final VoidCallback onSkipDose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const MedicationCardWidget({
    super.key,
    required this.medication,
    required this.onTakeNow,
    required this.onSkipDose,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(medication.id),
      background: _buildSwipeBackground(theme, isLeft: true),
      secondaryBackground: _buildSwipeBackground(theme, isLeft: false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
        } else {
          onDelete();
        }
        return false; // Don't actually dismiss
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with medication name and status
                Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(theme),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Medication name
                    Expanded(
                      child: Text(
                        medication.drugName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Time
                    Text(
                      medication.scheduledTime,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Dosage and frequency
                Row(
                  children: [
                    Icon(
                      Icons.medication,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      medication.dosage,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      medication.frequency,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    // Take Now button
                    if (medication.status == MedicationStatus.upcoming ||
                        medication.status == MedicationStatus.missed)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onTakeNow,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Take Now'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.tertiary,
                            side: BorderSide(color: theme.colorScheme.tertiary),
                          ),
                        ),
                      ),

                    if (medication.status == MedicationStatus.upcoming ||
                        medication.status == MedicationStatus.missed) ...[
                      const SizedBox(width: 12),

                      // Skip Dose button
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onSkipDose,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Skip'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],

                    if (medication.status == MedicationStatus.taken)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.tertiary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Taken at ${medication.takenTime ?? medication.scheduledTime}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Special instructions or notes
                if (medication.notes != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            medication.notes!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(ThemeData theme, {required bool isLeft}) {
    return Container(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLeft ? theme.colorScheme.primary : theme.colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLeft ? Icons.edit : Icons.delete,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            isLeft ? 'Edit' : 'Delete',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ThemeData theme) {
    switch (medication.status) {
      case MedicationStatus.taken:
        return theme.colorScheme.tertiary; // Green
      case MedicationStatus.missed:
        return theme.colorScheme.error; // Red
      case MedicationStatus.upcoming:
        return theme.colorScheme.primary; // Blue
    }
  }
}
