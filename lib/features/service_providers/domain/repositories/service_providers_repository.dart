import '../entities/service_provider_entity.dart';

abstract class ServiceProvidersRepository {
  Future<List<ServiceProviderEntity>> listAll();
  Future<void> create(ServiceProviderEntity provider);
  Future<void> update(ServiceProviderEntity provider);
  Future<void> delete(String id);
  Future<void> syncFromServer();
}
