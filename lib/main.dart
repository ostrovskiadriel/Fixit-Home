// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importe o dotenv
import 'package:supabase_flutter/supabase_flutter.dart'; // Importe o Supabase

import 'package:fixit_home/routes.dart';
import 'package:fixit_home/screens/home_screen.dart';
import 'package:fixit_home/screens/onboarding_screen.dart';
import 'package:fixit_home/screens/policy_consent_screen.dart';
import 'package:fixit_home/screens/splash_screen.dart';
import 'package:fixit_home/services/prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carrega as variáveis de ambiente do arquivo .env [cite: 1277]
  await dotenv.load(fileName: ".env");

  // 2. Inicializa o serviço de preferências (SharedPreferences)
  await PrefsService.init();

  // 3. Inicializa o Supabase [cite: 1283]
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, // [cite: 1278]
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // [cite: 1279]
  );

  runApp(const FixItApp());
}

// Helper para acessar o cliente Supabase globalmente
final supabase = Supabase.instance.client;

// --- Definição das Cores do Tema "FixIt Home" ---
const Color kColorBlue = Color(0xFF2563EB);
const Color kColorSlate = Color(0xFF0F172A);
const Color kColorAmber = Color(0xFFF59E0B);

class FixItApp extends StatelessWidget {
  const FixItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixIt Home',
      debugShowCheckedModeBanner: false,
      
      // --- Tema Claro ---
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: kColorBlue,
          primary: kColorBlue,
          secondary: kColorAmber,
          surface: Colors.white,
          onSurface: kColorSlate,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),

      // --- Tema Escuro ---
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: kColorBlue,
          primary: kColorBlue,
          secondary: kColorAmber,
          surface: kColorSlate,
          onSurface: Colors.white.withOpacity(0.9),
        ),
        scaffoldBackgroundColor: kColorSlate,
      ),
      
      themeMode: ThemeMode.system,
      
      // --- Roteamento ---
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.policyConsent: (context) => const PolicyConsentScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
      },
    );
  }
}