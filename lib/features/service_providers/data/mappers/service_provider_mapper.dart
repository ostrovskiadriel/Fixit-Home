import '../dtos/service_provider_dto.dart';
import '../../domain/entities/service_provider_entity.dart';

class ServiceProviderMapper {
  ServiceProviderEntity dtoToEntity(ServiceProviderDto dto) => dto.toEntity();
  ServiceProviderDto entityToDto(ServiceProviderEntity e) => ServiceProviderDto.fromEntity(e);
  List<ServiceProviderEntity> dtoListToEntityList(List<ServiceProviderDto> dtos) => dtos.map(dtoToEntity).toList();
  List<ServiceProviderDto> entityListToDtoList(List<ServiceProviderEntity> entities) => entities.map(entityToDto).toList();
}
