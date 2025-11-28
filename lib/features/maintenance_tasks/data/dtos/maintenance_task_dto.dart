// lib/features/maintenance_tasks/data/dtos/maintenance_task_dto.dart

import '../../domain/entities/maintenance_task_entity.dart';

class MaintenanceTaskDto {
  final String id;
  final String title;
  final String description;
  final String frequency; // Salvaremos o nome do Enum (ex: 'weekly')
  final int difficultyLevel; // Salvaremos o nível numérico (ex: 1)
  final String? lastPerformed;
  final String nextDueDate;
  final bool isArchived;

  MaintenanceTaskDto({
    required this.id,
    required this.title,
    required this.description,
    required this.frequency,
    required this.difficultyLevel,
    this.lastPerformed,
    required this.nextDueDate,
    required this.isArchived,
  });

  /// Converte de JSON (Supabase) para DTO
  factory MaintenanceTaskDto.fromJson(Map<String, dynamic> json) {
    return MaintenanceTaskDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] ?? '',
      frequency: json['frequency'] as String,
      difficultyLevel: json['difficulty_level'] as int,
      lastPerformed: json['last_performed'] as String?,
      nextDueDate: json['next_due_date'] as String,
      isArchived: json['is_archived'] ?? false,
    );
  }

  /// Converte do DTO para JSON (para salvar no Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'frequency': frequency,
      'difficulty_level': difficultyLevel,
      'last_performed': lastPerformed,
      'next_due_date': nextDueDate,
      'is_archived': isArchived,
    };
  }

  // --- Mappers (Auxiliares de Conversão) ---

  /// Converte da Entidade (Domain) para DTO (Data)
  factory MaintenanceTaskDto.fromEntity(MaintenanceTaskEntity entity) {
    return MaintenanceTaskDto(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      frequency: entity.frequency.name, // Enum -> String
      difficultyLevel: entity.difficulty.level, // Enum -> Int
      lastPerformed: entity.lastPerformed?.toIso8601String(),
      nextDueDate: entity.nextDueDate.toIso8601String(),
      isArchived: entity.isArchived,
    );
  }

  /// Converte do DTO (Data) para Entidade (Domain)
  MaintenanceTaskEntity toEntity() {
    return MaintenanceTaskEntity(
      id: id,
      title: title,
      description: description,
      // Converte String -> Enum (Frequency)
      frequency: TaskFrequency.values.firstWhere(
        (e) => e.name == frequency,
        orElse: () => TaskFrequency.oneTime,
      ),
      // Converte Int -> Enum (Difficulty)
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.level == difficultyLevel,
        orElse: () => TaskDifficulty.medium,
      ),
      lastPerformed: lastPerformed != null ? DateTime.parse(lastPerformed!) : null,
      nextDueDate: DateTime.parse(nextDueDate),
      isArchived: isArchived,
    );
  }
}