// lib/features/maintenance_tasks/presentation/pages/maintenance_tasks_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Imports da Arquitetura
import '../../domain/entities/maintenance_task_entity.dart';
import '../../data/repositories/maintenance_tasks_repository_impl.dart';
import '../widgets/maintenance_task_form_dialog.dart';

class MaintenanceTasksListPage extends StatefulWidget {
  const MaintenanceTasksListPage({super.key});

  @override
  State<MaintenanceTasksListPage> createState() => _MaintenanceTasksListPageState();
}

class _MaintenanceTasksListPageState extends State<MaintenanceTasksListPage> {
  // Instancia o repositório (que fala com o Supabase)
  final _repository = MaintenanceTasksRepositoryImpl();
  
  bool _isLoading = true;
  List<MaintenanceTaskEntity> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  /// Carrega as tarefas do Repositório
  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _repository.listAll();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Adicionar Nova Tarefa
  Future<void> _addTask() async {
    final newTask = await showMaintenanceTaskFormDialog(context);
    
    if (newTask != null) {
      try {
        await _repository.create(newTask);
        _loadTasks(); // Recarrega a lista
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarefa criada com sucesso!')),
          );
        }
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
        await _repository.update(editedTask);
        _loadTasks();
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
        await _repository.delete(task.id);
        _loadTasks();
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTasks),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cleaning_services_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Nenhuma manutenção agendada.', style: TextStyle(color: Colors.grey)),
        ],
      ),
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
                    Chip(
                      label: Text(task.frequency.label, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(task.difficulty.label, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
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
      case TaskDifficulty.easy: return Colors.green;
      case TaskDifficulty.medium: return Colors.orange;
      case TaskDifficulty.hard: return Colors.red;
      case TaskDifficulty.expert: return Colors.purple;
    }
  }
}