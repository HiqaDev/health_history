import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class ProfileDebugWidget extends StatefulWidget {
  @override
  _ProfileDebugWidgetState createState() => _ProfileDebugWidgetState();
}

class _ProfileDebugWidgetState extends State<ProfileDebugWidget> {
  final AuthService _authService = AuthService();
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _runDebugChecks();
  }

  Future<void> _runDebugChecks() async {
    String info = '';
    
    try {
      // Check if user is authenticated
      info += 'User authenticated: ${_authService.isAuthenticated}\n';
      
      if (_authService.isAuthenticated) {
        info += 'Current user ID: ${_authService.currentUser?.id}\n';
        info += 'Current user email: ${_authService.currentUser?.email}\n';
        
        // Test connection to Supabase
        final client = SupabaseService.instance.client;
        info += 'Supabase client configured: ${client.auth.currentUser != null ? 'YES' : 'NO'}\n';
        
        // Try to fetch user profile
        try {
          final profile = await _authService.getUserProfile();
          info += 'Profile fetch result: ${profile != null ? 'SUCCESS' : 'NULL'}\n';
          if (profile != null) {
            info += 'Profile data: $profile\n';
          }
        } catch (e) {
          info += 'Profile fetch error: $e\n';
        }
        
        // Test profile update with minimal data
        try {
          final testUpdate = {'updated_at': DateTime.now().toIso8601String()};
          await _authService.updateUserProfile(testUpdate);
          info += 'Profile update test: SUCCESS\n';
        } catch (e) {
          info += 'Profile update test error: $e\n';
        }
      }
    } catch (e) {
      info += 'Debug error: $e\n';
    }
    
    setState(() {
      _debugInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile Debug')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debug Information:', 
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_debugInfo),
              ),
            ),
            ElevatedButton(
              onPressed: _runDebugChecks,
              child: Text('Refresh Debug Info'),
            ),
          ],
        ),
      ),
    );
  }
}