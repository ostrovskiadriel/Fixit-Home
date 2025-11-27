// lib/features/daily_goals/daily_goal_entity_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Importe o arquivo de entidade que você acabou de me enviar
// (Ajuste o caminho '..' se a sua estrutura de pastas for diferente)
import '../../domain/entities/daily_goal_entity.dart';

/// Função helper para exibir o diálogo.
/// Retorna a entidade criada/editada ou null se for cancelado.
Future<DailyGoalEntity?> showDailyGoalEntityFormDialog(
  BuildContext context, {
  DailyGoalEntity? initial,
}) {
  return showDialog<DailyGoalEntity>(
    context: context,
    builder: (ctx) => _DailyGoalEntityFormDialog(initial: initial),
  );
}

/// Widget interno do diálogo (Stateful)
class _DailyGoalEntityFormDialog extends StatefulWidget {
  final DailyGoalEntity? initial;

  const _DailyGoalEntityFormDialog({this.initial});

  @override
  State<_DailyGoalEntityFormDialog> createState() =>
      _DailyGoalEntityFormDialogState();
}

class _DailyGoalEntityFormDialogState
    extends State<_DailyGoalEntityFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para os campos de texto
  late final TextEditingController _idController;
  late final TextEditingController _userIdController;
  late final TextEditingController _targetValueController;
  late final TextEditingController _currentValueController;

  // Variáveis de estado para os outros campos
  GoalType? _selectedType;
  DateTime? _selectedDate;
  bool _isCompleted = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    // Preenche os campos com dados iniciais (se for edição)
    // ou com valores padrão (se for criação)
    _idController = TextEditingController(text: initial?.id ?? '');
    _userIdController = TextEditingController(text: initial?.userId ?? '');
    _selectedType = initial?.type ?? GoalType.moodEntries;
    _targetValueController =
        TextEditingController(text: initial?.targetValue.toString() ?? '');
    _currentValueController =
        TextEditingController(text: initial?.currentValue.toString() ?? '');
    _selectedDate = initial?.date ?? DateTime.now();
    _isCompleted = initial?.isCompleted ?? false;
  }

  @override
  void dispose() {
    // Limpa os controllers para evitar memory leaks
    _idController.dispose();
    _userIdController.dispose();
    _targetValueController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  /// Exibe um SnackBar de erro [cite: 3035-3039]
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Exibe o seletor de data (datepicker) [cite: 2970-2982]
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Formata a data para exibição amigável [cite: 2984-2992]
  String _formatDate(DateTime date) {
    try {
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return date.toIso8601String(); // Fallback
    }
  }

  /// Valida os campos e retorna a entidade via Navigator.pop [cite: 2994-3033]
  void _onConfirm() {
    // Validações mínimas de UI
    if (_idController.text.trim().isEmpty) {
      _showError('ID é obrigatório.');
      return;
    }
    if (_userIdController.text.trim().isEmpty) {
      _showError('User ID é obrigatório.');
      return;
    }
    if (_selectedType == null) {
      _showError('Tipo de meta é obrigatório.');
      return;
    }

    final targetText = _targetValueController.text.trim();
    final currentText = _currentValueController.text.trim();

    if (targetText.isEmpty) {
      _showError('Valor alvo (targetValue) é obrigatório.');
      return;
    }
    if (currentText.isEmpty) {
      _showError('Valor atual (currentValue) é obrigatório.');
      return;
    }

    final targetValue = int.tryParse(targetText);
    final currentValue = int.tryParse(currentText);

    if (targetValue == null || targetValue <= 0) {
      _showError('Valor alvo deve ser um número inteiro maior que 0.');
      return;
    }
    if (currentValue == null || currentValue < 0) {
      _showError('Valor atual deve ser um inteiro >= 0.');
      return;
    }

    final date = _selectedDate ?? DateTime.now();

    // Cria a entidade de domínio
    final dto = DailyGoalEntity(
      id: _idController.text.trim(),
      userId: _userIdController.text.trim(),
      type: _selectedType!,
      targetValue: targetValue,
      currentValue: currentValue,
      date: date,
      isCompleted: _isCompleted,
    );

    // Retorna a entidade para a tela anterior
    Navigator.of(context).pop(dto);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar Meta Diária' : 'Adicionar Meta Diária'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ID
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'ID'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),

              // User ID
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: 'User ID'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),

              // Tipo (enum)
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Tipo de meta'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<GoalType>(
                    value: _selectedType,
                    isExpanded: true,
                    items: GoalType.values
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text('${g.icon} ${g.description}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Target Value (int)
              TextFormField(
                controller: _targetValueController,
                decoration:
                    const InputDecoration(labelText: 'Valor alvo (targetValue)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),

              // Current Value (int)
              TextFormField(
                controller: _currentValueController,
                decoration: const InputDecoration(
                    labelText: 'Valor atual (currentValue)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),

              // Date picker
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data'),
                      child: Text(
                        _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : 'Selecionar data',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Escolher'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // isCompleted
              Row(
                children: [
                  const Expanded(child: Text('Concluída?')),
                  Switch(
                    value: _isCompleted,
                    onChanged: (v) => setState(() => _isCompleted = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Retorna null
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: Text(_isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}