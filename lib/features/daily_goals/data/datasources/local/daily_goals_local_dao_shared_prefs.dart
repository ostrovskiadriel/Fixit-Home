import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dtos/daily_goal_dto.dart';
import 'daily_goals_local_dao.dart';

/// Implementação do DAO usando SharedPreferences para cache local.
///
/// Armazena a lista de metas como JSON serializado em SharedPreferences.
/// Ideal para pequenos conjuntos de dados (< 1MB) ou prototipagem rápida.
///
/// ⚠️ Dicas práticas:
/// - Para grandes volumes, considere migrar para SQLite
/// - Sempre verifique se SharedPreferences está inicializado
/// - Use try/catch ao fazer parse de JSON
/// - Log com kDebugMode para diagnóstico
class DailyGoalsLocalDaoSharedPrefs implements DailyGoalsLocalDao {
  static const String _storageKey = 'daily_goals_cache';

  final SharedPreferences _prefs;

  DailyGoalsLocalDaoSharedPrefs({required SharedPreferences prefs})
      : _prefs = prefs;

  /// Carrega todas as metas do SharedPreferences.
  @override
  Future<List<DailyGoalDto>> getAll() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        if (kDebugMode) {
          print('DailyGoalsLocalDaoSharedPrefs.getAll: cache vazio');
        }
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final dtos = jsonList
          .map((item) => DailyGoalDto.fromJson(item as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print('DailyGoalsLocalDaoSharedPrefs.getAll: carregadas ${dtos.length} metas');
      }

      return dtos;
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsLocalDaoSharedPrefs.getAll: erro ao carregar - $e');
      }
      return [];
    }
  }

  /// Busca uma meta pelo ID.
  @override
  Future<DailyGoalDto?> getById(String id) async {
    try {
      final dtos = await getAll();
      final dto = dtos.firstWhere(
        (dto) => dto.goalId == id,
        orElse: () => throw Exception('Meta não encontrada'),
      );
      return dto;
    } catch (_) {
      if (kDebugMode) {
        print('DailyGoalsLocalDaoSharedPrefs.getById: meta com ID $id não encontrada');
      }
      return null;
    }
  }

  /// Insere ou atualiza (upsert) uma lista de metas.
  @override
  Future<void> upsertAll(List<DailyGoalDto> dtos) async {
    try {
      final allDtos = await getAll();

      // Mapa para acesso rápido
      final dtoMap = {for (var dto in allDtos) dto.goalId: dto};

      // Atualizar ou inserir
      for (var newDto in dtos) {
        dtoMap[newDto.goalId] = newDto;
      }

      // Salvar tudo novamente
      final jsonList = dtoMap.values.map((dto) => dto.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_storageKey, jsonString);

      if (kDebugMode) {
        print('DailyGoalsLocalDaoSharedPrefs.upsertAll: ${dtos.length} metas upserted, total: ${dtoMap.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsLocalDaoSharedPrefs.upsertAll: erro ao fazer upsert - $e');
      }
      rethrow;
    }
  }

  /// Deleta uma meta pelo ID.
  @override
  Future<void> delete(String id) async {
    try {
      final dtos = await getAll();
      final filtered = dtos.where((dto) => dto.goalId != id).toList();

      final jsonList = filtered.map((dto) => dto.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_storageKey, jsonString);

      if (kDebugMode) {
        print('DailyGoalsLocalDaoSharedPrefs.delete: meta $id deletada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsLocalDaoSharedPrefs.delete: erro ao deletar - $e');
      }
      rethrow;
    }
  }

  /// Limpa todo o cache de metas.
  @override
  Future<void> clear() async {
    try {
      await _prefs.remove(_storageKey);
      if (kDebugMode) {
        print('DailyGoalsLocalDaoSharedPrefs.clear: cache limpo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsLocalDaoSharedPrefs.clear: erro ao limpar - $e');
      }
      rethrow;
    }
  }
}
