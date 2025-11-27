import 'package:flutter/material.dart';
import 'package:fixit_home/services/prefs_service.dart';
import 'package:fixit_home/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Inicia a verificação após o primeiro frame ser construído
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatusAndRedirect();
    });
  }

  Future<void> _checkAuthStatusAndRedirect() async {
    // Delay opcional para a marca ser visível (melhora a UX)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Garante que o widget ainda está na tela antes de navegar
    if (!mounted) return;

    // --- LÓGICA DE DECISÃO DE ROTA (Baseado no PRD "EduCare") ---
    
    final String targetRoute;

    if (PrefsService.hasAcceptedLatestPolicies()) {
      // 1. Usuário já aceitou as políticas? Vai direto para a Home. [cite: 897]
      targetRoute = AppRoutes.home;
    } else if (PrefsService.hasCompletedOnboarding()) {
      // 2. Já viu o Onboarding? Vai para a tela de Consentimento/Políticas. [cite: 796, 881]
      targetRoute = AppRoutes.policyConsent;
    } else {
      // 3. É um novo usuário? Mostra o Onboarding. [cite: 891, 892]
      targetRoute = AppRoutes.onboarding;
    }

    // Navega para a rota decidida, substituindo a Splash
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo FixIt Home - Ícone de ferramentas com estilo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withAlpha(25),
              ),
              child: Icon(
                Icons.build,
                size: 60,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FixIt Home',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seu guia de manutenção doméstica',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}