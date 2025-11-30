````markdown

# Prompt operacional adaptado: Sincronização de página/primeiro carregamento (FixIt Home)

> **Visão geral:** Este prompt orienta a geração de alterações na UI para que as telas de listagem (ex.: metas diárias ou tarefas de manutenção) usem os repositórios e façam um sync inicial automático quando o cache local estiver vazio. O objetivo é dar um comportamento robusto, testável e didático, com logs, tratamento de erros e dicas de UX.

Objetivo
--------
Gerar/instrumentar o código necessário para que as telas de listagem das features do FixIt Home (ex.: `daily_goals` e `maintenance_tasks`) consumam o DAO local e, caso o cache local esteja vazio, executem uma sincronização única via o repositório (que orquestra remote datasource + DAO local). Isso deve ser feito sem bloquear a UX e com logs/dicas explicativas.

Contexto do projeto
-------------------
- Entidades e repositórios já presentes no projeto:
  - `DailyGoalEntity` + `DailyGoalsRepository` / `DailyGoalsRepositoryImpl`
  - `MaintenanceTaskEntity` + `MaintenanceTasksRepository` / `MaintenanceTasksRepositoryImpl`
- DAOs locais disponíveis (SharedPreferences implementations):
  - `DailyGoalsLocalDaoSharedPrefs`
  - `MaintenanceTasksLocalDaoSharedPrefs`
- Remote datasources já implementados: `SupabaseDailyGoalsRemoteDatasource`, `SupabaseMaintenanceTasksRemoteDatasource`
- Supabase já inicializado via `main.dart` e `PrefsService` para persistência local

Escopo da alteração
-------------------
Para cada tela de listagem (ex.: `daily_goals_list_screen.dart`, `maintenance_tasks_list_screen.dart`):

1. Importar e usar o DAO local + repositório (não acessar Supabase diretamente).
2. Implementar `_loadItems()` (nome livre) com o seguinte fluxo:
   - 1) Carregar do DAO local (`dao.getAll()` / `repository.loadFromCache()` se existir)
   - 2) Se resultado vazio, inicializar `RemoteDatasource` + `RepositoryImpl` e executar `await repo.syncFromServer()` dentro de `try/catch` com logs
   - 3) Recarregar do DAO local e atualizar estado (usar `setState` apenas se `mounted`)
   - 4) Garantir que a UI mostre um `RefreshIndicator`/pull-to-refresh mesmo se lista vazia

3. Adicionar logs (usar `kDebugMode`) em pontos-chave: início carregamento do cache, início sync, sucesso/erro do sync, número de itens aplicados.

4. Inserir comentários explicativos e dicas em português sobre as boas práticas (ex: por que checar cache, quando forçar full-sync, versionar a chave de lastSync, não bloquear UI, RLS do Supabase, tratamento de parsing de datas/enum).

Requisitos exatos que a geração deve produzir
-------------------------------------------
- Em cada tela de listagem:
  - Usar **somente** o DAO local e o Repository (ou métodos do repository) — não deixar queries diretas ao `supabase` na UI.
  - Implementar função assíncrona que: carrega cache, se vazio chama `syncFromServer()`, recarrega cache e atualiza UI.
  - Incluir `try/catch` ao redor do `syncFromServer()` e logar erros com `kDebugMode`.
  - Verificar `mounted` antes de `setState`.
  - Garantir `RefreshIndicator` com `AlwaysScrollableScrollPhysics()` para permitir pull-to-refresh mesmo com lista vazia.

- Exemplo de código (resumido) a ser inserido na tela:
```dart
final dao = DailyGoalsLocalDaoSharedPrefs(prefs: prefs); // ou obter via provider
final repo = DailyGoalsRepositoryImpl(remoteDatasource: SupabaseDailyGoalsRemoteDatasource(), localDao: dao, mapper: DailyGoalMapper());

Future<void> _loadItems() async {
  if (kDebugMode) print('Tela: carregando cache local...');
  final items = await dao.getAll();
  if (items.isEmpty) {
    if (kDebugMode) print('Cache vazio — executando sync inicial...');
    try {
      await repo.syncFromServer();
    } catch (e) {
      if (kDebugMode) print('Sync inicial falhou: $e');
    }
  }

  final refreshed = await dao.getAll();
  if (!mounted) return;
  setState(() => _items = refreshed.map((d) => mapper.dtoToEntity(d)).toList());
}
```

Investigação obrigatória antes de executar o prompt
--------------------------------------------------
O agente que usar este prompt deve primeiro:
1. Confirmar o caminho exato do arquivo de listagem a ser modificado (ex.: `lib/features/daily_goals/presentation/pages/daily_goals_list_screen.dart`).
2. Confirmar nomes das classes DAO/Repository/Mapper usadas no projeto (ex.: `DailyGoalsLocalDaoSharedPrefs`, `DailyGoalsRepositoryImpl`, `DailyGoalMapper`).
3. Verificar se existe `PrefsService` / `SharedPreferences` inicializável no `main.dart`.
4. Confirmar se a UI possui `setState`/mounted flows compatíveis (ex.: StatefulWidget).

Boas práticas e dicas (para incluir nos comentários gerados)
---------------------------------------------------------
- Sempre verificar `mounted` antes de `setState` em callbacks assíncronos.
- Versione a chave de last-sync na persistência (`daily_goals_last_sync_v1`) se mudar o formato do sync.
- Acrescente logs com `kDebugMode` contendo apenas dados não sensíveis (não exponha keys).
- Trate parsing de datas e enums com try/catch e valores default seguros.
- Use pagination e limites no datasource remoto para evitar OOM.
- Para grande volume de dados, migre DAO de SharedPreferences para SQLite.

Checklist de validação
----------------------
- [ ] `flutter analyze` passa sem erros
- [ ] Tela populada a partir do cache quando disponível
- [ ] Na primeira execução (cache vazio) a tela solicita sync e o cache é preenchido
- [ ] Pull-to-refresh funciona com lista vazia
- [ ] Logs com `kDebugMode` presentes nos pontos chave
- [ ] Não há queries diretas ao `supabase` na UI (repositórios/DAO devem ser usados)

Exemplos de logs esperados
-------------------------
- `DailyGoalsPage._loadItems: carregando cache local...`
- `DailyGoalsRepositoryImpl.syncFromServer: aplicados 5 registros`
- `MaintenanceTasksPage._loadItems: cache vazio — sync inicial` 

Notas finais
-----------
- Este prompt foca no sync inicial quando o cache está vazio. Para requisitos mais avançados (sincronização periódica, background sync, conflito de merge), criar prompt/serviço separado.
- Sempre teste o fluxo com dados reais no Supabase Studio e ajuste as queries caso a estrutura da tabela seja diferente.

````