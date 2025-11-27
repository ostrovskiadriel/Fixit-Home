import '../../dtos/daily_goal_dto.dart';

/// Interface para acesso a dados locais de metas diárias.
///
/// O DAO (Data Access Object) abstrai o gerenciamento do cache local
/// (SharedPreferences, SQLite, etc.), permitindo trocar a implementação
/// sem afetar o repositório.
abstract class DailyGoalsLocalDao {
  /// Carrega todas as metas do cache local.
  Future<List<DailyGoalDto>> getAll();

  /// Busca uma meta pelo ID no cache local.
  Future<DailyGoalDto?> getById(String id);

  /// Insere ou atualiza (upsert) uma lista de metas no cache.
  /// Use após sincronização com servidor.
  Future<void> upsertAll(List<DailyGoalDto> dtos);

  /// Deleta uma meta do cache pelo ID.
  Future<void> delete(String id);

  /// Limpa todo o cache de metas.
  Future<void> clear();
}
