import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDataService {
  // Клиент Supabase
  final SupabaseClient _client = Supabase.instance.client;

  /// Получить список клубов (с возможностью сортировки)
  Future<List<Map<String, dynamic>>> fetchClubs({String sortBy = 'rating'}) async {
    final orderColumn = switch (sortBy) {
      'name' => 'name',
      'rating' => 'rating',
      _ => 'created_at',
    };

    try {
      final response = await _client
          .from('clubs')
          .select('*')
          .order(orderColumn, ascending: false);

      // Supabase возвращает dynamic → приводим к List<Map<String, dynamic>>
      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      print('Supabase error while fetching clubs: ${e.message}');
      throw Exception('Ошибка при получении клубов: ${e.message}');
    } catch (e) {
      print('General error while fetching clubs: $e');
      return [];
    }
  }

  /// Получить данные одного клуба по ID
  Future<Map<String, dynamic>?> fetchClubById(String clubId) async {
    try {
      final response = await _client
          .from('clubs')
          .select('*')
          .eq('id', clubId)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      print('Supabase error while fetching club: ${e.message}');
      return null;
    } catch (e) {
      print('General error while fetching club: $e');
      return null;
    }
  }
}
