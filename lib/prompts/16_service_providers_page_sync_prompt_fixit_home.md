````markdown
# Prompt Operacional - ServiceProviders: Page Sync & UI Integration (FixIt Home)

> Use este prompt para aplicar o padrão "sync-on-empty-cache" e fornecer instruções para integrar o repositório à página de listagem de `service_providers`.

## Objetivo

Descrever as mudanças necessárias na tela de listagem para usar `ServiceProvidersRepository`:

- Carregar do cache local inicialmente via `loadFromCache()`;
- Se o cache estiver vazio, executar `syncFromServer()` e em seguida `listAll()`;
- Expor `RefreshIndicator` para forçar sync manual pelo usuário (pull-to-refresh);
- Substituir chamadas diretas ao Supabase pela API do repositório (create/update/delete).

## Passos de alteração na UI

1. Adicionar uma instância de `ServiceProvidersRepositoryImpl` na `State` da page (ou injetar via DI).
2. Implementar `_initAndLoad()` chamado em `initState()` que:
   - chama `await repo.loadFromCache()` e popula o estado;
   - se lista vazia, chama `await repo.syncFromServer()` e recarrega `repo.listAll()`;
3. Implementar `RefreshIndicator(onRefresh: () => repo.syncFromServer())` que atualiza o estado após a conclusão.
4. Atualizar ações de criação/edição/exclusão para usar `repo.create()/update()/delete()` e depois recarregar a lista.

## Boas práticas

- Verificar `mounted` antes de `setState` em callbacks assíncronos.
- Usar `kDebugMode` para logs de sucesso/erro curto.
- Manter a UI trabalhando apenas com `ServiceProviderEntity` (não DTOs).
- Mostrar `SnackBar` com mensagens de erro amigáveis em falhas.

## Exemplo reduzido (pseudocódigo)

```dart
void _initAndLoad() async {
  final cache = await repo.loadFromCache();
  setState(() => _providers = cache);
  if (cache.isEmpty) {
    await repo.syncFromServer();
    final fresh = await repo.listAll();
    if (mounted) setState(() => _providers = fresh);
  }
}
```

---

Checklist de validação
- [ ] A UI não usa DTOs diretamente
- [ ] Pull-to-refresh força `syncFromServer()` e atualiza a lista
- [ ] `flutter analyze` sem erros

````
