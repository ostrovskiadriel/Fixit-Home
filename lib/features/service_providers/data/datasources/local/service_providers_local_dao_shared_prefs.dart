import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dtos/service_provider_dto.dart';
import 'service_providers_local_dao.dart';

class ServiceProvidersLocalDaoSharedPrefs implements ServiceProvidersLocalDao {
  static const String _storageKey = 'service_providers_cache';
  final SharedPreferences _prefs;

  ServiceProvidersLocalDaoSharedPrefs({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<void> clear() async {
    await _prefs.remove(_storageKey);
    if (kDebugMode) print('ServiceProvidersLocalDaoSharedPrefs.clear: cache limpo');
  }

  @override
  Future<void> delete(String id) async {
    try {
      final dtos = await getAll();
      final filtered = dtos.where((d) => d.id != id).toList();
      final jsonString = jsonEncode(filtered.map((d) => d.toJson()).toList());
      await _prefs.setString(_storageKey, jsonString);
      if (kDebugMode) print('ServiceProvidersLocalDaoSharedPrefs.delete: $id deletado');
    } catch (e) {
      if (kDebugMode) print('ServiceProvidersLocalDaoSharedPrefs.delete: erro - $e');
      rethrow;
    }
  }

  @override
  Future<List<ServiceProviderDto>> getAll() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      final list = jsonDecode(jsonString) as List<dynamic>;
      final dtos = list.map((e) => ServiceProviderDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      if (kDebugMode) print('ServiceProvidersLocalDaoSharedPrefs.getAll: carregados ${dtos.length}');
      return dtos;
    } catch (e) {
      if (kDebugMode) print('ServiceProvidersLocalDaoSharedPrefs.getAll: erro - $e');
      return [];
    }
  }

  @override
  Future<ServiceProviderDto?> getById(String id) async {
    final dtos = await getAll();
    try {
      return dtos.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertAll(List<ServiceProviderDto> dtos) async {
    try {
      final existing = await getAll();
      final map = {for (var e in existing) e.id: e};
      for (var d in dtos) {
        map[d.id] = d;
      }
      final jsonString = jsonEncode(map.values.map((d) => d.toJson()).toList());
      await _prefs.setString(_storageKey, jsonString);
      if (kDebugMode) print('ServiceProvidersLocalDaoSharedPrefs.upsertAll: ${dtos.length} upserted');
    } catch (e) {
      if (kDebugMode) print('ServiceProvidersLocalDaoSharedPrefs.upsertAll: erro - $e');
      rethrow;
    }
  }
}
