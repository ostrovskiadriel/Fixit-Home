import '../entities/maintenance_task_entity.dart';

/// Interface de repositório para MaintenanceTask
abstract class MaintenanceTasksRepository {
  /// Carrega do cache local para render rápido
  Future<List<MaintenanceTaskEntity>> loadFromCache();

  /// Sincroniza incrementalmente com o servidor
  Future<int> syncFromServer();

  /// Retorna lista completa (após sync)
  Future<List<MaintenanceTaskEntity>> listAll();

  /// Retorna itens em destaque (ex: próximos a vencer)
  Future<List<MaintenanceTaskEntity>> listFeatured();

  /// Busca por ID
  Future<MaintenanceTaskEntity?> getById(String id);

  /// Cria nova tarefa
  Future<void> create(MaintenanceTaskEntity task);

  /// Atualiza tarefa existente
  Future<void> update(MaintenanceTaskEntity task);

  /// Deleta tarefa
  Future<void> delete(String id);
}
