import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixit_home/features/daily_goals/domain/entities/daily_goal_entity.dart';
import 'package:fixit_home/features/daily_goals/domain/repositories/daily_goals_repository.dart';
import '../datasources/local/daily_goals_local_dao.dart';
import '../datasources/remote/supabase_daily_goals_remote_datasource.dart';
import '../mappers/daily_goal_mapper.dart';

/// Implementação concreta do repositório de metas diárias.
///
/// Combina:
/// - **Remote datasource**: Busca dados atualizados do Supabase
/// - **Local DAO**: Gerencia cache local em SharedPreferences/SQLite
/// - **Mapper**: Converte entre DTO (dados) e Entidade (domínio)
/// - **Sincronização incremental**: Usa timestamp "updated_at" para eficiência
///
/// Fluxo típico:
/// 1. loadFromCache() → carrega dados local rapidamente
/// 2. syncFromServer() → sincroniza mudanças do servidor
/// 3. listAll() → retorna lista completa (após sync)
///
/// ⚠️ Dicas práticas:
/// - Sempre verifique se widget está mounted antes de setState em métodos assíncronos
/// - Use kDebugMode para logs de diagnóstico (sem expor secrets)
/// - Trate erros gracefully — retorne dados vazios ou do cache anterior
/// - Sincronização incremental economiza banda — sempre use "since" quando possível
/// - Versione a chave de sync para permitir cache-busting se necessário
class DailyGoalsRepositoryImpl implements DailyGoalsRepository {
  final SupabaseDailyGoalsRemoteDatasource _remoteDatasource;
  final DailyGoalsLocalDao _localDao;
  final DailyGoalMapper _mapper;
  final Future<SharedPreferences> _prefsAsync;

  // Chave para armazenar timestamp da última sincronização
  static const String _lastSyncKey = 'daily_goals_last_sync_v1';

  DailyGoalsRepositoryImpl({
    required SupabaseDailyGoalsRemoteDatasource remoteDatasource,
    required DailyGoalsLocalDao localDao,
    required DailyGoalMapper mapper,
    Future<SharedPreferences>? prefsAsync,
  })  : _remoteDatasource = remoteDatasource,
        _localDao = localDao,
        _mapper = mapper,
        _prefsAsync = prefsAsync ?? SharedPreferences.getInstance();

  /// Carrega metas do cache local para render rápido.
  ///
  /// Use na inicialização da tela para exibir dados imediatamente
  /// sem esperar pela rede. Retorna lista vazia se cache vazio.
  @override
  Future<List<DailyGoalEntity>> loadFromCache() async {
    try {
      final cachedDtos = await _localDao.getAll();
      final entities = _mapper.dtoListToEntityList(cachedDtos);

      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.loadFromCache: carregadas ${entities.length} metas do cache');
      }

      return entities;
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.loadFromCache: erro - $e');
      }
      return [];
    }
  }

  /// Sincroniza metas do Supabase de forma incremental.
  ///
  /// - Recupera apenas registros modificados desde última sincronização
  /// - Usa campo "updated_at" para eficiência
  /// - Retorna quantidade de registros sincronizados
  /// - Atualiza marcador de última sincronização
  ///
  /// Use periodicamente (ex: em background tasks) para manter cache atualizado.
  @override
  Future<int> syncFromServer() async {
    try {
      final prefs = await _prefsAsync;
      final lastSyncIso = prefs.getString(_lastSyncKey);

      // Parse da última sincronização
      DateTime? since;
      if (lastSyncIso != null && lastSyncIso.isNotEmpty) {
        try {
          since = DateTime.parse(lastSyncIso);
        } catch (e) {
          if (kDebugMode) {
            print('DailyGoalsRepositoryImpl.syncFromServer: erro ao parsear lastSync - $e');
          }
        }
      }

      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.syncFromServer: iniciando sync desde ${since?.toIso8601String() ?? "início"}');
      }

      // Buscar do servidor
      final page = await _remoteDatasource.fetchDailyGoals(since: since, limit: 500);

      if (page.items.isEmpty) {
        if (kDebugMode) {
          print('DailyGoalsRepositoryImpl.syncFromServer: nenhuma mudança recebida');
        }
        return 0;
      }

      // Fazer upsert no cache local
      await _localDao.upsertAll(page.items);

      // Atualizar marcador de última sincronização
      final newestDate = _computeNewestDate(page.items);
      await prefs.setString(_lastSyncKey, newestDate.toUtc().toIso8601String());

      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.syncFromServer: aplicadas ${page.items.length} mudanças');
      }

      return page.items.length;
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.syncFromServer: erro - $e');
      }
      return 0;
    }
  }

  /// Retorna lista completa de metas do cache.
  ///
  /// Use após syncFromServer() para garantir dados atualizados.
  /// Para render inicial rápido, use loadFromCache().
  @override
  Future<List<DailyGoalEntity>> listAll() async {
    try {
      final cachedDtos = await _localDao.getAll();
      final entities = _mapper.dtoListToEntityList(cachedDtos);

      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.listAll: retornando ${entities.length} metas');
      }

      return entities;
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.listAll: erro - $e');
      }
      return [];
    }
  }

  /// Retorna apenas metas em destaque (filtradas por flag ou critério).
  ///
  /// Implementação padrão: retorna todas (usar para adicionar filtro específico).
  /// Use para exibir metas prioritárias na home screen.
  @override
  Future<List<DailyGoalEntity>> listFeatured() async {
    try {
      final allEntities = await listAll();
      // TODO: Implementar filtro específico se houver campo 'featured' na entidade
      // Por enquanto, retorna todas
      return allEntities;
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.listFeatured: erro - $e');
      }
      return [];
    }
  }

  /// Busca uma meta específica pelo ID.
  ///
  /// Use para obter detalhes de uma meta individual.
  /// Retorna null se meta não encontrada.
  @override
  Future<DailyGoalEntity?> getById(String id) async {
    try {
      final cachedDto = await _localDao.getById(id);
      if (cachedDto == null) {
        if (kDebugMode) {
          print('DailyGoalsRepositoryImpl.getById: meta $id não encontrada');
        }
        return null;
      }

      final entity = _mapper.dtoToEntity(cachedDto);

      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.getById: meta $id encontrada');
      }

      return entity;
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.getById: erro - $e');
      }
      return null;
    }
  }

  /// Salva ou atualiza uma meta no cache local.
  ///
  /// Converte Entidade para DTO e faz upsert.
  /// Retorna true se bem-sucedido.
  @override
  Future<bool> save(DailyGoalEntity goal) async {
    try {
      final dto = _mapper.entityToDto(goal);
      await _localDao.upsertAll([dto]);

      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.save: meta ${goal.id} salva');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.save: erro ao salvar - $e');
      }
      return false;
    }
  }

  /// Deleta uma meta do cache local.
  ///
  /// Use com cuidado — esta operação é irreversível no cache.
  /// Para soft delete, considere marcar como deletado.
  /// Retorna true se bem-sucedido.
  @override
  Future<bool> delete(String id) async {
    try {
      await _localDao.delete(id);

      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.delete: meta $id deletada');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl.delete: erro ao deletar - $e');
      }
      return false;
    }
  }

  /// Calcula a data de atualização mais recente da página de resultados.
  ///
  /// Usa para atualizar marcador de última sincronização.
  DateTime _computeNewestDate(List<dynamic> dtos) {
    try {
      if (dtos.isEmpty) return DateTime.now().toUtc();

      DateTime newest = DateTime.fromMillisecondsSinceEpoch(0);

      for (var item in dtos) {
        if (item is Map<String, dynamic> && item['date'] != null) {
          try {
            final itemDate = DateTime.parse(item['date'] as String);
            if (itemDate.isAfter(newest)) {
              newest = itemDate;
            }
          } catch (_) {
            // Ignorar se falhar parse
          }
        }
      }

      // Se não conseguiu extrair data, usa agora
      if (newest == DateTime.fromMillisecondsSinceEpoch(0)) {
        return DateTime.now().toUtc();
      }

      return newest;
    } catch (e) {
      if (kDebugMode) {
        print('DailyGoalsRepositoryImpl._computeNewestDate: erro - $e, usando DateTime.now()');
      }
      return DateTime.now().toUtc();
    }
  }
}

