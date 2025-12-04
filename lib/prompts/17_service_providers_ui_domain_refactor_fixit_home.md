````markdown
# Prompt Operacional - ServiceProviders: UI ⇄ Domain Refactor (FixIt Home)

> Use este prompt para guiar a refatoração da UI de `service_providers` para trabalhar apenas com `ServiceProviderEntity` e consumir o `ServiceProvidersRepository`.

## Objetivo

Remover acoplamento direto da UI com Supabase/DTOs e garantir que a apresentação trabalhe com entidades e repositório:

- Introduzir `ServiceProvidersRepository` como fonte única de verdade para a tela;
- Garantir conversões apenas na camada de dados (Mapper/DTO);
- Simplificar callbacks da UI (`create/update/delete`) delegando para o repositório.

## Mudanças recomendadas

1. Remover imports de DTOs e `supabase` do arquivo da tela.
2. Adicionar import para `service_providers_repository_impl.dart` e `service_provider_entity.dart`.
3. Criar método `_initAndLoad()` (veja `16_service_providers_page_sync_prompt_fixit_home.md`).
4. Substituir funções que faziam `supabase.from(...).insert/update/delete` por `await repo.create(entity)` etc.
5. Tratar estados de loading e empty-state com `RefreshIndicator` e `CircularProgressIndicator`.

## Exemplo rápido

Antes:
```dart
await supabase.from('service_providers').insert(dto.toJson());
```

Depois:
```dart
await repo.create(entity);
await _loadData();
```

## Boas práticas
- Registrar/instanciar repositório via DI quando o projeto crescer.
- Manter validação/formatos de exibição (ex: `categoryLabel`, `rating`) dentro de widgets ou view models.

Checklist
- [ ] UI só manipula `ServiceProviderEntity`
- [ ] Sem imports de `supabase` na UI
- [ ] `flutter analyze` sem erros

````
