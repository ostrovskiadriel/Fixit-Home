// lib/features/daily_goals/daily_goal_local_dto_shared_prefs.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/dtos/daily_goal_dto.dart'; // <-- CORREÇÃO AQUI
import 'data/dtos/daily_goal_local_dto.dart';

class DailyGoalLocalDtoSharedPrefs implements DailyGoalLocalDto {
  static const _cacheKey = 'daily_goal_cache_v1';
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<void> upsertAll(List<DailyGoalDto> dtos) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_cacheKey);
    final Map<String, Map<String, dynamic>> current = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        for (final e in list) {
          final m = Map<String, dynamic>.from(e as Map);
          final key = m['goal_id']?.toString();
          if (key != null) current[key] = m;
        }
      } catch (e) { await prefs.remove(_cacheKey); }
    }
    for (final dto in dtos) { current[dto.goalId] = dto.toJson(); }
    final merged = current.values.toList();
    await prefs.setString(_cacheKey, jsonEncode(merged));
  }

  @override
  Future<List<DailyGoalDto>> listAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => DailyGoalDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      await prefs.remove(_cacheKey);
      return [];
    }
  }

  @override
  Future<DailyGoalDto?> getById(String id) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        final m = Map<String, dynamic>.from(e as Map);
        if (m['goal_id'] == id) return DailyGoalDto.fromJson(m);
      }
    } catch (_) { await prefs.remove(_cacheKey); }
    return null;
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_cacheKey);
  }
}