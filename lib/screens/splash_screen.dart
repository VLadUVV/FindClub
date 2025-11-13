import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_navigation.dart';
import '../utils/app_colors.dart';

const supabaseURL = 'https://uhghujpoonfwldierekd.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoZ2h1anBvb25md2xkaWVyZWtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4NjA3OTUsImV4cCI6MjA3ODQzNjc5NX0.iO6qMsVdmIfzTl-zgBdmX_Qb8_cMFDjIFQ5BfvcztXU';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _animation;

  final Duration _spinDuration = const Duration(milliseconds: 1200);
  final Duration _pauseDuration = const Duration(milliseconds: 1800);
  final Duration _minDisplayTime = const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _animationController = AnimationController(
      vsync: this,
      duration: _spinDuration,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(_pauseDuration, () {
          if (mounted) {
            _animationController.reset();
            _animationController.forward();
          }
        });
      }
    });
    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      await Supabase.initialize(
        url: supabaseURL,
        anonKey: supabaseKey,
      );

      final supabase = Supabase.instance.client;

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
      debugPrint('❌ Неизвестная ошибка при инициализации: $e');
    }

    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < _minDisplayTime) {
      await Future.delayed(_minDisplayTime - elapsed);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              RotationTransition(
                turns: _animation,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 50.0, left: 20, right: 20),
                child: Text(
                  "Найди свой клуб по интересам в\nFindClub",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.accentOrange, // Используем ваш цвет
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}