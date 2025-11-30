# 18 - Sincronização bidirecional (Push then Pull) — Adaptado para FixIt Home

> Objetivo: adaptar o padrão didático de sincronização bidirecional (push então pull) para as entidades do FixIt Home (ex.: `DailyGoalEntity`, `MaintenanceTaskEntity`). Este documento descreve o que mudar, onde alterar, exemplos de código e passos de verificação para garantir que o cache local e o Supabase convergem.

Resumo
------
Neste projeto usamos SharedPreferences como DAO rápido para cache local e Supabase como backend remoto. A sincronização bidirecional aqui significa:
1. Push (melhor esforço): enviar alterações locais ao servidor (upsert em lote) — útil quando o DAO não trackea flags "dirty" por item.
2. Pull (incremental): buscar apenas mudanças remotas desde o `lastSync` e aplicar no cache local.

Aplicabilidade no FixIt Home
----------------------------
- Entidades alvo (exemplos):
  - `DailyGoalEntity` (metas diárias)
  - `MaintenanceTaskEntity` (tarefas de manutenção)

- Repositórios já presentes:
  - `DailyGoalsRepositoryImpl`
  - `MaintenanceTasksRepositoryImpl`

- DAOs locais (SharedPreferences):
  - `DailyGoalsLocalDaoSharedPrefs`
  - `MaintenanceTasksLocalDaoSharedPrefs`

- Remote datasources:
  - `SupabaseDailyGoalsRemoteDatasource`
  - `SupabaseMaintenanceTasksRemoteDatasource`

Alterações principais a implementar
----------------------------------
1. Remote datasource: adicionar método `Future<int> upsertXxx(List<XxxDto> dtos)` para suportar upsert em lote (usando `upsert` do Supabase).
   - Arquivos: `lib/features/daily_goals/data/datasources/remote/supabase_daily_goals_remote_datasource.dart`
             `lib/features/maintenance_tasks/data/datasources/remote/supabase_maintenance_tasks_remote_datasource.dart`
   - Comportamento: enviar `List<Map<String, dynamic>>` com `dto.toJson()` e retornar um contador de linhas afetadas (ou null/0 em erro).

2. Repositório: atualizar `syncFromServer()` para executar o fluxo push→pull:
   - Ler tudo do DAO local (`localDao.getAll()`)
   - Tentar `await remote.upsertXxx(localDtos)` dentro de `try/catch` (best-effort — falhas não bloqueiam o pull)
   - Executar `await remote.fetchXxx(since: lastSync)` (pull incremental)
   - `await localDao.upsertAll(remoteDtos)` para aplicar mudanças locais
   - Atualizar `lastSync` com o máximo `updated_at` recebido
   - Arquivos: `DailyGoalsRepositoryImpl` e `MaintenanceTasksRepositoryImpl`

3. Logs e diagnósticos: usar `kDebugMode` para imprimir pontos importantes:
   - Antes do push: quantos items serão enviados
   - Resultado do upsert: sucesso/erro e data
   - Pull: quantas mudanças recebidas
   - Aplicação local: quantos itens upserted

Exemplo de implementação (esquemático)
-------------------------------------
// No Remote Datasource (DailyGoals)
Future<int> upsertDailyGoals(List<DailyGoalDto> dtos) async {
  try {
    final rows = await _client.from('daily_goals').upsert(dtos.map((d) => d.toJson()).toList()).select();
    return (rows as List).length;
  } catch (e) {
    if (kDebugMode) print('SupabaseDailyGoalsRemoteDatasource.upsert: erro - $e');
    return 0;
  }
}

