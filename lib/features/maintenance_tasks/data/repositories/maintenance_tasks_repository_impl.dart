import 'package:flutter/foundation.dart';
import 'package:fixit_home/main.dart'; // Para acessar o supabase

// Imports das suas camadas
import '../../domain/entities/maintenance_task_entity.dart';
import '../../domain/repositories/maintenance_tasks_repository.dart';
import '../dtos/maintenance_task_dto.dart';

class MaintenanceTasksRepositoryImpl implements MaintenanceTasksRepository {
  
  @override
  Future<List<MaintenanceTaskEntity>> loadFromCache() async {
    // Por enquanto, vamos buscar direto do servidor (igual ao DailyGoals)
    return listAll();
  }

  @override
  Future<List<MaintenanceTaskEntity>> listAll() async {
    try {
      final response = await supabase
          .from('maintenance_tasks')
          .select()
          .order('next_due_date', ascending: true);

      return (response as List)
          .map((e) => MaintenanceTaskDto.fromJson(e).toEntity())
          .toList();
    } catch (e) {
      if (kDebugMode) print('Erro ao listar tarefas: $e');
      return [];
    }
  }

  @override
  Future<MaintenanceTaskEntity?> getById(String id) async {
    try {
      final response = await supabase
          .from('maintenance_tasks')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return MaintenanceTaskDto.fromJson(response).toEntity();
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar tarefa: $e');
      return null;
    }
  }

  // --- Métodos de Escrita (CRUD) ---

  @override
  Future<void> create(MaintenanceTaskEntity task) async {
    try {
      final dto = MaintenanceTaskDto.fromEntity(task);
      await supabase.from('maintenance_tasks').insert(dto.toJson());
    } catch (e) {
      if (kDebugMode) print('Erro ao criar tarefa: $e');
      rethrow; // Relança o erro para a UI saber que falhou
    }
  }

  @override
  Future<void> update(MaintenanceTaskEntity task) async {
    try {
      final dto = MaintenanceTaskDto.fromEntity(task);
      await supabase
          .from('maintenance_tasks')
          .update(dto.toJson())
          .eq('id', task.id);
    } catch (e) {
      if (kDebugMode) print('Erro ao atualizar tarefa: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await supabase.from('maintenance_tasks').delete().eq('id', id);
    } catch (e) {
      if (kDebugMode) print('Erro ao deletar tarefa: $e');
      rethrow;
    }
  }

  @override
  Future<int> syncFromServer() async {
    // Sincronização simplificada
    return 0;
  }

  @override
  Future<List<MaintenanceTaskEntity>> listFeatured() async {
    // Retorna tarefas urgentes (regra de negócio simples)
    final all = await listAll();
    return all.where((t) => t.isOverdue || t.daysRemaining <= 3).toList();
  }
}