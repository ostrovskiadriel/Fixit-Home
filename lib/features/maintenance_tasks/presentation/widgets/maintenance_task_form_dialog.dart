// lib/features/maintenance_tasks/presentation/widgets/maintenance_task_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/maintenance_task_entity.dart';

/// Helper para exibir o diálogo
Future<MaintenanceTaskEntity?> showMaintenanceTaskFormDialog(
  BuildContext context, {
  MaintenanceTaskEntity? initial,
}) {
  return showDialog<MaintenanceTaskEntity>(
    context: context,
    builder: (ctx) => _MaintenanceTaskFormDialog(initial: initial),
  );
}

class _MaintenanceTaskFormDialog extends StatefulWidget {
  final MaintenanceTaskEntity? initial;

  const _MaintenanceTaskFormDialog({this.initial});

  @override
  State<_MaintenanceTaskFormDialog> createState() =>
      _MaintenanceTaskFormDialogState();
}

class _MaintenanceTaskFormDialogState extends State<_MaintenanceTaskFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  // Estado dos campos
  late TaskFrequency _frequency;
  late TaskDifficulty _difficulty;
  late DateTime _nextDueDate;
  String? _id; // ID para edição

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    // Inicializa com dados existentes ou valores padrão
    _id = initial?.id;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    
    _frequency = initial?.frequency ?? TaskFrequency.monthly;
    _difficulty = initial?.difficulty ?? TaskDifficulty.medium;
    _nextDueDate = initial?.nextDueDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Gera um ID simples baseado no tempo (se for criação)
  String _generateId() {
    return _id ?? DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _onConfirm() {
    if (_formKey.currentState!.validate()) {
      
      final newTask = MaintenanceTaskEntity(
        id: _generateId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        frequency: _frequency,
        difficulty: _difficulty,
        nextDueDate: _nextDueDate,
        // Mantém valores antigos se for edição
        lastPerformed: widget.initial?.lastPerformed,
        isArchived: widget.initial?.isArchived ?? false,
      );

      Navigator.of(context).pop(newTask);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _nextDueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar Tarefa' : 'Nova Manutenção'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex: Limpar filtro do ar',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 3) {
                    return 'Mínimo de 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Dropdown: Frequência
              DropdownButtonFormField<TaskFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequência',
                  border: OutlineInputBorder(),
                ),
                items: TaskFrequency.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.label),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 16),

              // Dropdown: Dificuldade
              DropdownButtonFormField<TaskDifficulty>(
                initialValue: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Dificuldade',
                  border: OutlineInputBorder(),
                ),
                items: TaskDifficulty.values.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Row(
                      children: [
                        // Bolinha colorida indicando dificuldade
                        Icon(Icons.circle, size: 12, color: _getDifficultyColor(d)),
                        const SizedBox(width: 8),
                        Text(d.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _difficulty = v!),
              ),
              const SizedBox(height: 16),

              // Data de Vencimento
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Próximo Vencimento',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat.yMMMd().format(_nextDueDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _onConfirm,
          child: Text(_isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }

  Color _getDifficultyColor(TaskDifficulty d) {
    switch (d) {
      case TaskDifficulty.easy: return Colors.green;
      case TaskDifficulty.medium: return Colors.orange;
      case TaskDifficulty.hard: return Colors.red;
      case TaskDifficulty.expert: return Colors.purple;
    }
  }
}