/*
// Exemplo de uso:
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixit_home/features/daily_goals/data/datasources/local/daily_goals_local_dao_shared_prefs.dart';
import 'package:fixit_home/features/daily_goals/data/datasources/remote/supabase_daily_goals_remote_datasource.dart';
import 'package:fixit_home/features/daily_goals/data/mappers/daily_goal_mapper.dart';
import 'package:fixit_home/features/daily_goals/data/repositories/daily_goals_repository_impl.dart';

// Inicializar dependências
final prefs = await SharedPreferences.getInstance();
final localDao = DailyGoalsLocalDaoSharedPrefs(prefs: prefs);
final remoteDatasource = SupabaseDailyGoalsRemoteDatasource();
final mapper = DailyGoalMapper();

// Criar repositório
final repo = DailyGoalsRepositoryImpl(
  remoteDatasource: remoteDatasource,
  localDao: localDao,
  mapper: mapper,
  prefsAsync: Future.value(prefs),
);

// Usar na tela
final cachedMetas = await repo.loadFromCache(); // Render rápido
await repo.syncFromServer();                      // Atualizar
final todasMetas = await repo.listAll();          // Usar dados atualizados

// Checklist de erros comuns e como evitar:
// - Erro: "RLS policy prevents reading"
//   Solução: Configure RLS no Supabase para permitir SELECT
//
// - Erro: "Parse exception na conversão de tipo"
//   Solução: Verifique se DTO e Mapper aceitam múltiplos formatos (String para enum, DateTime parse)
//
// - Erro: "Dados não atualizam na UI"
//   Solução: Verifique se widget está mounted antes de setState
//   Adicione prints/logs com kDebugMode para diagnosticar
//
// - Erro: "Cache fica desincronizado"
//   Solução: Incremente versão em _lastSyncKey (v1 → v2) para forçar full sync
//
// - Erro: "Performance lenta com muitos dados"
//   Solução: Migre DAO de SharedPreferences para SQLite
//   Use paginação no remote datasource

// Logs esperados:
// DailyGoalsRepositoryImpl.loadFromCache: carregadas 5 metas do cache
// DailyGoalsRepositoryImpl.syncFromServer: aplicadas 2 mudanças
// DailyGoalsRepositoryImpl.listAll: retornando 7 metas
// DailyGoalsRepositoryImpl.save: meta abc123 salva

// Referências:
// - DailyGoalEntity: lib/features/daily_goals/domain/entities/daily_goal_entity.dart
// - DailyGoalsRepository: lib/features/daily_goals/domain/repositories/daily_goals_repository.dart
// - SupabaseDailyGoalsRemoteDatasource: lib/features/daily_goals/data/datasources/remote/...
// - DailyGoalMapper: lib/features/daily_goals/data/mappers/daily_goal_mapper.dart
// - DailyGoalsLocalDao: lib/features/daily_goals/data/datasources/local/daily_goals_local_dao.dart
*/
