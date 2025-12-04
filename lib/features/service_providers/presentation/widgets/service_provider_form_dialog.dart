// lib/features/service_providers/presentation/widgets/service_provider_form_dialog.dart

import 'package:flutter/material.dart';
import '../../domain/entities/service_provider_entity.dart';

Future<ServiceProviderEntity?> showServiceProviderFormDialog(
  BuildContext context, {
  ServiceProviderEntity? initial,
}) {
  return showDialog<ServiceProviderEntity>(
    context: context,
    builder: (ctx) => _ServiceProviderFormDialog(initial: initial),
  );
}

class _ServiceProviderFormDialog extends StatefulWidget {
  final ServiceProviderEntity? initial;
  const _ServiceProviderFormDialog({this.initial});

  @override
  State<_ServiceProviderFormDialog> createState() => _ServiceProviderFormDialogState();
}

class _ServiceProviderFormDialogState extends State<_ServiceProviderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late ServiceCategory _category;
  double _rating = 0.0;
  bool _isFavorite = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    
    _nameController = TextEditingController(text: initial?.name ?? '');
    _phoneController = TextEditingController(text: initial?.phoneNumber ?? '');
    _category = initial?.category ?? ServiceCategory.general;
    _rating = initial?.rating ?? 5.0;
    _isFavorite = initial?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_formKey.currentState!.validate()) {
      final entity = ServiceProviderEntity(
        id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        category: _category,
        rating: _rating,
        isFavorite: _isFavorite,
      );
      Navigator.pop(context, entity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar Prestador' : 'Novo Prestador'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.length < 3 ? 'Nome muito curto' : null,
              ),
              const SizedBox(height: 12),

              // Telefone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // Categoria (Dropdown)
              DropdownButtonFormField<ServiceCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
                items: ServiceCategory.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(children: [Text(c.icon), const SizedBox(width: 8), Text(c.label)]),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              // Avaliação (Slider)
              Row(
                children: [
                  const Text('Avaliação: '),
                  Text(_rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
              Slider(
                value: _rating,
                min: 0,
                max: 5,
                divisions: 10,
                label: _rating.toString(),
                onChanged: (v) => setState(() => _rating = v),
              ),

              // Favorito
              SwitchListTile(
                title: const Text('Favorito?'),
                value: _isFavorite,
                onChanged: (v) => setState(() => _isFavorite = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _onConfirm, child: const Text('Salvar')),
      ],
    );
  }
}