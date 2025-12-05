// lib/features/service_providers/presentation/pages/service_providers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/service_provider_entity.dart';
import '../../data/repositories/service_providers_repository_impl.dart';
import '../../data/datasources/local/service_providers_local_dao_shared_prefs.dart';
import '../../data/datasources/remote/supabase_service_providers_remote_datasource.dart';
import '../../data/mappers/service_provider_mapper.dart';
import '../widgets/service_provider_form_dialog.dart';

class ServiceProvidersListScreen extends StatefulWidget {
  const ServiceProvidersListScreen({super.key});

  @override
  State<ServiceProvidersListScreen> createState() => _ServiceProvidersListScreenState();
}

class _ServiceProvidersListScreenState extends State<ServiceProvidersListScreen> {
  late ServiceProvidersRepositoryImpl _repository;
  bool _isLoading = true;
  List<ServiceProviderEntity> _providers = [];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final localDao = ServiceProvidersLocalDaoSharedPrefs(prefs: prefs);
      final remote = SupabaseServiceProvidersRemoteDatasource();
      final mapper = ServiceProviderMapper();
      _repository = ServiceProvidersRepositoryImpl(
        remote: remote,
        localDao: localDao,
        mapper: mapper,
        prefsAsync: Future.value(prefs),
      );

      final cache = await _repository.listAll();
      setState(() {
        _providers = cache;
        _isLoading = false;
      });

      if (cache.isEmpty) {
        await _repository.syncFromServer();
        final fresh = await _repository.listAll();
        if (mounted) setState(() => _providers = fresh);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.listAll();
      if (mounted) {
        setState(() {
          _providers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addProvider() async {
    final newEntity = await showServiceProviderFormDialog(context);
    if (newEntity != null) {
      try {
        await _repository.create(newEntity);
        await _loadData();
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _editProvider(ServiceProviderEntity entity) async {
    final edited = await showServiceProviderFormDialog(context, initial: entity);
    if (edited != null) {
      try {
        await _repository.update(edited);
        await _loadData();
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _deleteProvider(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir'),
        content: const Text('Tem certeza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sim', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.delete(id);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prestadores de Serviço')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProvider,
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _repository.syncFromServer();
                await _loadData();
              },
              child: _providers.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: 300, child: Center(child: Text('Nenhum prestador cadastrado.'))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _providers.length,
                      itemBuilder: (ctx, index) {
                        final p = _providers[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              child: Text(p.categoryIcon),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${p.categoryLabel} • ${p.phoneNumber}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (p.isFavorite) const Icon(Icons.favorite, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                Text(p.rating.toStringAsFixed(1)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteProvider(p.id),
                                  tooltip: 'Remover contato',
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            onTap: () => _editProvider(p),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}