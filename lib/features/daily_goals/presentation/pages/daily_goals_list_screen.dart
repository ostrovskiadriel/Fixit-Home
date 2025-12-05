// lib/features/daily_goals/presentation/pages/daily_goals_list_screen.dart
import 'package:flutter/material.dart';
// NOTE: Supabase access moved to repository. UI no longer calls Supabase directly.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:fixit_home/features/daily_goals/data/datasources/local/daily_goals_local_dao_shared_prefs.dart';
import 'package:fixit_home/features/daily_goals/data/datasources/remote/supabase_daily_goals_remote_datasource.dart';
import 'package:fixit_home/features/daily_goals/data/mappers/daily_goal_mapper.dart';
import 'package:fixit_home/features/daily_goals/data/repositories/daily_goals_repository_impl.dart';

// Imports Clean Architecture
import '../../domain/entities/daily_goal_entity.dart';
// DTO imports removed — UI works with domain entities only
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
  DailyGoalsRepositoryImpl? _repo;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    // Inicializa o repositório (DAO local + remote datasource + mapper)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localDao = DailyGoalsLocalDaoSharedPrefs(prefs: prefs);
      final remote = SupabaseDailyGoalsRemoteDatasource();
      final mapper = DailyGoalMapper();

      _repo = DailyGoalsRepositoryImpl(
        remoteDatasource: remote,
        localDao: localDao,
        mapper: mapper,
        prefsAsync: Future.value(prefs),
      );

      await _loadGoals();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao inicializar repositório: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// READ (Ler)
  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      // 1) Tenta carregar do cache local para render rápido
      final repo = _repo;
      if (repo == null) throw Exception('Repositório não inicializado');

      final cached = await repo.loadFromCache();

      // Se cache vazio, dispara sincronização do servidor
      if (cached.isEmpty) {
        if (mounted) {
          setState(() { _goals = []; });
        }
        try {
          await repo.syncFromServer();
        } catch (e) {
          if (kDebugMode) print('Erro durante sync inicial: $e');
        }
      }

      // Carrega a lista atualizada do cache
      final entities = await repo.listAll();

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
      try {
        if (_repo == null) throw Exception('Repositório não inicializado');
        await _repo!.create(newGoalEntity);
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
        if (_repo == null) throw Exception('Repositório não inicializado');
        await _repo!.update(editedGoal);
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
        if (_repo == null) throw Exception('Repositório não inicializado');
        await _repo!.delete(goal.id);
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
    return RefreshIndicator(
      onRefresh: () => _repo?.syncFromServer().then((_) => _loadGoals()) ?? _loadGoals(),
      child: _goals.isEmpty
          ? const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: 300, child: Center(child: Text('Nenhuma meta encontrada.'))),
            )
          : ListView.builder(
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
            ),
    );
  }

  // Note: Entity->DTO mapping moved to repository/mapper; UI should not perform conversion.

}