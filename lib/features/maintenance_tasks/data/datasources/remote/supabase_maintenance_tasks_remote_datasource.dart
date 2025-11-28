import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dtos/maintenance_task_dto.dart';

class RemotePage<T> {
  final List<T> items;
  final String? next;
  RemotePage({required this.items, this.next});
}

class SupabaseMaintenanceTasksRemoteDatasource {
  final SupabaseClient _client;
  SupabaseMaintenanceTasksRemoteDatasource({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Busca tarefas de manutenção. Atualmente retorna todos ordenados por next_due_date.
  Future<RemotePage<MaintenanceTaskDto>> fetchMaintenanceTasks({
    int limit = 500,
    int offset = 0,
  }) async {
    try {
      if (kDebugMode) print('SupabaseMaintenanceTasksRemoteDatasource.fetchMaintenanceTasks: limit=$limit offset=$offset');

      final response = await _client.from('maintenance_tasks').select().order('next_due_date', ascending: true).range(offset, offset + limit - 1);
      final rows = response as List<dynamic>;

      if (kDebugMode) print('SupabaseMaintenanceTasksRemoteDatasource.fetchMaintenanceTasks: recebidos ${rows.length} registros');

      final dtos = rows.map((r) => MaintenanceTaskDto.fromJson(Map<String, dynamic>.from(r as Map))).toList();
      final hasMore = dtos.length == limit;
      final next = hasMore ? (offset + limit).toString() : null;
      return RemotePage<MaintenanceTaskDto>(items: dtos, next: next);
    } catch (e) {
      if (kDebugMode) print('SupabaseMaintenanceTasksRemoteDatasource.fetchMaintenanceTasks: erro - $e');
      return RemotePage<MaintenanceTaskDto>(items: []);
    }
  }
}
