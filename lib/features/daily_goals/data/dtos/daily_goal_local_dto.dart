// lib/features/daily_goals/daily_goal_local_dto.dart
import 'daily_goal_dto.dart';
abstract class DailyGoalLocalDto {
  Future<void> upsertAll(List<DailyGoalDto> dtos);
  Future<List<DailyGoalDto>> listAll();
  Future<DailyGoalDto?> getById(String id);
  Future<void> clear();
}