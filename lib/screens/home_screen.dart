import 'package:flutter/material.dart';
// Import corrigido
import '../features/daily_goals/presentation/pages/daily_goals_list_screen.dart';
import 'package:fixit_home/features/maintenance_tasks/presentation/pages/maintenance_tasks_list_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Navega para a tela de Metas Diárias
  void _navigateToDailyGoals(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const DailyGoalsListScreen(),
      ),
    );
  }

void _navigateToMaintenance(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (ctx) => const MaintenanceTasksListPage()),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FixIt Home'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.home_repair_service_outlined, // Ícone do "FixIt Home"
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

              // Botão para acessar a feature de Metas Diárias
              ElevatedButton.icon(
                onPressed: () => _navigateToDailyGoals(context),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Ver Minhas Metas Diárias'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16), // Espaçamento
              ElevatedButton.icon(
              onPressed: () => _navigateToMaintenance(context),
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Gerenciar Manutenções'),
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