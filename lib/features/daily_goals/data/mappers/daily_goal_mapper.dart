import 'package:fixit_home/features/daily_goals/domain/entities/daily_goal_entity.dart';
import '../dtos/daily_goal_dto.dart';

/// Mapper para converter entre DailyGoalDto (camada de dados) e DailyGoalEntity (domínio).
///
/// O mapper é responsável por transformar dados vindos da API/cache (DTOs)
/// em entidades de domínio com regras de negócio. Isso mantém a separação
/// entre as camadas e facilita testes.
///
/// ⚠️ Dicas práticas:
/// - Sempre trate conversão de tipos com segurança (ex: String → enum)
/// - Parse de datas deve usar try/catch
/// - Se um campo vier em formato inesperado, log com kDebugMode e retorne valor padrão seguro
class DailyGoalMapper {
  /// Converte DTO para Entidade de domínio.
  ///
  /// Use quando receber dados de cache ou Supabase para transformá-los
  /// em objetos de domínio com validações e regras de negócio.
  DailyGoalEntity dtoToEntity(DailyGoalDto dto) {
    return DailyGoalEntity(
      id: dto.goalId,
      userId: dto.userId,
      type: GoalType.fromString(dto.type),
      targetValue: dto.targetValue,
      currentValue: dto.currentValue,
      date: DateTime.parse(dto.date),
      isCompleted: dto.isCompleted,
    );
  }

  /// Converte Entidade de domínio para DTO.
  ///
  /// Use quando precisar salvar dados no cache ou enviar para Supabase.
  /// Converte tipos específicos do domínio (ex: enum) para formatos simples (string).
  DailyGoalDto entityToDto(DailyGoalEntity entity) {
    return DailyGoalDto(
      goalId: entity.id,
      userId: entity.userId,
      type: entity.type.name, // Enum para String
      targetValue: entity.targetValue,
      currentValue: entity.currentValue,
      date: entity.date.toIso8601String(), // DateTime para ISO8601 String
      isCompleted: entity.isCompleted,
    );
  }

  /// Converte lista de DTOs para lista de Entidades.
  List<DailyGoalEntity> dtoListToEntityList(List<DailyGoalDto> dtos) {
    return dtos.map((dto) => dtoToEntity(dto)).toList();
  }

  /// Converte lista de Entidades para lista de DTOs.
  List<DailyGoalDto> entityListToDtoList(List<DailyGoalEntity> entities) {
    return entities.map((entity) => entityToDto(entity)).toList();
  }
}
