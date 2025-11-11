import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_navigation.dart';
import 'utils/app_colors.dart';

const supabaseURL = 'https://uhghujpoonfwldierekd.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoZ2h1anBvb25md2xkaWVyZWtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4NjA3OTUsImV4cCI6MjA3ODQzNjc5NX0.iO6qMsVdmIfzTl-zgBdmX_Qb8_cMFDjIFQ5BfvcztXU';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Инициализация Supabase
  await Supabase.initialize(
    url: supabaseURL,
    anonKey: supabaseKey,
  );

  final supabase = Supabase.instance.client;

  // Попытка анонимного входа
  try {
    if (supabase.auth.currentUser == null) {
      final response = await supabase.auth.signInAnonymously();
      if (response.user != null) {
        debugPrint('✅ Анонимный вход выполнен, uid: ${response.user!.id}');
      } else {
        debugPrint('⚠️ Анонимный вход не сработал');
      }
    } else {
      debugPrint('✅ Пользователь уже вошёл: ${supabase.auth.currentUser!.id}');
    }
  } on AuthApiException catch (e) {
    debugPrint('❌ Ошибка аутентификации: ${e.message}');
  } catch (e) {
    debugPrint('❌ Неизвестная ошибка при аутентификации: $e');
  }

  // 2️⃣ Запуск приложения
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindClub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'SF Pro Display',
        primaryColor: AppColors.accentOrange,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentOrange,
          background: AppColors.background,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}
