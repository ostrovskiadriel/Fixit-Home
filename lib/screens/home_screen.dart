// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

import 'package:fixit_home/features/app/theme_controller.dart';

// Imports das features
import '../features/daily_goals/presentation/pages/daily_goals_list_screen.dart';
import 'package:fixit_home/features/maintenance_tasks/presentation/pages/maintenance_tasks_list_page.dart';
import 'package:fixit_home/features/service_providers/presentation/pages/service_providers_list_screen.dart';

// Import do Drawer
import 'package:fixit_home/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  final ThemeController? themeController;

  const HomeScreen({super.key, this.themeController});

  void _navigateToDailyGoals(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const DailyGoalsListScreen()),
    );
  }

  void _navigateToMaintenance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const MaintenanceTasksListPage()),
    );
  }

  void _navigateToProviders(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ServiceProvidersListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FixIt Home'),
      ),
      
      // --- Drawer with optional ThemeController ---
      drawer: AppDrawer(themeController: themeController), 
      // --------------------------------

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.home_repair_service_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Bem-vindo ao FixIt Home!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Seu app de manutenção doméstica.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Botão 1: Metas
              ElevatedButton.icon(
                onPressed: () => _navigateToDailyGoals(context),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Ver Minhas Metas Diárias'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16), 
              
              // Botão 2: Manutenção
              ElevatedButton.icon(
                onPressed: () => _navigateToMaintenance(context),
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Gerenciar Manutenções'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botão 3: Prestadores
              ElevatedButton.icon(
                onPressed: () => _navigateToProviders(context),
                icon: const Icon(Icons.contacts),
                label: const Text('Contatos Úteis'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}