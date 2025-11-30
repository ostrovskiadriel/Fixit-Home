# 17 - Refatoração UI: Usar Entidades de Domínio em vez de DTOs (FixIt Home)

> **Este prompt orienta a refatoração das telas (presentation layer) do FixIt Home para usar exclusivamente entidades de domínio (`DailyGoalEntity`, `MaintenanceTaskEntity`) em vez de DTOs, mantendo o mapeamento DTO↔Entity concentrado na camada de persistência (DAO/Mapper).**

Visão Geral
-----------
Mudar a camada de apresentação para trabalhar com entidades de domínio em todo lugar, convertendo DTOs→Entity apenas na fronteira com o DAO (local ou remoto). Isso desacopla a UI de detalhes de persistência e centraliza a lógica de conversão.

Contexto do Projeto FixIt Home
-------------------------------
- **Entidades de domínio:**
  - `DailyGoalEntity` (com properties: id, userId, type, targetValue, currentValue, date, isCompleted)
  - `MaintenanceTaskEntity` (com properties: id, title, description, frequency, difficulty, lastPerformed, nextDueDate, isArchived)

- **DAOs e Mappers:**
  - `DailyGoalsLocalDaoSharedPrefs` / `MaintenanceTasksLocalDaoSharedPrefs` (implementam interfaces DAO)
  - `DailyGoalMapper` / `MaintenanceTaskMapper` (convertem DTO↔Entity)

- **Repositórios:**
  - `DailyGoalsRepositoryImpl` / `MaintenanceTasksRepositoryImpl` (orquestram local DAO + remote datasource + mapper)

- **Telas atuais:**
  - `daily_goals_list_screen.dart` (lista de metas diárias)
  - `maintenance_tasks_list_page.dart` (lista de tarefas de manutenção)

Padrão de Refatoração
---------------------

### 1. Estado da Tela (StatefulWidget)
Ao invés de manter `List<DailyGoalDto>` ou `List<MaintenanceTaskDto>`, usar direto as entidades:

```dart
class _DailyGoalsListScreenState extends State<DailyGoalsListScreen> {
  late DailyGoalsRepositoryImpl _repo;
  List<DailyGoalEntity> _goals = [];  // ← Usar Entity, não DTO
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    // Inicializa repositório
    final prefs = await SharedPreferences.getInstance();
    final localDao = DailyGoalsLocalDaoSharedPrefs(prefs: prefs);
    final remote = SupabaseDailyGoalsRemoteDatasource();
    final mapper = DailyGoalMapper();

    _repo = DailyGoalsRepositoryImpl(
      remoteDatasource: remote,
      localDao: localDao,
      mapper: mapper,
      prefsAsync: Future.value(prefs),
    );

    await _loadGoals();
  }

  Future<void> _loadGoals() async {
    // Carrega do repositório (que internamente usa DAO + Mapper)
    setState(() => _isLoading = true);
    try {
      final cached = await _repo.loadFromCache();
      if (cached.isEmpty) {
        try {
          await _repo.syncFromServer();
        } catch (e) {
          if (kDebugMode) print('Sync inicial falhou: $e');
        }
      }
      final entities = await _repo.listAll();  // ← Retorna Entity, não DTO
      if (mounted) setState(() { _goals = entities; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Exibir erro...
    }
  }

  // ✅ Comentário: Todos os itens em _goals são entities (DailyGoalEntity).
  // O mapeamento DTO→Entity acontece dentro do repository/mapper, não aqui.
}
```

### 2. Métodos de CRUD (Create, Read, Update, Delete)
Passar **entities** para o repositório, que as converte internamente para DTO e persiste:

```dart
Future<void> _onCreateGoal(DailyGoalEntity newGoal) async {
  try {
    // Repository.create() já espera Entity e faz a conversão para DTO internamente
    await _repo.create(newGoal);
    
    // Recarregar a lista
    await _loadGoals();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta criada com sucesso!')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  // ✅ Comentário: A conversão Entity→DTO é feita pelo repository.create()
  // Não fazer conversão aqui — manter a UI "limpa" de detalhes de persistência.
}

Future<void> _onEditGoal(DailyGoalEntity goal) async {
  final editedGoal = await showDailyGoalEntityFormDialog(context, initial: goal);
  if (editedGoal != null) {
    try {
      // Repository espera Entity, não DTO
      await _repo.update(editedGoal);
      await _loadGoals();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta atualizada!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    }
  }
}

Future<void> _onRemoveGoal(DailyGoalEntity goal) async {
  try {
    await _repo.delete(goal.id);
    await _loadGoals();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta removida.')));
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
  }
}
```

### 3. Widgets de Listagem
Aceitar e usar **entities** (não DTOs):

```dart
class _buildGoalList() {
  if (_goals.isEmpty) {
    return RefreshIndicator(
      onRefresh: () => _repo.syncFromServer().then((_) => _loadGoals()),
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: 300, child: Center(child: Text('Nenhuma meta encontrada.'))),
      ),
    );
  }

  return ListView.builder(
    itemCount: _goals.length,
    itemBuilder: (context, index) {
      final goal = _goals[index];  // ← Entity, não DTO
      
      return Card(
        child: ListTile(
          leading: Text(goal.type.icon, style: const TextStyle(fontSize: 24)),
          title: Text(goal.type.description),
          subtitle: Text('Progresso: ${goal.currentValue} / ${goal.targetValue}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDailyGoalDetailsDialog(
            context,
            goal: goal,  // ← Passa Entity
            onEdit: () => _onEditGoal(goal),
            onRemove: () => _onRemoveGoal(goal),
          ),
        ),
      );
    },
  );
}

// ✅ Comentário: O widget recebe DailyGoalEntity e usa seus properties diretamente.
// Não precisa fazer .toJson() ou conversões — tudo é domínio.
```

