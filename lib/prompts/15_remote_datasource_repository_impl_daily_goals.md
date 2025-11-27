# Prompt Operacional Adaptado - DailyGoals Remote Datasource + Repository Impl

> **Este prompt foi adaptado para o projeto FixIt Home. Use-o para gerar implementações concretas do repositório com Supabase.**

## Objetivo

Gerar dois arquivos Dart para a feature **DailyGoals**:
1. **Remote Datasource** — Acessa a tabela `daily_goals` no Supabase
2. **Repository Impl** — Combina cache local (SharedPreferences/DAO) com dados remotos

---

## Parâmetros Adaptados para FixIt Home

### Variáveis
- **ENTITY**: `DailyGoalEntity`
- **ENTITY_PLURAL**: `daily_goals`
- **TABLE_NAME**: `daily_goals` (tabela Supabase)
- **ENTITY_PASCAL**: `DailyGoal`

### Diretórios
```
lib/features/daily_goals/
├── domain/
│   ├── entities/
│   │   └── daily_goal_entity.dart
│   └── repositories/
│       └── daily_goals_repository.dart         ✅ (já criado)
├── data/
│   ├── dtos/
│   │   └── daily_goal_dto.dart
│   ├── datasources/
│   │   ├── remote/
│   │   │   └── supabase_daily_goals_remote_datasource.dart    ✨ NOVO
│   │   └── local/
│   │       └── daily_goals_local_dao.dart
│   └── repositories/
│       └── daily_goals_repository_impl.dart                   ✨ NOVO
└── presentation/
    └── ...
```

---

## Estrutura da Tabela Supabase

A tabela `daily_goals` deve ter as colunas:
```sql
id                TEXT PRIMARY KEY
user_id           TEXT NOT NULL
type              TEXT NOT NULL (enum: moodEntries, positiveEntries, reflection, gratitude)
target_value      INTEGER NOT NULL
current_value     INTEGER NOT NULL
date              TIMESTAMP NOT NULL
is_completed      BOOLEAN NOT NULL DEFAULT FALSE
updated_at        TIMESTAMP NOT NULL DEFAULT NOW()
created_at        TIMESTAMP NOT NULL DEFAULT NOW()
```

---

## Investigação Obrigatória

Antes de gerar, verifique:

✅ **Entidade**: `DailyGoalEntity` em `lib/features/daily_goals/domain/entities/daily_goal_entity.dart`
- Propriedades: `id` (String), `userId`, `type` (GoalType enum), `targetValue`, `currentValue`, `date` (DateTime), `isCompleted`

✅ **Interface do Repositório**: `DailyGoalsRepository` em `lib/features/daily_goals/domain/repositories/daily_goals_repository.dart`
- Métodos: `loadFromCache()`, `syncFromServer()`, `listAll()`, `listFeatured()`, `getById()`, `save()`, `delete()`

✅ **DTO**: `DailyGoalDto` em `lib/features/daily_goals/data/dtos/daily_goal_dto.dart`
- Métodos: `fromJson()`, `toJson()`

⚠️ **Mapper** (pode ser necessário criar):
- Converte `DailyGoalDto` → `DailyGoalEntity`
- Converte `DailyGoalEntity` → `DailyGoalDto`

⚠️ **DAO Local** (pode ser necessário criar):
- Interface: `DailyGoalsLocalDao`
- Implementação: `DailyGoalsLocalDaoSharedPrefs` (usando SharedPreferences)
- Métodos: `upsertAll()`, `getAll()`, `getById()`, `delete()`, `clear()`

---

## Arquivo 1: Supabase Remote Datasource

**Localização**: `lib/features/daily_goals/data/datasources/remote/supabase_daily_goals_remote_datasource.dart`

**Classe**: `SupabaseDailyGoalsRemoteDatasource`

### Responsabilidades:
1. Conectar ao Supabase via `SupabaseClient`
2. Implementar interface remota (se existir) ou método `fetchDailyGoals()`
3. Filtrar por `updated_at >= since` (se informado)
4. Ordenar por `updated_at DESC`
5. Mapear rows para `DailyGoalDto`
6. Retornar página com `next` cursor se há mais dados
7. Tratar erros gracefully (retornar página vazia)
8. Adicionar logs com `kDebugMode` para diagnóstico

### Método Principal:
```dart
Future<RemotePage<DailyGoalDto>> fetchDailyGoals({
  DateTime? since,
  int limit = 500,
  PageCursor? cursor,
}) async {
  // Implementação aqui
}
```

### Dicas Práticas:
- ⚠️ O DTO deve aceitar `type` como String (vindo do Supabase) e converter para enum GoalType
- ⚠️ Datas vêm como ISO8601 String do Supabase — parse com segurança
- ⚠️ Sempre log com `kDebugMode` o número de registros recebidos
- ⚠️ Envolva conversões em try/catch
- ⚠️ Não exponha secrets em logs

---

## Arquivo 2: Repository Impl

**Localização**: `lib/features/daily_goals/data/repositories/daily_goals_repository_impl.dart`

**Classe**: `DailyGoalsRepositoryImpl implements DailyGoalsRepository`

