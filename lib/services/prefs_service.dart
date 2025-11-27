import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar as preferências do usuário (persistência local).
/// Abstrai o SharedPreferences da UI, conforme requisito.
class PrefsService {
  // Instância estática (Singleton)
  static late SharedPreferences _prefs;

  // --- Chaves de Persistência ---
  // Baseado no PRD de exemplo "EduCare" 
  static const String _kOnboardingCompletedKey = 'onboarding_completed';
  static const String _kPoliciesVersionAcceptedKey = 'policies_version_accepted';
  // (Você pode adicionar as outras chaves do PRD aqui, como 'privacy_read_v1', etc.)

  // --- Versão Atual das Políticas ---
  // Se você mudar isso para "v2", o app forçará o usuário a aceitar de novo.
  static const String _kCurrentPoliciesVersion = 'v1';

  /// Inicializa o serviço. Deve ser chamado no main.dart
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Onboarding ---

  /// Verifica se o usuário já completou o Onboarding [cite: 887]
  static bool hasCompletedOnboarding() {
    return _prefs.getBool(_kOnboardingCompletedKey) ?? false;
  }

  /// Marca o Onboarding como completo [cite: 887]
  static Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_kOnboardingCompletedKey, value);
  }

  // --- Políticas e Consentimento ---

  /// Verifica se o usuário aceitou a versão MAIS RECENTE das políticas [cite: 885]
  static bool hasAcceptedLatestPolicies() {
    final acceptedVersion = _prefs.getString(_kPoliciesVersionAcceptedKey);
    return acceptedVersion == _kCurrentPoliciesVersion;
  }

  /// Salva a versão das políticas que o usuário aceitou [cite: 885]
  static Future<void> setPoliciesAccepted() async {
    await _prefs.setString(_kPoliciesVersionAcceptedKey, _kCurrentPoliciesVersion);
    // Você também pode salvar a data do aceite aqui [cite: 886]
    // await _prefs.setString('accepted_at', DateTime.now().toIso8601String());
  }

  /// Limpa o aceite das políticas (para o fluxo de revogação) [cite: 865]
  static Future<void> clearPolicyAcceptance() async {
    await _prefs.remove(_kPoliciesVersionAcceptedKey);
  }
}