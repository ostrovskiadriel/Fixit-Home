import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dtos/maintenance_task_dto.dart';
import 'maintenance_tasks_local_dao.dart';

class MaintenanceTasksLocalDaoSharedPrefs implements MaintenanceTasksLocalDao {
  static const String _storageKey = 'maintenance_tasks_cache';
  final SharedPreferences _prefs;

  MaintenanceTasksLocalDaoSharedPrefs({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<void> clear() async {
    await _prefs.remove(_storageKey);
    if (kDebugMode) print('MaintenanceTasksLocalDaoSharedPrefs.clear: cache limpo');
  }

  @override
  Future<void> delete(String id) async {
    try {
      final dtos = await getAll();
      final filtered = dtos.where((d) => d.id != id).toList();
      final jsonString = jsonEncode(filtered.map((d) => d.toJson()).toList());
      await _prefs.setString(_storageKey, jsonString);
      if (kDebugMode) print('MaintenanceTasksLocalDaoSharedPrefs.delete: $id deletado');
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksLocalDaoSharedPrefs.delete: erro - $e');
      rethrow;
    }
  }

  @override
  Future<List<MaintenanceTaskDto>> getAll() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      final list = jsonDecode(jsonString) as List<dynamic>;
      final dtos = list.map((e) => MaintenanceTaskDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      if (kDebugMode) print('MaintenanceTasksLocalDaoSharedPrefs.getAll: carregados ${dtos.length}');
      return dtos;
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksLocalDaoSharedPrefs.getAll: erro - $e');
      return [];
    }
  }

  @override
  Future<MaintenanceTaskDto?> getById(String id) async {
    final dtos = await getAll();
    try {
      return dtos.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertAll(List<MaintenanceTaskDto> dtos) async {
    try {
      final existing = await getAll();
      final map = {for (var e in existing) e.id: e};
      for (var d in dtos) {
        map[d.id] = d;
      }
      final jsonString = jsonEncode(map.values.map((d) => d.toJson()).toList());
      await _prefs.setString(_storageKey, jsonString);
      if (kDebugMode) print('MaintenanceTasksLocalDaoSharedPrefs.upsertAll: ${dtos.length} upserted');
    } catch (e) {
      if (kDebugMode) print('MaintenanceTasksLocalDaoSharedPrefs.upsertAll: erro - $e');
      rethrow;
    }
  }
}
