// lib/features/service_providers/data/repositories/service_providers_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/service_provider_entity.dart';
import '../../domain/repositories/service_providers_repository.dart';
import '../datasources/local/service_providers_local_dao.dart';
import '../datasources/remote/supabase_service_providers_remote_datasource.dart';
import '../mappers/service_provider_mapper.dart';

class ServiceProvidersRepositoryImpl implements ServiceProvidersRepository {
  final SupabaseServiceProvidersRemoteDatasource _remote;
  final ServiceProvidersLocalDao _localDao;
  final ServiceProviderMapper _mapper;
  final Future<SharedPreferences> _prefsAsync;

  static const String _lastSyncKey = 'service_providers_last_sync_v1';

  ServiceProvidersRepositoryImpl({
    required SupabaseServiceProvidersRemoteDatasource remote,
    required ServiceProvidersLocalDao localDao,
    required ServiceProviderMapper mapper,
    Future<SharedPreferences>? prefsAsync,
  })  : _remote = remote,
        _localDao = localDao,
        _mapper = mapper,
        _prefsAsync = prefsAsync ?? SharedPreferences.getInstance();

  @override
  Future<List<ServiceProviderEntity>> listAll() async {
    try {
      final cached = await _localDao.getAll();
      final entities = _mapper.dtoListToEntityList(cached);
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.listAll: retornando ${entities.length} prestadores');
      return entities;
    } catch (e) {
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.listAll: erro - $e');
      return [];
    }
  }

  @override
  Future<void> create(ServiceProviderEntity provider) async {
    try {
      final dto = _mapper.entityToDto(provider);
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.create: criando prestador ${provider.name}');

      // 1) write to remote
      await _remote.upsertServiceProviders([dto]);
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.create: enviado para remoto com sucesso');

      // 2) upsert locally immediately so UI updates right away
      await _localDao.upsertAll([dto]);
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.create: upserted localmente');

      // 3) sync to get any other changes
      await syncFromServer();
    } catch (e) {
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.create: erro - $e');
      rethrow;
    }
  }

  @override
  Future<void> update(ServiceProviderEntity provider) async {
    try {
      final dto = _mapper.entityToDto(provider);
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.update: atualizando prestador ${provider.name}');

      // 1) write to remote
      await _remote.upsertServiceProviders([dto]);
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.update: enviado para remoto com sucesso');

      // 2) upsert locally immediately so UI updates right away
      await _localDao.upsertAll([dto]);
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.update: upserted localmente');

      // 3) sync to get any other changes
      await syncFromServer();
    } catch (e) {
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.update: erro - $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Attempt remote delete (best-effort)
      try {
        await _remote.deleteServiceProvider(id);
      } catch (e) {
        if (kDebugMode) print('ServiceProvidersRepositoryImpl.delete: erro ao deletar no remoto - $e');
      }

      await _localDao.delete(id);
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.delete: $id deletado');
    } catch (e) {
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.delete: erro - $e');
      rethrow;
    }
  }

  @override
  Future<int> syncFromServer() async {
    try {
      // 0) push local -> remote (best-effort)
      try {
        final localDtos = await _localDao.getAll();
        if (localDtos.isNotEmpty) {
          if (kDebugMode) print('ServiceProvidersRepositoryImpl.syncFromServer: push ${localDtos.length} items');
          await _remote.upsertServiceProviders(localDtos);
        }
      } catch (e) {
        if (kDebugMode) print('ServiceProvidersRepositoryImpl.syncFromServer: push falhou - $e');
      }

      final prefs = await _prefsAsync;
      final lastIso = prefs.getString(_lastSyncKey);

      DateTime? since;
      if (lastIso != null && lastIso.isNotEmpty) {
        try {
          since = DateTime.parse(lastIso);
        } catch (_) {}
      }

      if (kDebugMode) print('ServiceProvidersRepositoryImpl.syncFromServer: pull desde ${since?.toIso8601String() ?? 'início'}');

      final page = await _remote.fetchServiceProviders(since: since, limit: 500);
      if (page.items.isEmpty) return 0;

      await _localDao.upsertAll(page.items);

      // compute newest updated_at — the DTO doesn't expose updated_at, fallback to now
      final newest = DateTime.now().toUtc();
      await prefs.setString(_lastSyncKey, newest.toIso8601String());

      if (kDebugMode) print('ServiceProvidersRepositoryImpl.syncFromServer: aplicadas ${page.items.length} mudanças');

      return page.items.length;
    } catch (e) {
      if (kDebugMode) print('ServiceProvidersRepositoryImpl.syncFromServer: erro - $e');
      return 0;
    }
  }
}