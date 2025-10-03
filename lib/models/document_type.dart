enum DocumentType {
  prescription,
  labReport,
  insuranceCard,
  identification,
  imaging,
  bill,
  referral,
  vaccination,
  other,
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.prescription:
        return 'Prescription';
      case DocumentType.labReport:
        return 'Lab Report';
      case DocumentType.insuranceCard:
        return 'Insurance Card';
      case DocumentType.identification:
        return 'ID Document';
      case DocumentType.imaging:
        return 'Medical Imaging';
      case DocumentType.bill:
        return 'Medical Bill';
      case DocumentType.referral:
        return 'Referral';
      case DocumentType.vaccination:
        return 'Vaccination Record';
      case DocumentType.other:
        return 'Other';
    }
  }

  String get iconName {
    switch (this) {
      case DocumentType.prescription:
        return 'medication';
      case DocumentType.labReport:
        return 'science';
      case DocumentType.insuranceCard:
        return 'credit_card';
      case DocumentType.identification:
        return 'badge';
      case DocumentType.imaging:
        return 'medical_services';
      case DocumentType.bill:
        return 'receipt';
      case DocumentType.referral:
        return 'assignment';
      case DocumentType.vaccination:
        return 'vaccines';
      case DocumentType.other:
        return 'description';
    }
  }
}