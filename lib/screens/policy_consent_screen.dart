// lib/screens/policy_consent_screen.dart
import 'package:fixit_home/routes.dart';
import 'package:fixit_home/screens/policy_viewer_screen.dart';
import 'package:fixit_home/services/prefs_service.dart';
import 'package:flutter/material.dart';

class PolicyConsentScreen extends StatefulWidget {
  const PolicyConsentScreen({super.key});

  @override
  State<PolicyConsentScreen> createState() => _PolicyConsentScreenState();
}

class _PolicyConsentScreenState extends State<PolicyConsentScreen> {
  // Estado de leitura dos documentos
  bool _termsRead = false;
  bool _privacyRead = false;

  bool get _allPoliciesRead => _termsRead && _privacyRead;

  /// Navega para a tela de visualização de política
  Future<void> _navigateToViewer(BuildContext context, String title, String assetPath, bool isTerms) async {
    final bool? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PolicyViewerScreen(
          title: title,
          markdownAssetPath: assetPath,
        ),
      ),
    );

    // Se o usuário "Marcou como lido", o 'result' será true
    if (result == true) {
      setState(() {
        if (isTerms) {
          _termsRead = true;
        } else {
          _privacyRead = true;
        }
      });
    }
  }

  /// Salva o aceite e navega para a Home
  void _onAccept() {
    if (!_allPoliciesRead) return; // Segurança extra

    // Persiste a versão do aceite
    PrefsService.setPoliciesAccepted();

    // Navega para a Home, limpando o histórico de navegação
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 80,
                color: colors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Políticas e Consentimento',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Para usar o FixIt Home, você precisa ler e aceitar nossos Termos de Uso e nossa Política de Privacidade.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Botão 1: Termos de Uso
              _buildPolicyButton(
                context: context,
                title: 'Termos de Uso',
                isRead: _termsRead,
                onTap: () => _navigateToViewer(context, 'Termos de Uso', 'assets/terms.md', true),
              ),
              const SizedBox(height: 16),

              // Botão 2: Política de Privacidade
              _buildPolicyButton(
                context: context,
                title: 'Política de Privacidade',
                isRead: _privacyRead,
                onTap: () => _navigateToViewer(context, 'Política de Privacidade', 'assets/privacy.md', false),
              ),

              const Spacer(),
              const SizedBox(height: 24),

              // Botão Final de Aceite
              ElevatedButton(
                // Habilita somente se ambos foram lidos
                onPressed: _allPoliciesRead ? _onAccept : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Concordo e Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para criar os botões de política
  Widget _buildPolicyButton({
    required BuildContext context,
    required String title,
    required bool isRead,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title),
      leading: Icon(
        isRead ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isRead ? Colors.green : colors.onSurface.withOpacity(0.5),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colors.onSurface.withOpacity(0.2),
        ),
      ),
    );
  }
}