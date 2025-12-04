````markdown
# Prompt Operacional - ServiceProviders: Two-Way Sync (push then pull)

> Use este prompt para gerar instruções e código exemplo que implementa duas vias de sincronização (push local → remote, depois pull incremental) para `service_providers`.

## Objetivo

Implementar um fluxo de sincronização robusto em `ServiceProvidersRepositoryImpl` que:

- Primeiro envia (push) alterações locais para o Supabase (upsert em lote);
- Depois puxa (pull) mudanças remotas incrementais desde `lastSync` e aplica ao cache local;
- Atualiza `lastSync` com o `updated_at` mais recente aplicado;
- Trata conflitos de forma simples (último gravado vence) e loga problemas para análise.

## Requisitos mínimos

1. `upsertServiceProviders(List<ServiceProviderDto> dtos)` no datasource remoto;
2. `syncFromServer()` no repositório deve:
   - Tentar `push` das mudanças locais (se houver) e logar falhas sem bloquear o `pull`;
   - Efetuar `pull` chamando `remote.fetchServiceProviders(since: lastSync)`;
   - Aplicar `upsertAll` no DAO local com os DTOs retornados convertidos via mapper;
   - Atualizar `lastSync` com o `updated_at` mais recente ou `DateTime.now().toUtc()` em fallback.

## Tratamento de erros e logs

- Push deve ser "best-effort": capture exceções e registre com `kDebugMode`, mas prossiga com o pull.
- Em caso de erro de parsing de datas, ignore o registro problemático e continue processando os demais.
- Log esperado:
  - `ServiceProvidersRepositoryImpl.pushLocalChanges: enviado 3 registros`;
  - `ServiceProvidersRepositoryImpl.syncFromServer: aplicados 5 registros`.

## Exemplo simplificado (pseudocódigo)

```dart
Future<int> syncFromServer() async {
  // 1 — push local
  try {
    final local = await _localDao.getAll();
    final dtos = local.map(mapper.entityToDto).toList();
    if (dtos.isNotEmpty) await _remote.upsertServiceProviders(dtos);
  } catch (e) {
    if (kDebugMode) print('push falhou: $e');
  }

  // 2 — pull incremental
  final page = await _remote.fetchServiceProviders(since: _readLastSync());
  if (page.items.isEmpty) return 0;
  await _localDao.upsertAll(page.items.map(mapper.dtoToEntity).toList());
  _writeLastSync(_computeNewest(page.items));
  return page.items.length;
}
```

Checklist
- [ ] Implementar `upsertServiceProviders` no remote datasource
- [ ] Garantir chaves `_lastSyncKey` com versão
- [ ] Logs com `kDebugMode` nas etapas push/pull
- [ ] `flutter analyze` sem erros após implementação

````
