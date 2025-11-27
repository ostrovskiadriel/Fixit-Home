// lib/widgets/onboarding_page_widget.dart
import 'package:flutter/material.dart';

class OnboardingPageWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingPageWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 120,
            color: colors.primary, // Usa a cor primária (Azul)
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: textTheme.headlineMedium?.copyWith(
              color: colors.onSurface, // Usa a cor de texto (Slate)
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurface.withAlpha(204),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}