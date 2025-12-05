// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';

// Imports de Navegação e Serviços
import 'package:fixit_home/routes.dart'; 
import 'package:fixit_home/services/prefs_service.dart';
import 'package:fixit_home/features/app/theme_controller.dart';

// Imports das Features
import 'package:fixit_home/features/daily_goals/presentation/pages/daily_goals_list_screen.dart';
import 'package:fixit_home/features/maintenance_tasks/presentation/pages/maintenance_tasks_list_page.dart';
import 'package:fixit_home/features/service_providers/presentation/pages/service_providers_list_screen.dart';

class AppDrawer extends StatelessWidget {
  final ThemeController? themeController;

  const AppDrawer({super.key, this.themeController});

  /// Função para processar a revogação
  Future<void> _onRevokePrivacy(BuildContext context) async {
    // 1. Mostra o diálogo de confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revogar Consentimento'),
        content: const Text(
          'Deseja revogar o aceite dos Termos de Uso e Política de Privacidade?\n\n'
          'O aplicativo será reiniciado e você terá que aceitar os termos novamente para continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revogar e Sair'),
          ),
        ],
      ),
    );

    // 2. Se o usuário confirmou...
    if (confirm == true) {
      // Limpa a persistência (marca como não aceito)
      await PrefsService.clearPolicyAcceptance();
      
      // (Opcional) Limpa também o onboarding para resetar TUDO
      await PrefsService.setOnboardingCompleted(false);

      if (context.mounted) {
        // Remove todas as telas e volta para a Splash
        // Isso automaticamente fecha o Drawer e a Home
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.splash, 
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          // 1. Cabeçalho
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.grey),
            ),
            accountName: const Text(
              "Usuário FixIt",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text("usuario@fixit.com"),
          ),

          // 2. Itens do Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  label: 'Início',
                  onTap: () => Navigator.of(context).pop(), 
                ),
                const Divider(),
                
                // Features Principais
                _buildDrawerItem(
                  context,
                  icon: Icons.flag,
                  label: 'Metas Diárias',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyGoalsListScreen()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.cleaning_services,
                  label: 'Manutenções',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceTasksListPage()));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.contacts,
                  label: 'Contatos Úteis',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceProvidersListScreen()));
                  },
                ),
                
                const Divider(),
                
                // Configurações
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  label: 'Configurações',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Em breve...')),
                    );
                  },
                ),

                // --- BOTÃO CORRIGIDO ---
                _buildDrawerItem(
                  context,
                  icon: Icons.privacy_tip,
                  label: 'Privacidade (Revogar)',
                  onTap: () {
                    // NÃO fechamos o drawer aqui (removemos o Navigator.pop)
                    // Deixamos a função _onRevokePrivacy cuidar de tudo
                    _onRevokePrivacy(context); 
                  },
                ),
                // Theme toggle moved into the scrollable list so it's always reachable
                if (themeController != null) ...[
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Tema Escuro'),
                    value: themeController!.mode == ThemeMode.dark,
                    onChanged: (_) async {
                      await themeController!.toggle(Theme.of(context).brightness);
                    },
                    secondary: const Icon(Icons.brightness_6),
                  ),
                ],
              ],
            ),
          ),
          
          // Rodapé
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Versão 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}