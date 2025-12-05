// lib/features/daily_goals/domain/entities/daily_goal_entity.dart

class DailyGoalEntity {
  DailyGoalEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.date,
    required this.isCompleted,
  })  : assert(id.isNotEmpty, 'ID não pode ser vazio'),
        assert(userId.isNotEmpty, 'User ID não pode ser vazio'),
        assert(targetValue > 0, 'Meta deve ser maior que zero'),
        assert(currentValue >= 0, 'Produção não pode ser negativa');

  final String id;
  final String userId;
  final GoalType type;
  final int targetValue;  // Ex: 50 (metros quadrados)
  final int currentValue; // Ex: 25 (já feitos)
  final DateTime date;
  final bool isCompleted;

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
  int get progressPercentage => (progress * 100).round();
  bool get isAchieved => currentValue >= targetValue;
  int get remaining => (targetValue - currentValue).clamp(0, targetValue);

  /// Retorna true se a data da meta é hoje (mesma data local)
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  DailyGoalEntity copyWith({
    String? id,
    String? userId,
    GoalType? type,
    int? targetValue,
    int? currentValue,
    DateTime? date,
    bool? isCompleted,
  }) {
    return DailyGoalEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// NOVOS TIPOS PARA REFORMA
enum GoalType {
  demolition('Demolição', '🔨'),
  masonry('Alvenaria/Paredes', '🧱'),
  flooring('Piso/Revestimento', '📏'),
  painting('Pintura', '🖌️'),
  electrical('Elétrica', '⚡'),
  plumbing('Hidráulica', '🚰'),
  finishing('Acabamento', '✨'),
  cleaning('Limpeza de Obra', '🧹');

  final String description;
  final String icon;

  const GoalType(this.description, this.icon);

  static GoalType fromString(String value) {
    return GoalType.values.firstWhere(
      (type) => type.name == value,
      // Fallback seguro caso venha um tipo antigo do banco
      orElse: () => GoalType.masonry, 
    );
  }
}