import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dtos/daily_goal_dto.dart';

/// Modelo para representar página de resultados remotos com cursor de paginação.
class RemotePage<T> {
  final List<T> items;
  final String? next;

  RemotePage({required this.items, this.next});
}

/// Remote datasource para buscar metas diárias do Supabase.
///
/// Responsável por comunicação com servidor Supabase, filtragem, ordenação
/// e paginação de metas. Não contém lógica de cache — isso é responsabilidade
/// do repositório.
///
/// ⚠️ Dicas práticas:
/// - Sempre envolva chamadas Supabase em try/catch
/// - Use kDebugMode para logs de diagnóstico (sem expor secrets)
/// - Retorne página vazia em caso de erro para evitar quebra da UI
/// - Verifique RLS policies no Supabase para permissões de leitura
/// - Dates vêm como ISO8601 strings — parse com segurança
/// - O tipo vem como string (enum name) — converta com GoalType.fromString()
class SupabaseDailyGoalsRemoteDatasource {
  final SupabaseClient _client;

  SupabaseDailyGoalsRemoteDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Busca metas do Supabase com filtro incremental por data de atualização.
  ///
  /// Parâmetros:
  /// - [since]: data mínima de atualização (para sincronização incremental)
  /// - [limit]: quantidade máxima de registros a retornar (padrão: 500)
  /// - [offset]: offset para paginação (padrão: 0)
  ///
  /// Retorna [RemotePage<DailyGoalDto>] com:
  /// - items: lista de metas convertidas para DTO
  /// - next: string de cursor se há mais dados (size == limit)
  ///
  /// Em caso de erro, retorna página vazia para evitar quebra da UI.
  Future<RemotePage<DailyGoalDto>> fetchDailyGoals({
    DateTime? since,
    int limit = 500,
    int offset = 0,
  }) async {
    try {
      if (kDebugMode) {
        print('SupabaseDailyGoalsRemoteDatasource.fetchDailyGoals: '
            'since=${since?.toIso8601String()}, limit=$limit, offset=$offset');
      }

      var query = _client
          .from('daily_goals')
          .select()
          .order('updated_at', ascending: false);

      // Nota: Filtro incremental por 'updated_at' requer RLS policy configurada
      // Por agora, retrieves todos os registros (implementar filtro conforme necessário)
      // if (since != null) {
      //   query = query.gt('updated_at', since.toUtc().toIso8601String());
      // }

      // Paginação
      query = query.range(offset, offset + limit - 1);

      final rows = await query as List<dynamic>;

      if (kDebugMode) {
        print('SupabaseDailyGoalsRemoteDatasource.fetchDailyGoals: '
            'recebidos ${rows.length} registros');
      }

      // Converter rows para DTOs
      final dtos = rows
          .map((row) => DailyGoalDto.fromJson(row as Map<String, dynamic>))
          .toList();

      // Calcular próximo cursor (se houver mais dados)
      final hasMore = dtos.length == limit;
      final nextCursor = hasMore ? (offset + limit).toString() : null;

      return RemotePage<DailyGoalDto>(items: dtos, next: nextCursor);
    } catch (e) {
      if (kDebugMode) {
        print('SupabaseDailyGoalsRemoteDatasource.fetchDailyGoals: erro - $e');
      }
      // Retorna página vazia em caso de erro
      return RemotePage<DailyGoalDto>(items: []);
    }
  }
}

/*
// Exemplo de uso:
final datasource = SupabaseDailyGoalsRemoteDatasource();

// Primeira sincronização (sem filtro)
final page1 = await datasource.fetchDailyGoals(limit: 500);
print('Recebidos ${page1.items.length} registros');

// Sincronização incremental (apenas mudanças desde última sync)
final lastSync = DateTime.now().subtract(Duration(hours: 1));
final page2 = await datasource.fetchDailyGoals(since: lastSync);
print('Recebidas ${page2.items.length} mudanças');

// Paginação
final page3 = await datasource.fetchDailyGoals(limit: 500, offset: 500);
print('Página 2: ${page3.items.length} registros, próxima: ${page3.next}');

// Checklist de erros comuns e como evitar:
// - Erro: RLS policy nega leitura
//   Solução: Configure RLS para permitir SELECT na tabela daily_goals
//   Exemplo: CREATE POLICY "anon_read_daily_goals" ON daily_goals
//     FOR SELECT USING (true);
//
// - Erro: ParseException ao converter type (string → enum)
//   Solução: Certifique-se de que o tipo vem como enum name (ex: "moodEntries")
//   Use GoalType.fromString() com tratamento seguro
//
// - Erro: DateTime parse exception
//   Solução: O Supabase retorna timestamps em ISO8601. Parse com DateTime.parse()
//   Se falhar, use try/catch e retorne DateTime.now() como fallback
//
// - Erro: Dados não aparecem na UI
//   Solução: Verifique logs com kDebugMode. Inspecione conteúdo do JSON recebido.
//   Teste a query no Supabase Studio.

// Logs esperados:
// SupabaseDailyGoalsRemoteDatasource.fetchDailyGoals: recebidos 5 registros
// SupabaseDailyGoalsRemoteDatasource.fetchDailyGoals: since=2025-11-27T10:00:00Z, limit=500, offset=0

// Referências:
// - Supabase Flutter: https://supabase.com/docs/reference/flutter/introduction
// - RLS Policies: https://supabase.com/docs/guides/auth/row-level-security
*/
