import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/auth_service.dart';
import '../../services/health_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class EmergencyAccess extends StatefulWidget {
  const EmergencyAccess({Key? key}) : super(key: key);

  @override
  State<EmergencyAccess> createState() => _EmergencyAccessState();
}

class _EmergencyAccessState extends State<EmergencyAccess> {
  final AuthService _authService = AuthService();
  final HealthService _healthService = HealthService();
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _emergencyContacts = [];
  List<Map<String, dynamic>> _criticalMedicalInfo = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    try {
      setState(() => _isLoading = true);

      if (!_authService.isAuthenticated) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please log in to access emergency data')),
          );
        }
        return;
      }

      final currentUserId = _authService.currentUser!.id;

      // Load user profile
      _userProfile = await _authService.getUserProfile();

      // Load emergency contacts with userId parameter
      _emergencyContacts =
          await _healthService.getEmergencyContacts(currentUserId);

      // Load critical medical info with userId parameter
      _criticalMedicalInfo =
          await _healthService.getCriticalMedicalInfo(currentUserId);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading emergency data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Emergency Access',
        backgroundColor: AppTheme.accentLight,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency QR Code
                  _buildEmergencyQRCard(),
                  SizedBox(height: 20.sp),

                  // Critical Medical Information
                  _buildCriticalMedicalInfo(),
                  SizedBox(height: 20.sp),

                  // Blood Type & Allergies
                  _buildBloodTypeAllergies(),
                  SizedBox(height: 20.sp),

                  // Emergency Contacts
                  _buildEmergencyContacts(),
                  SizedBox(height: 20.sp),

                  // Current Medications
                  _buildCurrentMedications(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmergencyQRCard() {
    return Card(
      color: AppTheme.accentLight,
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          children: [
            Icon(
              Icons.qr_code,
              size: 60.sp,
              color: Colors.white,
            ),
            SizedBox(height: 12.sp),
            Text(
              'Emergency QR Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Scan for instant access to critical medical info',
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalMedicalInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: AppTheme.accentLight, size: 24.sp),
                SizedBox(width: 8.sp),
                Text(
                  'Critical Medical Information',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.sp),
            if (_criticalMedicalInfo.isEmpty)
              Text(
                'No critical medical information recorded',
                style: TextStyle(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 14.sp,
                ),
              )
            else
              ..._criticalMedicalInfo.map((info) => Padding(
                    padding: EdgeInsets.only(bottom: 8.sp),
                    child: Row(
                      children: [
                        Container(
                          width: 8.sp,
                          height: 8.sp,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: Text(
                            info['title'] ??
                                info['description'] ??
                                'Unknown condition',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodTypeAllergies() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blood Type & Medical Info',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.sp),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Type',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      Text(
                        _userProfile?['blood_group'] ?? 'Not specified',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1.sp,
                  height: 40.sp,
                  color: AppTheme.dividerLight,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Contact',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                        Text(
                          _userProfile?['emergency_contact_name'] ??
                              'Not specified',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_userProfile?['emergency_contact_phone'] != null)
                          Text(
                            _userProfile!['emergency_contact_phone'],
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone,
                    color: AppTheme.primaryLight, size: 24.sp),
                SizedBox(width: 8.sp),
                Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.sp),
            if (_emergencyContacts.isEmpty)
              Text(
                'No emergency contacts added',
                style: TextStyle(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 14.sp,
                ),
              )
            else
              ..._emergencyContacts.map((contact) => Container(
                    margin: EdgeInsets.only(bottom: 12.sp),
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(8.sp),
                      border: Border.all(color: AppTheme.dividerLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20.sp,
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            (contact['name'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.sp,
                                ),
                              ),
                              Text(
                                contact['relationship'] ??
                                    'Unknown relationship',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryLight,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // TODO: Implement call functionality
                          },
                          icon: Icon(
                            Icons.call,
                            color: AppTheme.successLight,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMedications() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication,
                    color: AppTheme.warningLight, size: 24.sp),
                SizedBox(width: 8.sp),
                Text(
                  'Current Medications',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.sp),
            Text(
              'Critical medications for emergency situations',
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 12.sp),
            // Add your medication widgets here
            Text(
              'No critical medications recorded',
              style: TextStyle(
                fontSize: 14.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
