import '../../domain/entities/maintenance_task_entity.dart';
import '../dtos/maintenance_task_dto.dart';

/// Mapper para MaintenanceTask: converte entre DTO e Entity.
///
/// Observações:
/// - Usa os helpers do DTO quando disponível (`fromEntity` / `toEntity`).
/// - Centralizar conversões facilita testes e manutenção.
class MaintenanceTaskMapper {
  MaintenanceTaskEntity dtoToEntity(MaintenanceTaskDto dto) {
    return dto.toEntity();
  }

  MaintenanceTaskDto entityToDto(MaintenanceTaskEntity entity) {
    return MaintenanceTaskDto.fromEntity(entity);
  }

  List<MaintenanceTaskEntity> dtoListToEntityList(List<MaintenanceTaskDto> dtos) {
    return dtos.map((d) => dtoToEntity(d)).toList();
  }

  List<MaintenanceTaskDto> entityListToDtoList(List<MaintenanceTaskEntity> entities) {
    return entities.map((e) => entityToDto(e)).toList();
  }
}
