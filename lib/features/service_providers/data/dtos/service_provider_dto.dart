// lib/features/service_providers/data/dtos/service_provider_dto.dart

import '../../domain/entities/service_provider_entity.dart';

class ServiceProviderDto {
  final String id;
  final String name;
  final String category;
  final String phone;
  final double rating;
  final bool isFavorite;

  ServiceProviderDto({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.rating,
    required this.isFavorite,
  });

  // JSON (Supabase) -> DTO
  // AQUI ESTAVA O PROBLEMA: Adicionei proteções (?? '') para evitar crash com nulos
  factory ServiceProviderDto.fromJson(Map<String, dynamic> json) {
    return ServiceProviderDto(
      id: json['id']?.toString() ?? '', // Proteção contra ID nulo
      name: json['name']?.toString() ?? 'Sem Nome', // Proteção contra Nome nulo
      category: json['category']?.toString() ?? 'other',
      phone: json['phone']?.toString() ?? '', // Proteção CRÍTICA: aceita nulo e vira ''
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0, // Proteção para números
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  // DTO -> JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'phone': phone,
      'rating': rating,
      'is_favorite': isFavorite,
    };
  }

  // Entity -> DTO
  factory ServiceProviderDto.fromEntity(ServiceProviderEntity entity) {
    return ServiceProviderDto(
      id: entity.id,
      name: entity.name,
      category: entity.category.name,
      phone: entity.phoneNumber,
      rating: entity.rating,
      isFavorite: entity.isFavorite,
    );
  }

  // DTO -> Entity
  ServiceProviderEntity toEntity() {
    return ServiceProviderEntity(
      id: id,
      name: name,
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == category,
        orElse: () => ServiceCategory.other,
      ),
      phoneNumber: phone,
      rating: rating,
      isFavorite: isFavorite,
    );
  }
}