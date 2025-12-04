import '../../dtos/service_provider_dto.dart';

abstract class ServiceProvidersLocalDao {
  Future<List<ServiceProviderDto>> getAll();
  Future<ServiceProviderDto?> getById(String id);
  Future<void> upsertAll(List<ServiceProviderDto> dtos);
  Future<void> delete(String id);
  Future<void> clear();
}
