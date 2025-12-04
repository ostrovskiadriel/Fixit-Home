import 'package:flutter/foundation.dart';
import 'package:fixit_home/main.dart' show supabase;
import '../../dtos/service_provider_dto.dart';

class RemotePage<T> {
  final List<T> items;
  final dynamic next;
  RemotePage({required this.items, this.next});
}

class SupabaseServiceProvidersRemoteDatasource {
  final dynamic _client;
  SupabaseServiceProvidersRemoteDatasource({dynamic client}) : _client = client ?? supabase;

  Future<RemotePage<ServiceProviderDto>> fetchServiceProviders({
    DateTime? since,
    int limit = 500,
    dynamic cursor,
  }) async {
    try {
      final query = _client.from('service_providers').select().order('updated_at', ascending: false);

      if (since != null) {
        query.gte('updated_at', since.toUtc().toIso8601String());
      }

      final rows = await query.limit(limit);

      if (rows == null) return RemotePage(items: []);

      final dtos = (rows as List).map((e) => ServiceProviderDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      if (kDebugMode) print('SupabaseServiceProvidersRemoteDatasource.fetchServiceProviders: recebidos ${dtos.length} registros');

      return RemotePage(items: dtos, next: null);
    } catch (e) {
      if (kDebugMode) print('SupabaseServiceProvidersRemoteDatasource.fetchServiceProviders: erro - $e');
      return RemotePage(items: []);
    }
  }

  /// Upsert em lote — insere ou atualiza registros no Supabase.
  /// Retorna o número de registros afetados (quando possível).
  Future<int> upsertServiceProviders(List<ServiceProviderDto> dtos) async {
    try {
      if (dtos.isEmpty) return 0;
      final payload = dtos.map((d) => d.toJson()).toList();
      await _client.from('service_providers').upsert(payload);
      if (kDebugMode) print('SupabaseServiceProvidersRemoteDatasource.upsertServiceProviders: enviado ${dtos.length} registros');
      return dtos.length;
    } catch (e) {
      if (kDebugMode) print('SupabaseServiceProvidersRemoteDatasource.upsertServiceProviders: erro - $e');
      return 0;
    }
  }

  /// Delete by id on remote (best-effort)
  Future<bool> deleteServiceProvider(String id) async {
    try {
      await _client.from('service_providers').delete().eq('id', id);
      if (kDebugMode) print('SupabaseServiceProvidersRemoteDatasource.deleteServiceProvider: $id deletado');
      return true;
    } catch (e) {
      if (kDebugMode) print('SupabaseServiceProvidersRemoteDatasource.deleteServiceProvider: erro - $e');
      return false;
    }
  }
}
