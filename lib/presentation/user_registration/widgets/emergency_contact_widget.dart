import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmergencyContactWidget extends StatefulWidget {
  final List<Map<String, String>> emergencyContacts;
  final Function(List<Map<String, String>>) onContactsChanged;

  const EmergencyContactWidget({
    super.key,
    required this.emergencyContacts,
    required this.onContactsChanged,
  });

  @override
  State<EmergencyContactWidget> createState() => _EmergencyContactWidgetState();
}

class _EmergencyContactWidgetState extends State<EmergencyContactWidget> {
  static const List<String> relationships = [
    'Spouse',
    'Parent',
    'Child',
    'Sibling',
    'Friend',
    'Doctor',
    'Other',
  ];

  void _addEmergencyContact() {
    final newContact = {
      'name': '',
      'phone': '',
      'relationship': 'Spouse',
    };

    final updatedContacts =
        List<Map<String, String>>.from(widget.emergencyContacts);
    updatedContacts.add(newContact);
    widget.onContactsChanged(updatedContacts);
  }

  void _removeEmergencyContact(int index) {
    final updatedContacts =
        List<Map<String, String>>.from(widget.emergencyContacts);
    updatedContacts.removeAt(index);
    widget.onContactsChanged(updatedContacts);
  }

  void _updateContact(int index, String field, String value) {
    final updatedContacts =
        List<Map<String, String>>.from(widget.emergencyContacts);
    updatedContacts[index][field] = value;
    widget.onContactsChanged(updatedContacts);
  }

  void _showRelationshipPicker(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Select Relationship',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 2.h),
            ...relationships.map((relationship) => ListTile(
                  title: Text(
                    relationship,
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                  trailing: widget.emergencyContacts[index]['relationship'] ==
                          relationship
                      ? CustomIconWidget(
                          iconName: 'check',
                          size: 5.w,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    _updateContact(index, 'relationship', relationship);
                    Navigator.pop(context);
                  },
                )),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(int index) {
    final contact = widget.emergencyContacts[index];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Contact ${index + 1}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.emergencyContacts.length > 1)
                GestureDetector(
                  onTap: () => _removeEmergencyContact(index),
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      size: 4.w,
                      color: AppTheme.errorLight,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          TextFormField(
            initialValue: contact['name'],
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter contact name',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'person',
                  size: 5.w,
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            onChanged: (value) => _updateContact(index, 'name', value),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter contact name';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
          TextFormField(
            initialValue: contact['phone'],
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter phone number',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'phone',
                  size: 5.w,
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) => _updateContact(index, 'phone', value),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter phone number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
          GestureDetector(
            onTap: () => _showRelationshipPicker(index),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: _getRelationshipIcon(
                        contact['relationship'] ?? 'Spouse'),
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      contact['relationship'] ?? 'Select Relationship',
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'keyboard_arrow_down',
                    size: 5.w,
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRelationshipIcon(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'spouse':
        return 'favorite';
      case 'parent':
        return 'elderly';
      case 'child':
        return 'child_care';
      case 'sibling':
        return 'people';
      case 'friend':
        return 'group';
      case 'doctor':
        return 'local_hospital';
      default:
        return 'person';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Emergency Contacts',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            const Spacer(),
            if (widget.emergencyContacts.length < 3)
              GestureDetector(
                onTap: _addEmergencyContact,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'add',
                        size: 4.w,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Add',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 2.h),
        ...widget.emergencyContacts.asMap().entries.map((entry) {
          return _buildContactCard(entry.key);
        }),
        if (widget.emergencyContacts.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.dividerColor,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'contact_emergency',
                  size: 12.w,
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.4),
                ),
                SizedBox(height: 2.h),
                Text(
                  'No emergency contacts added',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 1.h),
                GestureDetector(
                  onTap: _addEmergencyContact,
                  child: Text(
                    'Add your first emergency contact',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
