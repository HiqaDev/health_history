import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/blood_group_selector_widget.dart';
import './widgets/emergency_contact_widget.dart';
import './widgets/password_strength_widget.dart';
import './widgets/profile_photo_widget.dart';

class UserRegistration extends StatefulWidget {
  const UserRegistration({super.key});

  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _authService = AuthService();

  // Form controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form state
  DateTime? _selectedDateOfBirth;
  String? _selectedBloodGroup;
  String? _selectedGender;
  String? _profilePhotoPath;
  List<Map<String, String>> _emergencyContacts = [];
  bool _acceptTerms = false;
  bool _acceptHipaa = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isEditMode = false;

  // Focus nodes for keyboard handling
  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emergencyContacts = [
      {'name': '', 'phone': '', 'relationship': 'Spouse'},
    ];
    _checkIfEditMode();
  }

  void _checkIfEditMode() async {
    // Check if user is editing existing profile
    if (_authService.isAuthenticated) {
      _isEditMode = true;
      await _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        setState(() {
          _fullNameController.text = profile['full_name'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _selectedGender = _capitalizeGender(profile['gender']);
          _selectedBloodGroup = profile['blood_group'];
          if (profile['date_of_birth'] != null) {
            _selectedDateOfBirth = DateTime.parse(profile['date_of_birth']);
          }
          if (profile['emergency_contact_name'] != null) {
            _emergencyContacts = [
              {
                'name': profile['emergency_contact_name'] ?? '',
                'phone': profile['emergency_contact_phone'] ?? '',
                'relationship': 'Emergency Contact',
              },
            ];
          }
          // Skip terms acceptance in edit mode
          _acceptTerms = true;
          _acceptHipaa = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    if (_isEditMode) {
      // For edit mode, don't require password fields
      return _formKey.currentState?.validate() == true &&
          _selectedDateOfBirth != null &&
          _selectedBloodGroup != null &&
          _selectedGender != null &&
          _emergencyContacts.any(
            (contact) =>
                contact['name']!.isNotEmpty && contact['phone']!.isNotEmpty,
          );
    }

    // For registration mode, require all fields including terms
    return _formKey.currentState?.validate() == true &&
        _selectedDateOfBirth != null &&
        _selectedBloodGroup != null &&
        _selectedGender != null &&
        _emergencyContacts.any(
          (contact) =>
              contact['name']!.isNotEmpty && contact['phone']!.isNotEmpty,
        ) &&
        _acceptTerms &&
        _acceptHipaa;
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.lightTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _createAccount() async {
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditMode) {
        // Update existing profile
        await _updateProfile();
      } else {
        // Create new account
        await _registerNewUser();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.contains('Sign-up failed:')) {
          errorMessage = errorMessage.replaceFirst('Sign-up failed: ', '');
        }

        // Handle common Supabase errors
        if (errorMessage.contains('User already registered')) {
          errorMessage =
              'This email is already registered. Please sign in instead.';
        } else if (errorMessage.contains('Invalid email')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (errorMessage.contains('Password should be at least')) {
          errorMessage = 'Password should be at least 6 characters long.';
        } else if (errorMessage.contains('Network')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        }

        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _registerNewUser() async {
    // Check if email is already taken
    final isEmailAvailable = await _authService.isEmailAvailable(
      _emailController.text.trim(),
    );

    if (!isEmailAvailable) {
      if (mounted) {
        _showErrorDialog(
          'This email address is already in use. Please use a different email or try signing in.',
        );
      }
      return;
    }

    // Prepare user metadata
    final userData = {
      'full_name': _fullNameController.text.trim(),
      'role': 'patient',
      'phone': _phoneController.text.trim(),
      'gender': _selectedGender?.toLowerCase(),
      'date_of_birth': _selectedDateOfBirth?.toIso8601String().split('T')[0],
      'blood_group': _selectedBloodGroup,
      'emergency_contact_name':
          _emergencyContacts.isNotEmpty ? _emergencyContacts[0]['name'] : null,
      'emergency_contact_phone':
          _emergencyContacts.isNotEmpty ? _emergencyContacts[0]['phone'] : null,
    };

    // Create account with Supabase Auth
    final response = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      userData: userData,
    );

    if (response.user != null) {
      // Account created successfully, profile will be created by trigger
      if (mounted) {
        _showSuccessDialog();
      }
    } else {
      throw Exception('Failed to create account. Please try again.');
    }
  }

  Future<void> _updateProfile() async {
    // Prepare updated user data
    final userData = {
      'full_name': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'gender': _selectedGender?.toLowerCase(),
      'date_of_birth': _selectedDateOfBirth?.toIso8601String().split('T')[0],
      'blood_group': _selectedBloodGroup,
      'emergency_contact_name':
          _emergencyContacts.isNotEmpty ? _emergencyContacts[0]['name'] : null,
      'emergency_contact_phone':
          _emergencyContacts.isNotEmpty ? _emergencyContacts[0]['phone'] : null,
    };

    // Update profile
    final result = await _authService.updateUserProfile(userData);

    if (result is Map<String, dynamic> && result['success'] == true) {
      if (mounted) {
        _showProfileUpdateSuccessDialog();
      }
    } else {
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  void _showProfileUpdateSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: AppTheme.successLight.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'check',
                      size: 10.w,
                      color: AppTheme.successLight,
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Profile Updated Successfully!',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Your profile information has been updated.',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pop(context); // Return to previous screen
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: AppTheme.successLight.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'check',
                      size: 10.w,
                      color: AppTheme.successLight,
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Account Created Successfully!',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Welcome to Health History. Your secure digital health vault is ready.',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Please check your email to verify your account.',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/health-dashboard',
                        (route) => false,
                      );
                    }
                  });
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CustomIconWidget(
                  iconName: 'error',
                  size: 6.w,
                  color: AppTheme.errorLight,
                ),
                SizedBox(width: 2.w),
                const Text('Registration Error'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Terms & Conditions'),
            content: SizedBox(
              width: double.maxFinite,
              height: 40.h,
              child: SingleChildScrollView(
                child: Text(
                  '''By creating an account, you agree to our Terms of Service and Privacy Policy.

HEALTH DATA PRIVACY:
• Your medical information is encrypted and stored securely
• We comply with HIPAA regulations for health data protection
• You control who can access your medical records
• Data is never shared without your explicit consent

ACCOUNT SECURITY:
• Use a strong, unique password for your account
• Enable biometric authentication when available
• Report any suspicious activity immediately
• Keep your emergency contacts updated

MEDICAL DISCLAIMER:
• This app is for record-keeping purposes only
• Always consult healthcare professionals for medical advice
• Emergency features do not replace calling emergency services
• Verify all medical information with your healthcare provider

By proceeding, you acknowledge that you have read and understood these terms.''',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showHipaaDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('HIPAA Compliance Notice'),
            content: SizedBox(
              width: double.maxFinite,
              height: 40.h,
              child: SingleChildScrollView(
                child: Text(
                  '''HEALTH INSURANCE PORTABILITY AND ACCOUNTABILITY ACT (HIPAA) NOTICE

PROTECTED HEALTH INFORMATION:
• Your health information is protected under HIPAA regulations
• We implement administrative, physical, and technical safeguards
• Access to your data is strictly controlled and monitored
• All data transmissions are encrypted using industry standards

YOUR RIGHTS:
• Right to access your health information
• Right to request corrections to your health information
• Right to request restrictions on use or disclosure
• Right to request confidential communications
• Right to file a complaint if you believe your rights have been violated

DATA USAGE:
• Health information is used only for treatment, payment, and healthcare operations
• Marketing communications require separate authorization
• Research use requires de-identification or specific authorization
• Emergency access may override normal privacy restrictions

BREACH NOTIFICATION:
• You will be notified of any unauthorized access to your health information
• Notifications will be provided within 60 days of discovery
• Appropriate authorities will be notified as required by law

By accepting, you acknowledge understanding of your HIPAA rights and our privacy practices.''',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // Gender Selection Widget
  Widget _buildGenderSelector() {
    final hasError = _selectedGender == null && _isLoading == false && _formKey.currentState?.validate() == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender *',
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: hasError ? Colors.red : null,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children:
              ['Male', 'Female', 'Other'].map((gender) {
                final isSelected = _selectedGender == gender;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = gender),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: gender != 'Other' ? 2.w : 0,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.1)
                                : AppTheme.lightTheme.colorScheme.surface,
                        border: Border.all(
                          color:
                              hasError
                                  ? Colors.red
                                  : isSelected
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme.lightTheme.dividerColor,
                          width: isSelected || hasError ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        gender,
                        textAlign: TextAlign.center,
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                              color:
                                  isSelected
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme
                                          .lightTheme
                                          .colorScheme
                                          .onSurface,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Text(
              'Please select a gender',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to capitalize gender from database
  String? _capitalizeGender(String? gender) {
    if (gender == null) return null;
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Profile' : 'Create Account',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back_ios',
            size: 5.w,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  _isEditMode ? 'Update Your Profile' : 'Join Health History',
                  style: AppTheme.lightTheme.textTheme.headlineSmall,
                ),
                SizedBox(height: 1.h),
                Text(
                  _isEditMode
                      ? 'Keep your health profile information up to date.'
                      : 'Create your secure digital health vault to store and manage your medical records safely.',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),

                // Profile Photo
                Center(
                  child: ProfilePhotoWidget(
                    initialPhotoPath: _profilePhotoPath,
                    onPhotoSelected: (path) {
                      setState(() {
                        _profilePhotoPath = path;
                      });
                    },
                  ),
                ),
                SizedBox(height: 4.h),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  focusNode: _fullNameFocus,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
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
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),

                // Email
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  enabled: !_isEditMode, // Disable in edit mode
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email address',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'email',
                        size: 5.w,
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
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
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),

                // Gender Selection
                _buildGenderSelector(),
                SizedBox(height: 3.h),

                // Date of Birth
                GestureDetector(
                  onTap: _selectDateOfBirth,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 3.h,
                    ),
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
                          iconName: 'calendar_today',
                          size: 5.w,
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            _selectedDateOfBirth != null
                                ? _formatDate(_selectedDateOfBirth!)
                                : 'Select Date of Birth',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                                  color:
                                      _selectedDateOfBirth != null
                                          ? AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurface
                                          : AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                ),
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
                SizedBox(height: 3.h),

                // Blood Group
                BloodGroupSelectorWidget(
                  selectedBloodGroup: _selectedBloodGroup,
                  onBloodGroupSelected: (bloodGroup) {
                    setState(() {
                      _selectedBloodGroup = bloodGroup;
                    });
                  },
                ),
                SizedBox(height: 4.h),

                // Emergency Contacts
                EmergencyContactWidget(
                  emergencyContacts: _emergencyContacts,
                  onContactsChanged: (contacts) {
                    setState(() {
                      _emergencyContacts = contacts;
                    });
                  },
                ),
                SizedBox(height: 4.h),

                // Password fields only for registration
                if (!_isEditMode) ...[
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Create a strong password',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'lock',
                          size: 5.w,
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: CustomIconWidget(
                          iconName:
                              _obscurePassword
                                  ? 'visibility'
                                  : 'visibility_off',
                          size: 5.w,
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted:
                        (_) => _confirmPasswordFocus.requestFocus(),
                    onChanged: (value) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // Password Strength Indicator
                  PasswordStrengthWidget(password: _passwordController.text),
                  SizedBox(height: 3.h),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'lock',
                          size: 5.w,
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: CustomIconWidget(
                          iconName:
                              _obscureConfirmPassword
                                  ? 'visibility'
                                  : 'visibility_off',
                          size: 5.w,
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 4.h),
                ],

                // Terms and conditions only for registration
                if (!_isEditMode) ...[
                  // Terms and Conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _acceptTerms = !_acceptTerms;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: 2.w),
                            child: RichText(
                              text: TextSpan(
                                style: AppTheme.lightTheme.textTheme.bodySmall,
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _showTermsDialog,
                                      child: Text(
                                        'Terms & Conditions',
                                        style: AppTheme
                                            .lightTheme
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  AppTheme
                                                      .lightTheme
                                                      .colorScheme
                                                      .primary,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' and Privacy Policy'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // HIPAA Compliance
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptHipaa,
                        onChanged: (value) {
                          setState(() {
                            _acceptHipaa = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _acceptHipaa = !_acceptHipaa;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: 2.w),
                            child: RichText(
                              text: TextSpan(
                                style: AppTheme.lightTheme.textTheme.bodySmall,
                                children: [
                                  const TextSpan(text: 'I acknowledge the '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _showHipaaDialog,
                                      child: Text(
                                        'HIPAA Privacy Notice',
                                        style: AppTheme
                                            .lightTheme
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  AppTheme
                                                      .lightTheme
                                                      .colorScheme
                                                      .primary,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' and health data privacy practices',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                ],

                // Create Account/Update Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed:
                        _isFormValid() && !_isLoading ? _createAccount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isFormValid()
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 5.w,
                              height: 5.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              _isEditMode ? 'Update Profile' : 'Create Account',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                  ),
                ),
                SizedBox(height: 3.h),

                // Login Link (only for registration)
                if (!_isEditMode) ...[
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/login-screen',
                            );
                          }
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}