### Responsabilidades:
1. Receber `SupabaseDailyGoalsRemoteDatasource` e `DailyGoalsLocalDao` no construtor
2. Gerenciar sincronização incremental via `syncFromServer()`
3. Carregar do cache com `loadFromCache()`
4. Listar metas em destaque com `listFeatured()`
5. Buscar por ID com `getById()`
6. Salvar/deletar via DAO
7. Usar mapper para converter DTO ↔ Entidade
8. Manter chave `daily_goals_last_sync_vX` no SharedPreferences

### Método Principal - syncFromServer():
```dart
@override
Future<int> syncFromServer() async {
  final prefs = await SharedPreferences.getInstance();
  final lastSyncIso = prefs.getString(_lastSyncKey);
  
  DateTime? since;
  if (lastSyncIso != null && lastSyncIso.isNotEmpty) {
    try {
      since = DateTime.parse(lastSyncIso);
    } catch (_) {
      // Log e continue
    }
  }
  
  // Fetch de remote
  final page = await _remoteDatasource.fetchDailyGoals(since: since, limit: 500);
  if (page.items.isEmpty) return 0;
  
  // Upsert no cache local
  await _localDao.upsertAll(page.items.map((dto) => _mapper.dtoToEntity(dto)).toList());
  
  // Atualizar marcador de sync
  final newest = _computeNewest(page.items);
  await prefs.setString(_lastSyncKey, newest.toIso8601String());
  
  if (kDebugMode) {
    print('DailyGoalsRepositoryImpl.syncFromServer: aplicados ${page.items.length} registros');
  }
  
  return page.items.length;
}
```

### Dicas Práticas:
- ⚠️ Sempre verifique se widget está `mounted` antes de setState
- ⚠️ Use mapper para converter DTO → Entidade
- ⚠️ Trate parsing de datas com segurança
- ⚠️ Log com `kDebugMode` para diagnóstico de problemas
- ⚠️ Use chave de sync com versão (`_vX`) para permitir cache-busting

---

## Interfaces Esperadas

### Remote API (se necessário):
```dart
abstract class DailyGoalsRemoteApi {
  Future<RemotePage<DailyGoalDto>> fetchDailyGoals({
    DateTime? since,
    int limit,
    PageCursor? cursor,
  });
}
```

### DAO Local:
```dart
abstract class DailyGoalsLocalDao {
  Future<List<DailyGoalDto>> getAll();
  Future<void> upsertAll(List<DailyGoalEntity> entities);
  Future<DailyGoalDto?> getById(String id);
  Future<void> delete(String id);
  Future<void> clear();
}
```

### Mapper:
```dart
class DailyGoalMapper {
  DailyGoalEntity dtoToEntity(DailyGoalDto dto) { ... }
  DailyGoalDto entityToDto(DailyGoalEntity entity) { ... }
}
```

---

## Checklist Pré-Geração

- [ ] DTO `DailyGoalDto` existe e tem `fromJson()`, `toJson()`
- [ ] Mapper `DailyGoalMapper` existe ou será criado
- [ ] DAO `DailyGoalsLocalDao` existe ou será criado
- [ ] Supabase inicializado em `main.dart`
- [ ] Tabela `daily_goals` criada no Supabase
- [ ] RLS policies configuradas (se necessário)

---

## Checklist Pós-Geração

- [ ] `supabase_daily_goals_remote_datasource.dart` criado
- [ ] `daily_goals_repository_impl.dart` criado
- [ ] Nenhum import circular
- [ ] Sem secrets em logs
- [ ] Logs com `kDebugMode` em pontos críticos
- [ ] Tratamento de erro com try/catch
- [ ] `flutter analyze` retorna "No issues found!"
- [ ] Sem duplicatas de classe
- [ ] Exemplo de uso comentado ao final de cada arquivo

---

## Exemplo de Uso

```dart
// Inicializar
final remoteDatasource = SupabaseDailyGoalsRemoteDatasource();
final localDao = DailyGoalsLocalDaoSharedPrefs();
final mapper = DailyGoalMapper();
final repo = DailyGoalsRepositoryImpl(
  remoteDatasource: remoteDatasource,
  localDao: localDao,
  mapper: mapper,
);

// Sincronizar e listar
await repo.syncFromServer();
final metas = await repo.listAll();
```

---

## Próximos Passos

1. **Gerar Remote Datasource** — Implementar `SupabaseDailyGoalsRemoteDatasource`
2. **Gerar Repository Impl** — Implementar `DailyGoalsRepositoryImpl`
3. **Criar DAO Local** — Se não existir (com SharedPreferences ou SQLite)
4. **Criar Mapper** — Converter entre DTO e Entidade
5. **Testes** — Unit tests para sync, cache e conversão
6. **Integração** — Conectar na UI com providers/riverpod

---

## Referências

- [Supabase Flutter](https://supabase.com/docs/reference/flutter/introduction)
- `lib/features/daily_goals/domain/entities/daily_goal_entity.dart` (entidade)
- `lib/features/daily_goals/domain/repositories/daily_goals_repository.dart` (interface)
- `lib/features/daily_goals/data/dtos/daily_goal_dto.dart` (DTO)
- `lib/services/supabase_service.dart` (inicialização Supabase)
