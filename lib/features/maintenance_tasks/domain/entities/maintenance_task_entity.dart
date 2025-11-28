// lib/features/maintenance_tasks/domain/entities/maintenance_task_entity.dart

/// Entity de domínio para Tarefas de Manutenção
class MaintenanceTaskEntity {
  final String id;
  final String title;
  final String description;
  final TaskFrequency frequency;
  final TaskDifficulty difficulty;
  final DateTime? lastPerformed;
  final DateTime nextDueDate;
  final bool isArchived;

  MaintenanceTaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
    required this.difficulty,
    this.lastPerformed,
    required this.nextDueDate,
    this.isArchived = false,
  })  : assert(id.isNotEmpty, 'ID não pode ser vazio'),
        assert(title.isNotEmpty, 'Título não pode ser vazio'),
        assert(title.length >= 3, 'Título deve ter pelo menos 3 caracteres');

  /// Regra de Negócio: Verifica se a tarefa está atrasada
  bool get isOverdue {
    if (isArchived) return false;
    final now = DateTime.now();
    // Considera atrasado se a data de vencimento for antes de "hoje" (início do dia)
    final today = DateTime(now.year, now.month, now.day);
    return nextDueDate.isBefore(today);
  }

  /// Regra de Negócio: Dias restantes para o vencimento
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextDueDate.difference(today).inDays;
  }

  /// Regra de Negócio: Define a cor baseada na dificuldade (para UI)
  String get difficultyLabel => difficulty.label;

  /// Cria uma cópia imutável com valores alterados
  MaintenanceTaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    TaskFrequency? frequency,
    TaskDifficulty? difficulty,
    DateTime? lastPerformed,
    DateTime? nextDueDate,
    bool? isArchived,
  }) {
    return MaintenanceTaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      difficulty: difficulty ?? this.difficulty,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MaintenanceTaskEntity &&
        other.id == id &&
        other.title == title &&
        other.frequency == frequency &&
        other.nextDueDate == nextDueDate &&
        other.isArchived == isArchived;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        frequency.hashCode ^
        nextDueDate.hashCode ^
        isArchived.hashCode;
  }

  @override
  String toString() {
    return 'MaintenanceTaskEntity(id: $id, title: $title, due: $nextDueDate, overdue: $isOverdue)';
  }
}

/// Enum para frequência da manutenção
enum TaskFrequency {
  oneTime('Única'),
  weekly('Semanal'),
  monthly('Mensal'),
  quarterly('Trimestral'),
  yearly('Anual');

  final String label;
  const TaskFrequency(this.label);
}

/// Enum para nível de dificuldade
enum TaskDifficulty {
  easy('Fácil', 1),
  medium('Médio', 2),
  hard('Difícil', 3),
  expert('Expert', 4);

  final String label;
  final int level;
  const TaskDifficulty(this.label, this.level);
}