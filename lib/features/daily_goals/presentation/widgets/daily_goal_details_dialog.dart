// lib/features/daily_goals/presentation/widgets/daily_goal_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/daily_goal_entity.dart';

/// Função helper para exibir o diálogo de detalhes
Future<void> showDailyGoalDetailsDialog(
  BuildContext context, {
  required DailyGoalEntity goal,
  required VoidCallback onEdit,
  required VoidCallback onRemove,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => _DailyGoalDetailsDialog(
      goal: goal,
      onEdit: onEdit,
      onRemove: onRemove,
    ),
  );
}

class _DailyGoalDetailsDialog extends StatelessWidget {
  final DailyGoalEntity goal;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _DailyGoalDetailsDialog({
    required this.goal,
    required this.onEdit,
    required this.onRemove,
  });

  String _formatDate(DateTime date) {
    try {
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return date.toIso8601String();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(goal.type.icon),
          const SizedBox(width: 8),
          Expanded(child: Text(goal.type.description)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Progresso:', '${goal.currentValue} / ${goal.targetValue}'),
          _buildDetailRow('Porcentagem:', '${goal.progressPercentage}%'),
          _buildDetailRow('Data:', _formatDate(goal.date)),
          _buildDetailRow('Status:', goal.isCompleted ? 'Concluída ✅' : 'Em andamento ⏳'),
          const Divider(),
          Text('ID: ${goal.id}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        // Botão 1: FECHAR
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('FECHAR'),
        ),
        // Botão 2: EDITAR
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Fecha o detalhes antes de editar
            onEdit();
          },
          child: const Text('EDITAR'),
        ),
        // Botão 3: REMOVER
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Fecha o detalhes antes de remover
            onRemove();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('REMOVER'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}