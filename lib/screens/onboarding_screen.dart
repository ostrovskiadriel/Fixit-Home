// lib/screens/onboarding_screen.dart
import 'package:dots_indicator/dots_indicator.dart';
import 'package:fixit_home/routes.dart';
import 'package:fixit_home/services/prefs_service.dart';
import 'package:fixit_home/widgets/onboarding_page_widget.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // Conteúdo das páginas do "FixIt Home"
  final List<Widget> _pages = [
    const OnboardingPageWidget(
      icon: Icons.lightbulb_outline, // Ícone da Lâmpada (Correto)
      title: "Bem-vindo ao FixIt Home",
      description: "Seu guia para pequenos reparos e manutenção doméstica simples.",
    ),
    const OnboardingPageWidget(
      icon: Icons.checklist_rtl,
      title: "Checklists Visuais",
      description: "Siga guias passo-a-passo para tarefas como trocar um chuveiro ou consertar uma torneira.",
    ),
    const OnboardingPageWidget(
      icon: Icons.notifications_active_outlined,
      title: "Lembretes Úteis",
      description: "Nunca mais esqueça de limpar a caixa d'água ou verificar o ar-condicionado.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navega para a próxima tela (Políticas) e salva o estado.
  void _onFinish() {
    // Salva que o onboarding foi concluído
    PrefsService.setOnboardingCompleted(true);
    
    // Navega para a tela de políticas
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.policyConsent);
    }
  }

  /// Pula o onboarding e vai direto para as políticas
  void _onSkip() {
    // Mesmo pulando, marcamos como concluído
    PrefsService.setOnboardingCompleted(true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.policyConsent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _pages.length - 1;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. O Conteúdo (PageView)
            PageView(
              controller: _pageController,
              children: _pages,
            ),

            // 2. Botão "Pular" (no topo) --- CORREÇÃO APLICADA AQUI ---
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: _onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: colors.secondary, // Usa a cor Âmbar
                ),
                child: const Text('Pular'),
              ),
            ),

            // 3. Controles Inferiores (Dots e Botão)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Indicador de Bolinhas (Corrigido para usar _currentPage)
                  DotsIndicator(
                    dotsCount: _pages.length,
                    position: _currentPage.toDouble(),
                    decorator: DotsDecorator(
                      color: colors.onSurface.withAlpha(51), // Inativo
                      activeColor: colors.primary, // Ativo (Azul)
                      size: const Size.square(9.0),
                      activeSize: const Size(18.0, 9.0),
                      activeShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botão de Avançar / Concluir
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (isLastPage) {
                        _onFinish(); // Conclui
                      } else {
                        // Avança para a próxima página
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(isLastPage ? 'Começar' : 'Avançar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}