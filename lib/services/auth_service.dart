import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthService {
  final _client = SupabaseService.instance.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Get current session
  Session? get currentSession => _client.auth.currentSession;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      // After successful signup, ensure user profile is created
      if (response.user != null && response.session != null) {
        await _ensureUserProfile(response.user!, userData);
      }
      
      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  // Ensure user profile exists (fallback for trigger)
  Future<void> _ensureUserProfile(User user, Map<String, dynamic>? userData) async {
    try {
      // Check if profile already exists
      final existingProfile = await _client
          .from('user_profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create profile manually if trigger didn't work
        final profileData = {
          'id': user.id,
          'email': user.email!,
          'full_name': userData?['full_name'] ?? user.userMetadata?['full_name'] ?? user.email!.split('@')[0],
          'role': userData?['role'] ?? user.userMetadata?['role'] ?? 'patient',
          'phone': userData?['phone'] ?? user.userMetadata?['phone'],
          'gender': userData?['gender'] ?? user.userMetadata?['gender'],
          'date_of_birth': userData?['date_of_birth'] ?? user.userMetadata?['date_of_birth'],
          'blood_group': userData?['blood_group'] ?? user.userMetadata?['blood_group'],
          'emergency_contact_name': userData?['emergency_contact_name'] ?? user.userMetadata?['emergency_contact_name'],
          'emergency_contact_phone': userData?['emergency_contact_phone'] ?? user.userMetadata?['emergency_contact_phone'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _client
            .from('user_profiles')
            .insert(profileData);
        
        print('User profile created manually for user: ${user.id}');
      }
    } catch (error) {
      print('Error ensuring user profile: $error');
      // Don't throw error here as it might prevent login
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // After successful signin, check if user profile exists
      if (response.user != null && response.session != null) {
        await _ensureUserProfile(response.user!, null);
      }
      
      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear the user session globally (both locally and on server)
      await _client.auth.signOut(scope: SignOutScope.global);
      
      // Optional: Clear any additional cached data
      // This ensures the session is completely cleared
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  // Update user password
  Future<UserResponse> updatePassword({required String password}) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: password),
      );
      return response;
    } catch (error) {
      throw Exception('Password update failed: $error');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response;
    } on PostgrestException catch (error) {
      print('Supabase error getting profile: ${error.message}');
      throw Exception('Failed to fetch user profile: ${error.message}');
    } catch (error) {
      print('General error getting profile: $error');
      throw Exception('Failed to fetch user profile: $error');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> updates) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // First check if profile exists
      final existingProfile = await _client
          .from('user_profiles')
          .select('id')
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile if it doesn't exist
        updates['id'] = currentUser!.id;
        updates['email'] = currentUser!.email;
        updates['created_at'] = DateTime.now().toIso8601String();
        
        final response = await _client
            .from('user_profiles')
            .insert(updates)
            .select()
            .single();

        return response;
      } else {
        // Update existing profile
        final response = await _client
            .from('user_profiles')
            .update(updates)
            .eq('id', currentUser!.id)
            .select()
            .single();

        return response;
      }
    } on PostgrestException catch (error) {
      print('Supabase error updating profile: ${error.message}');
      print('Error details: ${error.details}');
      print('Error hint: ${error.hint}');
      throw Exception('Failed to update user profile: ${error.message}');
    } catch (error) {
      print('General error updating profile: $error');
      throw Exception('Failed to update user profile: $error');
    }
  }

  // Create or update user profile
  Future<Map<String, dynamic>> createOrUpdateProfile(
      Map<String, dynamic> profileData) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      profileData['id'] = currentUser!.id;
      profileData['email'] = currentUser!.email;

      final response = await _client
          .from('user_profiles')
          .upsert(profileData)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create/update profile: $error');
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('email')
          .eq('email', email)
          .limit(1);

      return response.isEmpty;
    } catch (error) {
      // If there's an error, assume email might be taken
      return false;
    }
  }

  // Get user role
  Future<String> getUserRole() async {
    if (!isAuthenticated) return 'guest';

    try {
      final profile = await getUserProfile();
      return profile?['role'] ?? 'patient';
    } catch (error) {
      return 'patient'; // Default role
    }
  }

  // Update user avatar
  Future<String?> uploadAvatar(String filePath) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final fileBytes = await File(filePath).readAsBytes();
      
      final file = await _client.storage
          .from('profile-images')
          .uploadBinary('${currentUser!.id}/avatar.jpg', fileBytes);

      final url = _client.storage
          .from('profile-images')
          .getPublicUrl('${currentUser!.id}/avatar.jpg');

      // Update profile with avatar URL
      await updateUserProfile({'profile_picture_url': url});

      return url;
    } catch (error) {
      throw Exception('Failed to upload avatar: $error');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // First delete user profile data
      await _client.from('user_profiles').delete().eq('id', currentUser!.id);

      // Then sign out (Supabase handles auth user deletion server-side)
      await signOut();
    } catch (error) {
      throw Exception('Failed to delete account: $error');
    }
  }

  // Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      return response;
    } catch (error) {
      throw Exception('Failed to refresh session: $error');
    }
  }
}