Checklist de Refatoração
------------------------

Para cada tela de listagem (ex.: `daily_goals_list_screen.dart`, `maintenance_tasks_list_page.dart`):

- [ ] **Estado:** Mudar `List<Dto>` → `List<Entity>` (ex.: `List<DailyGoalDto>` → `List<DailyGoalEntity>`)
- [ ] **initState:** Inicializar Repository com DAO + Remote + Mapper
- [ ] **_loadItems():** Usar `repo.loadFromCache()` → se vazio, `repo.syncFromServer()` → `repo.listAll()`
- [ ] **Widgets:** Aceitar e usar `Entity` diretamente (acessar `.type`, `.frequency`, etc. sem conversão)
- [ ] **CRUD:** Passar `Entity` para `repo.create()/update()/delete()`
- [ ] **Imports:** Remover imports de DTO; manter apenas Entity, Repository, Mapper
- [ ] **Comentários:** Adicionar notas explicativas sobre a separação de camadas

Boas Práticas
-----------

### Conversão Centralizada
```dart
// ✅ CERTO: Mapeamento só no Mapper/DAO, entre persistência e domínio
final dtos = await dao.getAll();
final entities = mapper.dtoListToEntityList(dtos);  // ← Centralizado

// ❌ ERRADO: Mapeamento espalhado na UI
final entities = dtos.map((d) => DailyGoalEntity(...)).toList();  // ← Evitar!
```

### Verificar `mounted` antes de `setState`
```dart
if (mounted) {
  setState(() {
    _goals = entities;
    _isLoading = false;
  });
}
```

### Logs com `kDebugMode`
```dart
if (kDebugMode) {
  print('DailyGoalsListScreen._loadGoals: carregadas ${entities.length} metas do repositório');
}
```

### Tratar Erros Gracefully
```dart
try {
  await _repo.syncFromServer();
} catch (e) {
  if (kDebugMode) print('Erro ao sincronizar: $e');
  // Não bloquear UI — mostrar snackbar de erro e deixar usuário tentar novamente
}
```

Referências do Projeto
---------------------
- **Entidades:** `lib/features/daily_goals/domain/entities/daily_goal_entity.dart`
- **DAOs:** `lib/features/daily_goals/data/datasources/local/daily_goals_local_dao_shared_prefs.dart`
- **Mappers:** `lib/features/daily_goals/data/mappers/daily_goal_mapper.dart`
- **Repositórios:** `lib/features/daily_goals/data/repositories/daily_goals_repository_impl.dart`
- **Telas:** `lib/features/daily_goals/presentation/pages/daily_goals_list_screen.dart`

Validação (após refatoração)
-----------------------------

1. **Rode static analysis:**
   ```bash
   flutter analyze
   ```
   Deve resultar em: "No issues found!"

2. **Verifique testes (se houver):**
   - Mappers funcionam corretamente (DTO↔Entity)
   - Repository métodos retornam entities
   - UI recebe e trabalha com entities

3. **Teste a App:**
   - Tela lista metas/tarefas carregando do cache
   - Pull-to-refresh sincroniza com Supabase
   - Criar/editar/remover funciona e recarrega lista
   - Logs aparecem no console (com kDebugMode)

Exemplos de Logs Esperados
--------------------------
```
I/flutter: DailyGoalsListScreen._initAndLoad: inicializando repositório...
I/flutter: DailyGoalsRepositoryImpl.loadFromCache: carregadas 3 metas do cache
I/flutter: Cache vazio ou update necessário — sincronizando...
I/flutter: DailyGoalsRepositoryImpl.syncFromServer: aplicadas 2 mudanças
I/flutter: DailyGoalsListScreen._loadGoals: atualizadas 5 metas na UI
```

Checklist de Erros Comuns
--------------------------
- [ ] **DTOs aparecem na UI state:** Verificar se todos os `List<Dto>` foram convertidos para `List<Entity>`
- [ ] **Mapeamento espalhado:** Procurar por `.toEntity()` / `.toDto()` fora de Mapper e DAO
- [ ] **Não converter ao persistir:** Garantir que repository.create/update/delete aceitam Entity
- [ ] **setState sem mounted:** Todos os `setState` devem estar dentro de `if (mounted) { ... }`
- [ ] **Falta RefreshIndicator em lista vazia:** Lista vazia deve permitir pull-to-refresh
- [ ] **Imports de DTO na UI:** Remover `import '...dtos/...dto.dart'` das telas

Notas Finais
-----------
- Esta refatoração melhora a testabilidade: testes de UI podem injetar repositórios mock que retornam entities.
- Facilita evolução: mudar a forma como dados são persistidos (DAO, DB schema) sem tocar na UI.
- Dica: Se a app crescer e precisar de DI/Provider, este padrão facilita muito — os repositórios ficam prontos para serem injetados.

---
**Próximos passos recomendados:**
- [ ] Aplicar refatoração em `daily_goals_list_screen.dart` (já feita?)
- [ ] Aplicar refatoração em `maintenance_tasks_list_page.dart` (já feita?)
- [ ] Verificar se há outras telas que precisam da mesma refatoração
- [ ] Considerar adicionar Provider/GetIt para DI central (prompts futuros)
