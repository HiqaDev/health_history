import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static String? _supabaseUrl;
  static String? _supabaseAnonKey;

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    try {
      // Try to load from environment variables first
      _supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
      _supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

      // If not found in environment, try to load from env.json
      if ((_supabaseUrl?.isEmpty ?? true) || (_supabaseAnonKey?.isEmpty ?? true)) {
        try {
          final String envString = await rootBundle.loadString('env.json');
          final Map<String, dynamic> envData = json.decode(envString);
          
          _supabaseUrl = envData['SUPABASE_URL'];
          _supabaseAnonKey = envData['SUPABASE_ANON_KEY'];
        } catch (e) {
          print('Could not load env.json: $e');
        }
      }

      if ((_supabaseUrl?.isEmpty ?? true) || (_supabaseAnonKey?.isEmpty ?? true)) {
        throw Exception(
            'SUPABASE_URL and SUPABASE_ANON_KEY must be defined in environment variables or env.json file.');
      }

      await Supabase.initialize(
        url: _supabaseUrl!,
        anonKey: _supabaseAnonKey!,
      );

      print('Supabase initialized successfully');
    } catch (e) {
      print('Supabase initialization failed: $e');
      rethrow;
    }
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;
}
