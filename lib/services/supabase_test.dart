import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_data_service.dart'; // путь к твоему сервису

// Константы для Supabase (тестовое подключение)
const supabaseUrl = 'https://uhghujpoonfwldierekd.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoZ2h1anBvb25md2xkaWVyZWtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4NjA3OTUsImV4cCI6MjA3ODQzNjc5NX0.iO6qMsVdmIfzTl-zgBdmX_Qb8_cMFDjIFQ5BfvcztXU';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  print('Supabase initialized successfully');

  final dataService = SupabaseDataService();

  // Проверка получения списка клубов
  try {
    final clubs = await dataService.fetchClubs();
    print('Fetched ${clubs.length} clubs:');
    for (var club in clubs) {
      print(' - ${club['name']} (rating: ${club['rating']})');
    }
  } catch (e) {
    print('Error fetching clubs: $e');
  }

  // Проверка получения клуба по ID (подставь реальный ID из базы)
  const testClubId = '1'; 
  try {
    final club = await dataService.fetchClubById(testClubId);
    if (club != null) {
      print('Fetched club by ID $testClubId: ${club['name']}');
    } else {
      print('No club found with ID $testClubId');
    }
  } catch (e) {
    print('Error fetching club by ID: $e');
  }

  print('Supabase test completed');
}
