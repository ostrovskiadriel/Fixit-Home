````markdown
# Prompt Operacional Adaptado - ServiceProviders Remote Datasource + Repository Impl

> **Adaptado para o projeto FixIt Home. Use este prompt para gerar as implementações concretas do datasource remoto (Supabase) e do repository impl para `service_providers`.**

## Objetivo

Gerar dois arquivos Dart para a feature **ServiceProviders**:
1. **Remote Datasource** — acessa a tabela `service_providers` no Supabase
2. **Repository Impl** — combina cache local (SharedPreferences/DAO) com dados remotos

---

## Parâmetros adaptados

- **ENTITY**: `ServiceProviderEntity`
- **ENTITY_PLURAL**: `service_providers`
- **TABLE_NAME**: `service_providers`
- **ENTITY_PASCAL**: `ServiceProvider`

### Estrutura sugerida de diretórios
```
lib/features/service_providers/
├── domain/
│   ├── entities/
│   │   └── service_provider_entity.dart
│   └── repositories/
│       └── service_providers_repository.dart
├── data/
│   ├── dtos/
│   │   └── service_provider_dto.dart
│   ├── datasources/
│   │   └── remote/
│   │       └── supabase_service_providers_remote_datasource.dart  ✨ NOVO
│   └── repositories/
│       └── service_providers_repository_impl.dart                ✨ NOVO
└── presentation/
    └── ...
```

---

## Recomendações e investigação obrigatória

- Verificar se `ServiceProviderEntity` existe e quais campos estão definidos.
- Confirmar se existe DTO `ServiceProviderDto` com `fromJson`/`toJson`.
- Verificar se há um mapper para conversões DTO ↔ Entity (criar se necessário).
- Identificar colunas críticas na tabela Supabase (`id`, `updated_at`, `created_at`, `name`, etc.).

---

## Arquivo 1: Supabase Remote Datasource

**Localização sugerida:** `lib/features/service_providers/data/datasources/remote/supabase_service_providers_remote_datasource.dart`

**Classe:** `SupabaseServiceProvidersRemoteDatasource`

Responsabilidades principais:
- Conectar ao `SupabaseClient` (construtor recebe `SupabaseClient? client` com fallback ao client global).
- Implementar `fetchServiceProviders({DateTime? since, int limit = 500, PageCursor? cursor})` filtrando por `updated_at >= since` quando informado.
- Ordenar por `updated_at DESC` e mapear linhas para `ServiceProviderDto`.
- Retornar um `RemotePage<ServiceProviderDto>` contendo `items` e possivelmente `next` quando houver paginação.
- Tratar erros com try/catch e retornar página vazia em falhas não fatais.
- Logar eventos críticos com `kDebugMode` (número de registros, erros de parsing).

Dicas práticas:
- Datas podem vir como String — parse com try/catch.
- Campos podem variar (id int/string) — adapte `fromJson` do DTO para tolerância.
- Nunca logue secrets.

---

## Arquivo 2: Repository Impl

**Localização sugerida:** `lib/features/service_providers/data/repositories/service_providers_repository_impl.dart`

**Classe:** `ServiceProvidersRepositoryImpl implements ServiceProvidersRepository`

Responsabilidades principais:
- Receber `SupabaseServiceProvidersRemoteDatasource` e `ServiceProvidersLocalDao` (SharedPrefs) e `ServiceProviderMapper` no construtor.
- Implementar `syncFromServer()` com fluxo incremental:
  - Ler `_lastSyncKey` do `SharedPreferences`.
  - Chamar `remote.fetchServiceProviders(since: lastSync)`.
  - `upsertAll` no DAO local via mapper.
  - Atualizar `_lastSyncKey` com o `updated_at` mais recente (ou UTC now em fallback).
  - Retornar quantidade de itens aplicados.
- Métodos CRUD (`listAll`, `create`, `update`, `delete`) devem usar mapper/DAO e, quando apropriado, chamar sync parcial ou total.
- Adicionar logs `kDebugMode` em pontos de falha/êxito.

Checklist pós-geração:
- [ ] DTO e Mapper tratados corretamente
- [ ] DAO local com `upsertAll/getAll/getById/delete/clear`
- [ ] `flutter analyze` sem erros

---

Incluir ao final de cada arquivo um bloco de comentário com exemplo de uso, checklist e logs esperados.

````
