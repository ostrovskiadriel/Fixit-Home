import '../../dtos/maintenance_task_dto.dart';

/// Interface do DAO local para tarefas de manutenção.
abstract class MaintenanceTasksLocalDao {
  Future<List<MaintenanceTaskDto>> getAll();
  Future<MaintenanceTaskDto?> getById(String id);
  Future<void> upsertAll(List<MaintenanceTaskDto> dtos);
  Future<void> delete(String id);
  Future<void> clear();
}
