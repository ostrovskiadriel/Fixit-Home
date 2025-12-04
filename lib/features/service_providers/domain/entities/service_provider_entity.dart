// lib/features/service_providers/domain/entities/service_provider_entity.dart

class ServiceProviderEntity {
  final String id;
  final String name;
  final ServiceCategory category;
  final String phoneNumber;
  final double rating; // De 0.0 a 5.0
  final bool isFavorite;

  ServiceProviderEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.phoneNumber,
    this.rating = 0.0,
    this.isFavorite = false,
  })  : assert(id.isNotEmpty, 'ID não pode ser vazio'),
        assert(name.length >= 3, 'Nome deve ter pelo menos 3 letras'),
        assert(rating >= 0 && rating <= 5, 'Avaliação deve ser entre 0 e 5');

  // Ícone baseado na categoria (Regra de Negócio visual)
  String get categoryIcon => category.icon;
  
  // Nome legível da categoria
  String get categoryLabel => category.label;

  ServiceProviderEntity copyWith({
    String? id,
    String? name,
    ServiceCategory? category,
    String? phoneNumber,
    double? rating,
    bool? isFavorite,
  }) {
    return ServiceProviderEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

enum ServiceCategory {
  electrician('Eletricista', '⚡'),
  plumber('Encanador', '🚰'),
  painter('Pintor', '🎨'),
  carpenter('Marceneiro', '🪑'),
  general('Faz-Tudo', '🛠️'),
  other('Outro', '📋');

  final String label;
  final String icon;
  const ServiceCategory(this.label, this.icon);
}