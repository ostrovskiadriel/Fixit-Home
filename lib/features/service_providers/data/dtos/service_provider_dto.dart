// lib/features/service_providers/data/dtos/service_provider_dto.dart

import '../../domain/entities/service_provider_entity.dart';

class ServiceProviderDto {
  final String id;
  final String name;
  final String category; // Salva como String (ex: 'electrician')
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
  factory ServiceProviderDto.fromJson(Map<String, dynamic> json) {
    return ServiceProviderDto(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      phone: json['phone'] as String,
      rating: (json['rating'] as num).toDouble(),
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