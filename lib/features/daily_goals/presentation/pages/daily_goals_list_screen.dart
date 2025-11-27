// lib/features/daily_goals/presentation/pages/daily_goals_list_screen.dart
import 'package:flutter/material.dart';
import 'package:fixit_home/main.dart'; // Acesso ao supabase

// Imports Clean Architecture
import '../../domain/entities/daily_goal_entity.dart';
import '../../data/dtos/daily_goal_dto.dart';
import '../widgets/daily_goal_entity_form_dialog.dart';
import '../widgets/daily_goal_details_dialog.dart'; // <-- NOVO IMPORT

class DailyGoalsListScreen extends StatefulWidget {
  const DailyGoalsListScreen({super.key});
  @override
  State<DailyGoalsListScreen> createState() => _DailyGoalsListScreenState();
}

class _DailyGoalsListScreenState extends State<DailyGoalsListScreen> {
  bool _isLoading = true;
  List<DailyGoalEntity> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  /// READ (Ler)
  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('daily_goals')
          .select()
          .order('date', ascending: false);

      final dtos = data
          .map((item) => DailyGoalDto.fromJson(item))
          .toList();

      final entities = dtos.map(_dtoToEntity).toList();

      if (mounted) {
        setState(() {
          _goals = entities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// CREATE (Criar)
  Future<void> _openCreateGoalDialog() async {
    final newGoalEntity = await showDailyGoalEntityFormDialog(context);
    if (newGoalEntity != null) {
      final newGoalDto = _entityToDto(newGoalEntity);
      try {
        await supabase.from('daily_goals').insert(newGoalDto.toJson());
        await _loadGoals();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  /// UPDATE (Editar) - Requisito 6 do Professor
  Future<void> _onEditGoal(DailyGoalEntity goal) async {
    // Abre o formulário JÁ PREENCHIDO com a meta atual
    final editedGoal = await showDailyGoalEntityFormDialog(context, initial: goal);
    
    if (editedGoal != null) {
      try {
        final dto = _entityToDto(editedGoal);
        // Atualiza no Supabase onde o ID for igual
        await supabase
            .from('daily_goals')
            .update(dto.toJson())
            .eq('goal_id', goal.id);
            
        await _loadGoals(); // Recarrega a lista
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta atualizada!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao editar: $e')));
      }
    }
  }

  /// DELETE (Remover) - Requisito 7 do Professor
  Future<void> _onRemoveGoal(DailyGoalEntity goal) async {
    // Confirmação extra antes de apagar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tem certeza?'),
        content: Text('Deseja apagar a meta "${goal.type.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('daily_goals').delete().eq('goal_id', goal.id);
        await _loadGoals();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta removida.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao remover: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas Diárias (Supabase)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGoals),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildGoalList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateGoalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalList() {
    if (_goals.isEmpty) {
      return const Center(child: Text('Nenhuma meta encontrada.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return Card(
          child: ListTile(
            leading: Text(goal.type.icon, style: const TextStyle(fontSize: 24)),
            title: Text(goal.type.description),
            subtitle: Text('Progresso: ${goal.currentValue} / ${goal.targetValue}'),
            trailing: const Icon(Icons.chevron_right),
            // AQUI ESTÁ A IMPLEMENTAÇÃO DO REQUISITO 5:
            onTap: () => showDailyGoalDetailsDialog(
              context,
              goal: goal,
              onEdit: () => _onEditGoal(goal),     // Conecta a função de Editar
              onRemove: () => _onRemoveGoal(goal), // Conecta a função de Remover
            ),
          ),
        );
      },
    );
  }

  // Mappers
  DailyGoalEntity _dtoToEntity(DailyGoalDto dto) {
    return DailyGoalEntity(
      id: dto.goalId, userId: dto.userId, type: GoalType.fromString(dto.type),
      targetValue: dto.targetValue, currentValue: dto.currentValue,
      date: DateTime.parse(dto.date), isCompleted: dto.isCompleted,
    );
  }

  DailyGoalDto _entityToDto(DailyGoalEntity entity) {
    return DailyGoalDto(
      goalId: entity.id, userId: entity.userId, type: entity.type.name,
      targetValue: entity.targetValue, currentValue: entity.currentValue,
      date: entity.date.toIso8601String(), isCompleted: entity.isCompleted,
    );
  }
}