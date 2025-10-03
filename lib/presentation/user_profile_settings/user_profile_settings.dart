import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/auth_service.dart';
import '../../services/health_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class UserProfileSettings extends StatefulWidget {
  const UserProfileSettings({Key? key}) : super(key: key);

  @override
  State<UserProfileSettings> createState() => _UserProfileSettingsState();
}

class _UserProfileSettingsState extends State<UserProfileSettings> {
  final AuthService _authService = AuthService();
  final HealthService _healthService = HealthService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _medicalConditionsController = TextEditingController();

  String _selectedBloodGroup = 'Not specified';
  String _selectedGender = 'Not specified';
  DateTime? _selectedDateOfBirth;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _bloodGroups = [
    'Not specified',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  final List<String> _genders = ['Not specified', 'Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);

      final profile = await _authService.getUserProfile();
      if (profile != null) {
        _nameController.text = profile['full_name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _addressController.text = profile['address'] ?? '';
        // Handle emergency contact - try multiple field names for compatibility
        _emergencyContactController.text = profile['emergency_contact'] ?? 
                                         profile['emergency_contact_name'] ?? '';
        _allergiesController.text = profile['allergies'] ?? '';
        _medicationsController.text = profile['medications'] ?? '';
        _medicalConditionsController.text = profile['medical_conditions'] ?? '';
        _selectedBloodGroup = profile['blood_group'] ?? 'Not specified';
        _selectedGender = profile['gender'] ?? 'Not specified';

        if (profile['date_of_birth'] != null) {
          try {
            _selectedDateOfBirth = DateTime.parse(profile['date_of_birth']);
          } catch (dateError) {
            print('Error parsing date: $dateError');
            _selectedDateOfBirth = null;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final profileData = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'emergency_contact': _emergencyContactController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'medical_conditions': _medicalConditionsController.text.trim(),
        'blood_group':
            _selectedBloodGroup == 'Not specified' ? null : _selectedBloodGroup,
        'gender': _selectedGender == 'Not specified' ? null : _selectedGender,
        'date_of_birth': _selectedDateOfBirth?.toIso8601String().split('T')[0], // Keep only date part
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null or empty values to avoid unnecessary updates
      profileData.removeWhere((key, value) => 
          value == null || (value is String && value.isEmpty));

      print('Saving profile data: $profileData'); // Debug log

      await _authService.updateUserProfile(profileData);

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving profile: $e'); // Debug log
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const CustomAppBar(
        title: 'Profile Settings',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    _buildProfilePictureSection(),
                    SizedBox(height: 24.sp),

                    // Personal Information
                    _buildPersonalInformation(),
                    SizedBox(height: 24.sp),

                    // Medical Information
                    _buildMedicalInformation(),
                    SizedBox(height: 24.sp),

                    // Emergency Contact
                    _buildEmergencyContact(),
                    SizedBox(height: 24.sp),

                    // Account Settings
                    _buildAccountSettings(),
                    SizedBox(height: 32.sp),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryLight,
                          padding: EdgeInsets.symmetric(vertical: 16.sp),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40.sp,
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                _nameController.text.isNotEmpty
                    ? _nameController.text[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 12.sp),
            TextButton.icon(
              onPressed: () {
                // TODO: Implement photo upload
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Photo upload feature coming soon')),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Change Photo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.sp),

            // Full Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16.sp),

            // Email (read-only)
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              enabled: false,
            ),
            SizedBox(height: 16.sp),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.sp),

            // Date of Birth
            GestureDetector(
              onTap: _selectDateOfBirth,
              child: Container(
                padding:
                    EdgeInsets.symmetric(vertical: 16.sp, horizontal: 12.sp),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.dividerLight),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppTheme.textSecondaryLight),
                    SizedBox(width: 12.sp),
                    Text(
                      _selectedDateOfBirth != null
                          ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                          : 'Select Date of Birth',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: _selectedDateOfBirth != null
                            ? AppTheme.textPrimaryLight
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.sp),

            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.wc),
              ),
              items: _genders.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            SizedBox(height: 16.sp),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.sp),

            // Blood Group
            DropdownButtonFormField<String>(
              value: _selectedBloodGroup,
              decoration: const InputDecoration(
                labelText: 'Blood Group',
                prefixIcon: Icon(Icons.bloodtype),
              ),
              items: _bloodGroups.map((bloodGroup) {
                return DropdownMenuItem(
                  value: bloodGroup,
                  child: Text(bloodGroup),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBloodGroup = value!;
                });
              },
            ),
            SizedBox(height: 16.sp),

            // Allergies
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Allergies',
                prefixIcon: Icon(Icons.warning),
                hintText: 'List any allergies (food, medicine, etc.)',
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16.sp),

            // Current Medications
            TextFormField(
              controller: _medicationsController,
              decoration: const InputDecoration(
                labelText: 'Current Medications',
                prefixIcon: Icon(Icons.medication),
                hintText: 'List current medications and dosages',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.sp),

            // Medical Conditions
            TextFormField(
              controller: _medicalConditionsController,
              decoration: const InputDecoration(
                labelText: 'Medical Conditions',
                prefixIcon: Icon(Icons.medical_services),
                hintText: 'List chronic conditions, past surgeries, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContact() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contact',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.sp),
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact',
                prefixIcon: Icon(Icons.contact_phone),
                hintText: 'Name and phone number',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.sp),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implement change password
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Change password feature coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implement notification settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Notification settings feature coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Settings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implement privacy settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Privacy settings feature coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: AppTheme.accentLight),
              title: Text('Sign Out',
                  style: TextStyle(color: AppTheme.accentLight)),
              onTap: _showSignOutDialog,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login-screen',
                (route) => false,
              );
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.accentLight),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }
}
