// lib/data/dtos/daily_goal_dto.dart
// DTO (Data Transfer Object) - representa os dados como eles são salvos
// (ex: no SharedPreferences ou no Supabase)
class DailyGoalDto {
  final String goalId; // Note: 'goalId' em vez de 'id'
  final String userId;
  final String type; // Note: 'String' em vez de 'GoalType'
  final int targetValue;
  final int currentValue;
  final String date; // Note: 'String' em vez de 'DateTime'
  final bool isCompleted;

  DailyGoalDto({
    required this.goalId,
    required this.userId,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.date,
    required this.isCompleted,
  });

  // Converte DTO para JSON (para salvar no SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'goal_id': goalId,
      'user_id': userId,
      'type': type,
      'target_value': targetValue,
      'current_value': currentValue,
      'date': date,
      'is_completed': isCompleted,
    };
  }

  // Cria DTO a partir de JSON (lido do SharedPreferences)
  factory DailyGoalDto.fromJson(Map<String, dynamic> map) {
    return DailyGoalDto(
      goalId: map['goal_id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      targetValue: map['target_value'] as int,
      currentValue: map['current_value'] as int,
      date: map['date'] as String,
      isCompleted: map['is_completed'] as bool,
    );
  }
}