// No Repositório (DailyGoals)
Future<int> syncFromServer() async {
  final prefs = await _prefsAsync;
  final lastSyncIso = prefs.getString(_lastSyncKey);
  DateTime? since;
  if (lastSyncIso != null) try { since = DateTime.parse(lastSyncIso); } catch (_) {}

  // 1) Push (melhor esforço)
  try {
    final localDtos = await _localDao.getAll();
    if (localDtos.isNotEmpty) {
      if (kDebugMode) print('DailyGoalsRepositoryImpl.sync: enviando ${localDtos.length} items ao remoto');
      await _remoteDatasource.upsertDailyGoals(localDtos);
      if (kDebugMode) print('DailyGoalsRepositoryImpl.sync: push concluído');
    }
  } catch (e) {
    if (kDebugMode) print('DailyGoalsRepositoryImpl.sync: push falhou - $e');
  }

  // 2) Pull incremental
  final page = await _remoteDatasource.fetchDailyGoals(since: since, limit: 500);
  if (page.items.isNotEmpty) {
    await _localDao.upsertAll(page.items);
    final newest = _computeNewestDate(page.items);
    await prefs.setString(_lastSyncKey, newest.toUtc().toIso8601String());
  }

  return page.items.length;
}

Notas importantes de design
---------------------------
- Push é "best-effort": se falhar, o pull ainda ocorre. Isso evita que problemas de rede impeçam a UI de atualizar.
- Conflitos: inicialmente, adote "Last Write Wins" baseado em timestamps `updated_at` (servidor decide). Se for necessário, implemente resolução mais sofisticada (campo `version`, merge por campo, ou prompt ao usuário).
- IDs temporários: se o cliente gera IDs locais (ex.: UUID temporário) e o servidor gera IDs, você precisará de lógica para reconciliar (mapear temporário → server-id). No modelo atual (usando `goal_id`/`id`) prefira UUIDs gerados no cliente para simplificar.
- Volume de dados: para muitos registros, implemente paginação no `fetch` e aplique em lotes no DAO local.

Testes e verificação
--------------------
1. Rodar análise: `flutter analyze`
2. Teste manual:
   - Limpe o cache local (prefs) e abra a tela; verifique que o pull popula a lista.
   - Crie/edite localmente um item; execute `syncFromServer()` e verifique no Supabase Studio que a alteração apareceu.
   - No Supabase Studio, edite um item; execute `syncFromServer()` no app e verifique que o change é aplicado localmente.
   - Teste falha de push: simule indisponibilidade do servidor (remova keys) — a app deve logar o erro, mas ainda executar o pull (quando possível).

3. Logs esperados (dev/debug):
   - `DailyGoalsRepositoryImpl.sync: enviando 3 items ao remoto`
   - `SupabaseDailyGoalsRemoteDatasource.upsert: enviado 3 items` (ou erro)
   - `DailyGoalsRepositoryImpl.syncFromServer: aplicadas 2 mudanças`

Boas práticas
------------
- Envolva `print` com `if (kDebugMode)`.
- Verifique `mounted` antes de `setState` na UI após sync.
- Versione a chave de last-sync (ex.: `daily_goals_last_sync_v1`) para permitir cache-busting.
- Para produção, considere usar SQLite (moor/ Drift) em vez de SharedPreferences para volumes maiores e para possibilitar flags locais de "dirty" por item.

Checklist de mudanças geradas por este prompt
--------------------------------------------
- [ ] Adicionar `upsert` nos datasources remotos
- [ ] Atualizar repositórios para executar push→pull em `syncFromServer()`
- [ ] Adicionar logs `kDebugMode` em pontos chave
- [ ] Garantir tratamento de erros e não bloquear o pull por falhas no push
- [ ] Testar manualmente os cenários de criação/edição/deleção e conflito

Próximos passos (opcionais)
--------------------------
- Implementar flags "dirty" no DAO e fazer push apenas dos items marcados (mais eficiente).
- Implementar paginação do pull quando o dataset cresce.
- Criar testes automatizados para o repositório (mockando o datasource remoto)

---

*Arquivo adaptado para FixIt Home — se quiser, aplico as mudanças de código (datasource + repositório) automaticamente neste repositório agora.*