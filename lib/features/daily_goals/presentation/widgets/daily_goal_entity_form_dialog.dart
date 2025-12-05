// lib/features/daily_goals/presentation/widgets/daily_goal_entity_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/daily_goal_entity.dart';

Future<DailyGoalEntity?> showDailyGoalEntityFormDialog(
  BuildContext context, {
  DailyGoalEntity? initial,
}) {
  return showDialog<DailyGoalEntity>(
    context: context,
    builder: (ctx) => _DailyGoalEntityFormDialog(initial: initial),
  );
}

class _DailyGoalEntityFormDialog extends StatefulWidget {
  final DailyGoalEntity? initial;
  const _DailyGoalEntityFormDialog({this.initial});

  @override
  State<_DailyGoalEntityFormDialog> createState() => _DailyGoalEntityFormDialogState();
}

class _DailyGoalEntityFormDialogState extends State<_DailyGoalEntityFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _userIdController;
  late final TextEditingController _targetValueController;
  late final TextEditingController _currentValueController;

  GoalType? _selectedType;
  DateTime? _selectedDate;
  bool _isCompleted = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    // Se for criação, gera um ID automático (timestamp)
    _idController = TextEditingController(text: initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString());
    _userIdController = TextEditingController(text: initial?.userId ?? 'usuario_padrao');
    
    _selectedType = initial?.type ?? GoalType.masonry;
    _targetValueController = TextEditingController(text: initial?.targetValue.toString() ?? '');
    _currentValueController = TextEditingController(text: initial?.currentValue.toString() ?? '');
    _selectedDate = initial?.date ?? DateTime.now();
    _isCompleted = initial?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _idController.dispose();
    _userIdController.dispose();
    _targetValueController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final targetValue = int.tryParse(_targetValueController.text) ?? 0;
    final currentValue = int.tryParse(_currentValueController.text) ?? 0;

    final dto = DailyGoalEntity(
      id: _idController.text.trim(),
      userId: _userIdController.text.trim(),
      type: _selectedType!,
      targetValue: targetValue,
      currentValue: currentValue,
      date: _selectedDate ?? DateTime.now(),
      isCompleted: _isCompleted,
    );

    Navigator.of(context).pop(dto);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar Produção' : 'Nova Produção Diária'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tipo de Serviço (Dropdown)
              DropdownButtonFormField<GoalType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Serviço Executado',
                  border: OutlineInputBorder(),
                ),
                items: GoalType.values.map((g) {
                  return DropdownMenuItem(
                    value: g,
                    child: Text('${g.icon} ${g.description}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedType = v ?? GoalType.masonry),
              ),
              const SizedBox(height: 16),

              // Meta do Dia
              TextFormField(
                controller: _targetValueController,
                decoration: const InputDecoration(
                  labelText: 'Meta do Dia (Qtd)',
                  hintText: 'Ex: 20 (m² ou unidades)',
                  border: OutlineInputBorder(),
                  suffixText: 'unid.',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Informe a meta' : null,
              ),
              const SizedBox(height: 16),

              // Produção Realizada
              TextFormField(
                controller: _currentValueController,
                decoration: const InputDecoration(
                  labelText: 'Produzido Hoje',
                  hintText: 'Quanto foi feito?',
                  border: OutlineInputBorder(),
                  suffixText: 'unid.',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Informe a produção' : null,
              ),
              const SizedBox(height: 16),

              // Data
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data da Produção',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat.yMMMd().format(_selectedDate!),
                  ),
                ),
              ),
              
              // Status
              SwitchListTile(
                title: const Text('Meta Atingida?'),
                value: _isCompleted,
                onChanged: (v) => setState(() => _isCompleted = v),
              ),
              
              // Campos ocultos (ID e UserID) para manter compatibilidade, 
              // mas não mostramos na UI para simplificar
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