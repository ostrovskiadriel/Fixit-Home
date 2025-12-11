import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/maintenance_task_entity.dart';
import '../../domain/repositories/maintenance_tasks_repository.dart';
import '../dtos/maintenance_task_dto.dart';
import '../datasources/local/maintenance_tasks_local_dao.dart';
import '../datasources/remote/supabase_maintenance_tasks_remote_datasource.dart';
import '../mappers/maintenance_task_mapper.dart';
import 'package:fixit_home/main.dart' show supabase;

class MaintenanceTasksRepositoryImpl implements MaintenanceTasksRepository {
  final SupabaseMaintenanceTasksRemoteDatasource _remote;
  final MaintenanceTasksLocalDao _localDao;
  final MaintenanceTaskMapper _mapper;
  final Future<SharedPreferences> _prefsAsync;

  static const String _lastSyncKey = 'maintenance_tasks_last_sync_v1';

  MaintenanceTasksRepositoryImpl({
    required SupabaseMaintenanceTasksRemoteDatasource remote,
    required MaintenanceTasksLocalDao localDao,
    required MaintenanceTaskMapper mapper,
    Future<SharedPreferences>? prefsAsync,
  })  : _remote = remote,
        _localDao = localDao,
        _mapper = mapper,
        _prefsAsync = prefsAsync ?? SharedPreferences.getInstance();

  @override
  Future<List<MaintenanceTaskEntity>> loadFromCache() async {
    try {
      final dtos = await _localDao.getAll();
      final entities = _mapper.dtoListToEntityList(dtos);
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.loadFromCache: carregadas ${entities.length} tarefas do cache');
      return entities;
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.loadFromCache: erro - $e');
      return [];
    }
  }

  @override
  Future<int> syncFromServer() async {
    try {
      final prefs = await _prefsAsync;
      final lastSyncIso = prefs.getString(_lastSyncKey);

      DateTime? since;
      if (lastSyncIso != null && lastSyncIso.isNotEmpty) {
        try {
          since = DateTime.parse(lastSyncIso);
        } catch (_) {}
      }

      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.syncFromServer: iniciando sync desde ${since?.toIso8601String() ?? "início"}');

      // 1) Push local -> remoto (melhor esforço)
      try {
        final localDtos = await _localDao.getAll();
        if (localDtos.isNotEmpty) {
          if (kDebugMode) print('MaintenanceTasksRepositoryImpl.syncFromServer: enviando ${localDtos.length} items ao remoto (push)');
          final pushed = await _remote.upsertMaintenanceTasks(localDtos);
          if (kDebugMode) print('MaintenanceTasksRepositoryImpl.syncFromServer: push devolveu $pushed rows');
        }
      } catch (e) {
        if (kDebugMode) print('MaintenanceTasksRepositoryImpl.syncFromServer: push falhou - $e');
      }

      final page = await _remote.fetchMaintenanceTasks(limit: 500);
      if (page.items.isEmpty) {
        if (kDebugMode) print('MaintenanceTasksRepositoryImpl.syncFromServer: nenhuma mudança recebida');
        return 0;
      }

      await _localDao.upsertAll(page.items);

      // Atualiza último sync com a mais nova nextDueDate encontrada
      final newest = _computeNewestDate(page.items);
      await prefs.setString(_lastSyncKey, newest.toUtc().toIso8601String());

      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.syncFromServer: aplicadas ${page.items.length} mudanças');
      return page.items.length;
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.syncFromServer: erro - $e');
      return 0;
    }
  }

  @override
  Future<List<MaintenanceTaskEntity>> listAll() async {
    try {
      final dtos = await _localDao.getAll();
      final entities = _mapper.dtoListToEntityList(dtos);
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.listAll: retornando ${entities.length} tarefas');
      return entities;
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.listAll: erro - $e');
      return [];
    }
  }

  @override
  Future<List<MaintenanceTaskEntity>> listFeatured() async {
    final all = await listAll();
    return all.where((t) => t.isOverdue || t.daysRemaining <= 3).toList();
  }

  @override
  Future<MaintenanceTaskEntity?> getById(String id) async {
    try {
      final dto = await _localDao.getById(id);
      if (dto == null) return null;
      return _mapper.dtoToEntity(dto);
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.getById: erro - $e');
      return null;
    }
  }

  @override
  Future<void> create(MaintenanceTaskEntity task) async {
    try {
      final dto = _mapper.entityToDto(task);
      // escreve no servidor
      await supabase.from('maintenance_tasks').insert(dto.toJson());
      // sincroniza para atualizar cache local
      await syncFromServer();
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.create: erro - $e');
      rethrow;
    }
  }

  @override
  Future<void> update(MaintenanceTaskEntity task) async {
    try {
      final dto = _mapper.entityToDto(task);
      await supabase.from('maintenance_tasks').update(dto.toJson()).eq('id', task.id);
      await syncFromServer();
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.update: erro - $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Attempt to delete from remote (best-effort)
      try {
        await supabase.from('maintenance_tasks').delete().eq('id', id);
      } catch (e) {
        if (kDebugMode) print('MaintenanceTasksRepositoryImpl.delete: erro ao deletar no remoto - $e');
      }

      // Remove from local cache immediately so UI reflects the change
      await _localDao.delete(id);
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.delete: $id deletado localmente');

      // Then trigger a sync to reconcile any further changes
      await syncFromServer();
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl.delete: erro - $e');
      rethrow;
    }
  }

  DateTime _computeNewestDate(List<MaintenanceTaskDto> dtos) {
    try {
      if (dtos.isEmpty) return DateTime.now().toUtc();
      DateTime newest = DateTime.fromMillisecondsSinceEpoch(0);
      for (var d in dtos) {
        try {
          final dt = DateTime.parse(d.nextDueDate);
          if (dt.isAfter(newest)) newest = dt;
        } catch (_) {}
      }
      if (newest == DateTime.fromMillisecondsSinceEpoch(0)) return DateTime.now().toUtc();
      return newest;
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksRepositoryImpl._computeNewestDate: erro - $e');
      return DateTime.now().toUtc();
    }
  }
}