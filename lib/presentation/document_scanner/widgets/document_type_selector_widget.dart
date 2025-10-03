import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet selector for medical document categories
/// Allows users to categorize scanned documents for better organization
class DocumentTypeSelectorWidget extends StatelessWidget {
  final Function(DocumentType) onTypeSelected;
  final DocumentType? selectedType;

  const DocumentTypeSelectorWidget({
    super.key,
    required this.onTypeSelected,
    this.selectedType,
  });

  static const List<DocumentType> documentTypes = [
    DocumentType.prescription,
    DocumentType.labReport,
    DocumentType.insuranceCard,
    DocumentType.identification,
    DocumentType.imaging,
    DocumentType.bill,
    DocumentType.referral,
    DocumentType.vaccination,
    DocumentType.other,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Type',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the type of medical document you\'re scanning',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Document type grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: documentTypes
                  .map((type) => _buildTypeCard(
                        context,
                        type,
                        selectedType == type,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
      BuildContext context, DocumentType type, bool isSelected) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onTypeSelected(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withAlpha(51),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              type.icon,
              size: 24,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Enum for different document types with associated metadata
enum DocumentType {
  prescription('Prescription', Icons.medication),
  labReport('Lab Report', Icons.science),
  insuranceCard('Insurance Card', Icons.credit_card),
  identification('ID Card', Icons.badge),
  imaging('Medical Imaging', Icons.image),
  bill('Medical Bill', Icons.receipt),
  referral('Referral', Icons.assignment),
  vaccination('Vaccination Record', Icons.vaccines),
  other('Other', Icons.description);

  const DocumentType(this.label, this.icon);

  final String label;
  final IconData icon;
}
