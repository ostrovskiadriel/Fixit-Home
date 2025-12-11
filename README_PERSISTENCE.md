# Persistência e Sincronização — FixIt Home

Este documento descreve a implementação do padrão de persistência e sincronização utilizado no aplicativo FixIt Home. Ele cobre como as entidades de domínio (Daily Goals, Maintenance Tasks e Service Providers) foram implementadas usando:

- Remote: Supabase (via supabase_flutter)
- Local cache: SharedPreferences (encapsulado em DAOs)
- Camada de repositório: implementa sync bidirecional (push-then-pull), mappers e operações CRUD
- UI: consome apenas entidades de domínio (não DTOs), utiliza o repository (cache → sync pattern)

Use este README para mostrar ao professor onde está a tarefa implementada e como validar o comportamento.

---

## Sumário
- [Como testar rapidamente](#como-testar-rapidamente)
- [Fluxo geral](#fluxo-geral)
- [Arquivos por entidade](#arquivos-por-entidade)
  - Daily Goals
  - Maintenance Tasks
  - Service Providers
- [Arquivos de infraestrutura (globais)](#arquivos-de-infraestrutura-globais)
- [Observações e recomendações](#observacoes-e-recomendacoes)

---

## Como testar rapidamente
1. Configure o arquivo `.env` com suas variáveis do Supabase:

   - `SUPABASE_URL`  — URL do projeto
   - `SUPABASE_ANON_KEY` — Chave pública anon

2. Rode no terminal (Windows PowerShell):

```powershell
flutter pub get
flutter analyze
flutter run
```

3. Abra o app e navegue até: `Metas Diárias`, `Manutenções` e `Contatos Úteis`.

4. Testes funcionais:
   - Se houver cache salvo (prefs), a lista deve ser carregada rapidamente a partir do armazenamento local.
   - Se a lista estiver vazia, o repositório chamará `syncFromServer()` para puxar do Supabase.
   - Use pull-to-refresh (arraste para cima) para forçar `syncFromServer()`.
   - Crie/Edite um item: o repositório enviará os dados ao Supabase e manterá o cache local atualizado.
   - Deletar:
       - `Maintenance Tasks` e `Service Providers` removem localmente o item imediatamente (cliente atualizado) e tentam deletar remoto.
       - `Daily Goals` tem delete que tenta o servidor e limpa cache local.

---

## Fluxo geral
A arquitetura segue o mesmo padrão para todas as entidades:

1. UI carrega o repo local (`loadFromCache()`) e renderiza a lista (UI consome ENTITIES).
2. Se cache estiver vazio, a UI chama `syncFromServer()` para trazer dados do Supabase.
3. O Repository realiza:
   - Push local -> remoto (`upsert`): lê o cache local e chama o remote datasource `upsertX()`
   - Pull remoto -> local: `fetchX()` no remote datasource; em seguida `localDao.upsertAll(page.items)` para persistir no cache local
4. Repositório expõe métodos CRUD (`create`, `update`, `delete`) e sincronização (`syncFromServer()`).
5. Todas as conversões entre DTOs e Entities são feitas por `Mapper`.

Logs de debug são feitos com `kDebugMode` e `print` em pontos chave.

---

## Arquivos por entidade

Abaixo ficção dos arquivos relevantes que implementam a arquitetura por entidade:

### Daily Goals (Metas Diárias)
- Domain entity: `lib/features/daily_goals/domain/entities/daily_goal_entity.dart`
- DTO: `lib/features/daily_goals/data/dtos/daily_goal_dto.dart`
- Local DAO (interface): `lib/features/daily_goals/data/datasources/local/daily_goals_local_dao.dart`
- Local DAO (SharedPreferences): `lib/features/daily_goals/data/datasources/local/daily_goals_local_dao_shared_prefs.dart`
- Remote datasource (Supabase): `lib/features/daily_goals/data/datasources/remote/supabase_daily_goals_remote_datasource.dart`
- Mapper: `lib/features/daily_goals/data/mappers/daily_goal_mapper.dart`
- Repository (impl): `lib/features/daily_goals/data/repositories/daily_goals_repository_impl.dart`
- Repository (interface): `lib/features/daily_goals/domain/repositories/daily_goals_repository.dart`
- UI (list): `lib/features/daily_goals/presentation/pages/daily_goals_list_screen.dart`
- UI (form): `lib/features/daily_goals/presentation/widgets/daily_goal_entity_form_dialog.dart`

Como verificar / onde está o padrão:
- Em `daily_goals_list_screen.dart` a tela instancia o `DailyGoalsRepositoryImpl`, chama `loadFromCache()` e, quando necessário, `syncFromServer()`.
- Em `daily_goals_repository_impl.dart` o `syncFromServer()` faz `upsertDailyGoals(localDtos)` no remote e depois `fetchDailyGoals()`, atualiza o cache local com `upsertAll` e atualiza `lastSync`.

---

### Maintenance Tasks (Manutenções)
- Domain entity: `lib/features/maintenance_tasks/domain/entities/maintenance_task_entity.dart`
- DTO: `lib/features/maintenance_tasks/data/dtos/maintenance_task_dto.dart`
- Local DAO (interface): `lib/features/maintenance_tasks/data/datasources/local/maintenance_tasks_local_dao.dart`
- Local DAO (SharedPreferences): `lib/features/maintenance_tasks/data/datasources/local/maintenance_tasks_local_dao_shared_prefs.dart`
- Remote datasource (Supabase): `lib/features/maintenance_tasks/data/datasources/remote/supabase_maintenance_tasks_remote_datasource.dart`
- Mapper: `lib/features/maintenance_tasks/data/mappers/maintenance_task_mapper.dart`
- Repository (impl): `lib/features/maintenance_tasks/data/repositories/maintenance_tasks_repository_impl.dart`
- Repository (interface): `lib/features/maintenance_tasks/domain/repositories/maintenance_tasks_repository.dart`
- UI (list): `lib/features/maintenance_tasks/presentation/pages/maintenance_tasks_list_page.dart`
- UI (form): `lib/features/maintenance_tasks/presentation/widgets/maintenance_task_form_dialog.dart`

Como verificar / onde está o padrão:
- A tela `maintenance_tasks_list_page.dart` cria o repo e chama `loadFromCache()` em `_initAndLoad()`; se cache vazio, chama `syncFromServer()`.
- O repositório (`maintenance_tasks_repository_impl.dart`) faz push local -> remote via `upsertMaintenanceTasks(localDtos)` e depois `fetchMaintenanceTasks()` (pull) aplicando `upsertAll` no DAO local.
- `delete` foi corrigido para apagar localmente imediatamente usando `_localDao.delete(id)` (assim a UI já reflete o delete) e tenta apagar remoto como tentativa de melhor esforço.

---

### Service Providers (Contatos Úteis)
- Domain entity: `lib/features/service_providers/domain/entities/service_provider_entity.dart`
- DTO: `lib/features/service_providers/data/dtos/service_provider_dto.dart`
- Local DAO (interface): `lib/features/service_providers/data/datasources/local/service_providers_local_dao.dart`
- Local DAO (SharedPreferences): `lib/features/service_providers/data/datasources/local/service_providers_local_dao_shared_prefs.dart`
- Remote datasource (Supabase): `lib/features/service_providers/data/datasources/remote/supabase_service_providers_remote_datasource.dart`
- Mapper: `lib/features/service_providers/data/mappers/service_provider_mapper.dart`
- Repository (impl): `lib/features/service_providers/data/repositories/service_providers_repository_impl.dart`
- Repository (interface): `lib/features/service_providers/domain/repositories/service_providers_repository.dart`
- UI (list): `lib/features/service_providers/presentation/pages/service_providers_list_screen.dart`
- UI (form): `lib/features/service_providers/presentation/widgets/service_provider_form_dialog.dart`

Como verificar / onde está o padrão:
- A tela de listagem cria a DAO local + remote datasource + mapper + repository e chama `listAll()` para carregar do cache; se cache estiver vazio o código chama `syncFromServer()`.
- `create/update` realizam `upsertServiceProviders([dto])` no remoto, executam `localDao.upsertAll([dto])` para atualização imediata de UI, e então chamam `syncFromServer()` para reconciliar.
- `delete` foi implementado com remoção no cache local (e tentativa de remoção remota como melhor esforço).

---

## Arquivos de infraestrutura (globais)
- `lib/main.dart` — Inicializa Supabase e `PrefsService.init()`, monta `ThemeController`, expõe `supabase` como cliente global para uso pelos repositórios/datasources.
- `lib/services/prefs_service.dart` — wrapper de SharedPreferences usado por todo o app (onboarding, theme mode, policy flags).

---

## Observações e recomendações
- O padrão já segue as orientações da atividade: UI consome Entities, não DTOs; todos os artefatos (mapper, repo, DTO, DAO) estão no projeto e a sincronização bidirecional foi implementada.
- Recomendações para futuras melhorias:
  - Centralizar a injeção de dependências (Provider / GetIt) para criar repositórios com menos repetição nas telas.
  - Adicionar `deleted_at` (soft delete) no Supabase para evitar inconsistências entre upserts e exclusões em sincronizações.
  - Adicionar testes unitários/integrados (mock Supabase client, SharedPreferences mock) cobrindo ciclo: loadFromCache -> create -> sync -> delete.

---

## Como ver logs (debug)
- Rode o app em modo debug para ver os `kDebugMode` `print` statements no console (vários pontos em datasources e repositories apresentam logs de eventos importantes).

---

Se quiser, posso:
- Gerar um arquivo `README.md` (ao invés de `README_PERSISTENCE.md`) com um sumário mais curto para exibição no repo;
- Adicionar testes básicos para demonstrar o comportamento de load/sync/delete em cada entidade;
- Documentar passo a passo como reproduzir um bug de sincronização/remoção.

Boa sorte com a apresentação; me diga se você prefere o README em inglês, ou deseja incluir screenshots e logs de exemplo.
