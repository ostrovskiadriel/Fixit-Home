// lib/features/maintenance_tasks/presentation/pages/maintenance_tasks_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// Imports da Arquitetura
import '../../domain/entities/maintenance_task_entity.dart';
import '../../data/datasources/local/maintenance_tasks_local_dao_shared_prefs.dart';
import '../../data/datasources/remote/supabase_maintenance_tasks_remote_datasource.dart';
import '../../data/mappers/maintenance_task_mapper.dart';
import '../../data/repositories/maintenance_tasks_repository_impl.dart';
import '../widgets/maintenance_task_form_dialog.dart';

class MaintenanceTasksListPage extends StatefulWidget {
  const MaintenanceTasksListPage({super.key});

  @override
  State<MaintenanceTasksListPage> createState() => _MaintenanceTasksListPageState();
}

class _MaintenanceTasksListPageState extends State<MaintenanceTasksListPage> {
  MaintenanceTasksRepositoryImpl? _repo;
  bool _isLoading = true;
  List<MaintenanceTaskEntity> _tasks = [];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localDao = MaintenanceTasksLocalDaoSharedPrefs(prefs: prefs);
      final remote = SupabaseMaintenanceTasksRemoteDatasource();
      final mapper = MaintenanceTaskMapper();

      _repo = MaintenanceTasksRepositoryImpl(
        remote: remote,
        localDao: localDao,
        mapper: mapper,
        prefsAsync: Future.value(prefs),
      );

      await _loadTasks();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao inicializar repositório: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Carrega as tarefas do Repositório com padrão cache→sync
  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final repo = _repo;
      if (repo == null) throw Exception('Repositório não inicializado');

      final cached = await repo.loadFromCache();
      if (cached.isEmpty) {
        if (mounted) setState(() => _tasks = []);
        try {
          await repo.syncFromServer();
        } catch (e) {
          if (kDebugMode) print('Erro durante sync inicial: $e');
        }
      }

      final entities = await repo.listAll();
      if (mounted) setState(() { _tasks = entities; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Adicionar Nova Tarefa
  Future<void> _addTask() async {
    final newTask = await showMaintenanceTaskFormDialog(context);
    if (newTask != null) {
      try {
        if (_repo == null) throw Exception('Repositório não inicializado');
        await _repo!.create(newTask);
        await _loadTasks();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarefa criada com sucesso!')));
      } catch (e) {
        _showError('Erro ao criar: $e');
      }
    }
  }

  /// Editar Tarefa Existente
  Future<void> _editTask(MaintenanceTaskEntity task) async {
    final editedTask = await showMaintenanceTaskFormDialog(context, initial: task);
    if (editedTask != null) {
      try {
        if (_repo == null) throw Exception('Repositório não inicializado');
        await _repo!.update(editedTask);
        await _loadTasks();
      } catch (e) {
        _showError('Erro ao atualizar: $e');
      }
    }
  }

  /// Remover Tarefa
  Future<void> _deleteTask(MaintenanceTaskEntity task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Tarefa'),
        content: Text('Tem certeza que deseja excluir "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (_repo == null) throw Exception('Repositório não inicializado');
        await _repo!.delete(task.id);
        await _loadTasks();
      } catch (e) {
        _showError('Erro ao deletar: $e');
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manutenções'),
        actions: [ IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTasks) ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => _repo?.syncFromServer().then((_) => _loadTasks()) ?? _loadTasks(),
                  child: const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(height: 300, child: Center(child: Text('Nenhuma manutenção agendada.'))),
                  ),
                )
              : _buildList(),
      floatingActionButton: FloatingActionButton(onPressed: _addTask, child: const Icon(Icons.add)),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Card(
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getDifficultyColor(task.difficulty).withAlpha(50),
              child: Icon(Icons.build, color: _getDifficultyColor(task.difficulty)),
            ),
            title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vence em: ${DateFormat.yMMMd().format(task.nextDueDate)}'),
                Row(
                  children: [
                    Chip(label: Text(task.frequency.label, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                    const SizedBox(width: 8),
                    Chip(label: Text(task.difficulty.label, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                  ],
                )
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton(
              onSelected: (value) {
                if (value == 'edit') _editTask(task);
                if (value == 'delete') _deleteTask(task);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Editar')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: Colors.red))])),
              ],
            ),
            onTap: () => _editTask(task), // Atalho para editar
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(TaskDifficulty d) {
    switch (d) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
      case TaskDifficulty.expert:
        return Colors.purple;
    }
  }
}