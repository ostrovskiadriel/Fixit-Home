# Prompt Operacional Adaptado - FixIt Home

> **Este prompt foi adaptado para o projeto FixIt Home. Use-o para gerar interfaces de repositório para novas entidades.**

## Objetivo

Gerar um arquivo Dart contendo **apenas a interface (classe abstrata)** de um repositório para uma entidade do domínio do FixIt Home, de forma parametrizada e didática.

## Contexto do FixIt Home

Seu projeto segue Clean Architecture com as camadas:
- **Domain**: Entidades e interfaces de repositório
- **Data**: DTOs, DAOs e implementações de repositório
- **Presentation**: Widgets e gerenciamento de estado

### Estrutura padrão do projeto:
```
lib/features/
  └── <feature>/
      ├── domain/
      │   ├── entities/          # Entidades de domínio (regras de negócio)
      │   └── repositories/      # Interfaces de repositório
      ├── data/
      │   ├── dtos/              # Data Transfer Objects
      │   ├── datasources/       # Interfaces de fonte de dados
      │   └── repositories/      # Implementações de repositório
      └── presentation/
          └── ...                # UI e estado
```

## Parâmetros (Substituir antes de executar)

- **SUFFIX**: sufixo do repositório (ex.: `DailyGoals`). Forma: `<SUFFIX>Repository`
- **ENTITY**: nome da entidade/model (ex.: `DailyGoalEntity`) — usado nos tipos de retorno
- **ENTITY_SIMPLE**: nome simplificado em camelCase minúsculo (ex.: `dailyGoal`)
- **DEST_DIR**: diretório destino: `lib/features/<ENTITY_SIMPLE>/domain/repositories/`

## Investigação da Entidade (Obrigatória)

Antes de gerar:
1. Localize a entidade em `lib/features/<ENTITY_SIMPLE>/domain/entities/`
2. Confirme o nome exato da classe (ex.: `DailyGoalEntity`)
3. Verifique os tipos de propriedades-chave (ex.: `id: String`, `date: DateTime`)
4. Analise métodos auxiliares (ex.: `copyWith`, `toMap`, `fromMap`)

**Entidade encontrada no projeto:**
- ✅ `DailyGoalEntity` em `lib/features/daily_goals/domain/entities/daily_goal_entity.dart`
  - ID: `String`
  - Propriedades principais: `userId`, `type` (enum GoalType), `targetValue`, `currentValue`, `date`, `isCompleted`
  - Possui: `copyWith()`, `progress`, `isAchieved`, `remaining`, `isToday`

## Assinaturas Exatas que Devem Constar na Interface

Para o FixIt Home, adapte conforme a entidade:

### Básicas (sempre incluir):
- `Future<List<ENTITY>> loadFromCache();` — Render inicial rápido
- `Future<int> syncFromServer();` — Sincronização incremental. Retorna quantidade de mudanças
- `Future<List<ENTITY>> listAll();` — Listagem completa do cache
- `Future<List<ENTITY>> listFeatured();` — Destaques (filter por `featured`)
- `Future<ENTITY?> getById(String id);` — Busca por ID (String para FixIt Home)

### Adicionais (conforme necessidade):
- `Future<bool> save(ENTITY goal);` — Salvar/atualizar no cache
- `Future<bool> delete(String id);` — Deletar do cache
- `Future<List<ENTITY>> filterByUserId(String userId);` — Filtrar por usuário
- `Future<List<ENTITY>> filterByDate(DateTime date);` — Filtrar por data

## Regras e Restrições

1. **Arquivo de saída**: `lib/features/<entity_simple>/domain/repositories/<entity_simple>_repository.dart`
2. **Conteúdo**: Somente import da entidade + classe abstrata `<SUFFIX>Repository`
3. **Docstrings**: Cada método com `///` explicando o propósito em português
4. **Comentários**: Acima de cada método, detalhe o uso e boas práticas
5. **Sem implementações**: Apenas assinaturas de métodos
6. **Comentário introdutório**: Explicar o papel do repositório na arquitetura
7. **Bloco de uso ao final**: Exemplo de implementação e checklist de erros comuns

## Instruções de Geração

1. Use o template abaixo como referência
2. Substitua `<SUFFIX>`, `<ENTITY>` e `<entity_simple>` pelos valores corretos
3. Adapte as assinaturas conforme as características da entidade
4. Adicione métodos específicos do domínio se necessário
5. Verifique se o arquivo foi criado e não possui duplicatas

## Template de Saída Esperada

```dart
/// Interface de repositório para a entidade <ENTITY>.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.

import '../entities/<entity_simple>_entity.dart';

abstract class <SUFFIX>Repository {
  /// Descreve o método em português.
  ///
  /// Detalhes sobre quando usar, boas práticas, etc.
  Future<List<ENTITY>> loadFromCache();

  /// ... outros métodos ...
}

/*
// Exemplo de uso:
...
*/
```

## Checklist Pós-Geração

- [ ] Arquivo criado em `lib/features/<entity_simple>/domain/repositories/<entity_simple>_repository.dart`
- [ ] Contém único import para entidade e declaração `abstract class <SUFFIX>Repository`
- [ ] Todas as assinaturas e docstrings em português
- [ ] Sem implementações adicionais ou imports desnecessários
- [ ] Exemplo de uso ao final comentado
- [ ] Sem duplicatas ou conflitos com arquivos existentes

## Exemplo Específico: DailyGoalsRepository

**Parâmetros:**
- SUFFIX: `DailyGoals`
- ENTITY: `DailyGoalEntity`
- entity_simple: `dailyGoal`
- DEST_DIR: `lib/features/daily_goals/domain/repositories/`

**Arquivo gerado:**
✅ Arquivo criado: `lib/features/daily_goals/domain/repositories/daily_goals_repository.dart`

## Próximas Entidades a Gerar (Sugestões)

Com base na estrutura do FixIt Home, considere criar repositórios para:
1. **UserProfile** — Perfil do usuário
2. **MaintenanceTask** — Tarefas de manutenção
3. **Checklist** — Checklists de reparos
4. **Notification** — Notificações e lembretes

## Notas Finais

- Use este prompt para manter consistência ao adicionar novas entidades
- Sempre crie a interface antes de implementar
- Reutilize padrões já estabelecidos no projeto
- Para implementações, consulte `01_repository_local_dao_prompt.md` ou similar
