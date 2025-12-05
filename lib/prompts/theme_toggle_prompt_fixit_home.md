````markdown
# Prompt Operacional (Adaptado) — Toggle de Tema para FixIt Home

Objetivo
--------
Adaptar e implementar um toggle de tema (claro / escuro / seguir sistema) no app FixIt Home, integrando-o ao `MaterialApp`, persistindo a escolha do usuário via `PrefsService`, e propondo um controlador (`ThemeController`) para gerenciar o estado do tema de forma centralizada.

Contexto do repositório (rápido)
--------------------------------
- `lib/main.dart` já inicializa `PrefsService` com `PrefsService.init()` e usa `themeMode: ThemeMode.system` no `MaterialApp`.
- `lib/services/prefs_service.dart` existe e centraliza SharedPreferences.
- Estrutura de telas: `lib/screens/home_screen.dart` (Home) e `lib/widgets/app_drawer.dart` contém ações de preferência — local recomendado para o toggle.

Porque adaptar para FixIt Home
-----------------------------
- Mantém consistência com o serviço de preferências já existente (`PrefsService`).
- Evita duplicar código de persistência.
- Permite que `FixItApp` reaja ao `ThemeMode` do `ThemeController` via `ListenableBuilder` (ou Provider) e aplique o tema em toda a app.

Resumo técnico das mudanças
--------------------------
1. Expandir `PrefsService` para incluir chave e métodos `getThemeMode()` / `setThemeMode()` (string: 'system'|'light'|'dark').
2. Criar `lib/features/app/theme_controller.dart` (classe `ThemeController extends ChangeNotifier`) que lê a preferência do `PrefsService` e expõe `mode`, `isDarkMode`, `isSystemMode`, `setMode()` e `toggle()`.
3. No `main.dart`: criar e carregar o `ThemeController` antes do `runApp()` (aproveitar `PrefsService.init()` já presente), passar o controller ao `FixItApp`.
4. Em `lib/main.dart` (classe `FixItApp`) ou `lib/features/app/food_safe_app.dart` (se existir), ouvir o controller com `ListenableBuilder` e usar `themeController.mode` no `MaterialApp.themeMode`.
5. No Drawer (`lib/widgets/app_drawer.dart` ou `lib/screens/home_screen.dart`), substituir o `SwitchListTile` local por um que consome `ThemeController` e faça `await controller.toggle(brightness)` ou `controller.setMode(...)`.

Trechos de código adaptados (exemplos prontos para colar)
-------------------------------------------------------

1) Adicionar chave e métodos ao `PrefsService` (em `lib/services/prefs_service.dart`):

```dart
static const String _kThemeModeKey = 'theme_mode';

static Future<String> getThemeMode() async {
  return _prefs.getString(_kThemeModeKey) ?? 'system';
}

static Future<void> setThemeMode(String mode) async {
  await _prefs.setString(_kThemeModeKey, mode);
}

static Future<void> removeThemeMode() async {
  await _prefs.remove(_kThemeModeKey);
}
```

2) `ThemeController` (em `lib/features/app/theme_controller.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:fixit_home/services/prefs_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;
  bool get isSystemMode => _mode == ThemeMode.system;

  Future<void> load() async {
    final saved = await PrefsService.getThemeMode();
    _mode = _stringToThemeMode(saved);
  }

  Future<void> setMode(ThemeMode newMode) async {
    if (_mode != newMode) {
      _mode = newMode;
      await PrefsService.setThemeMode(_themeModeToString(newMode));
      notifyListeners();
    }
  }

  Future<void> toggle(Brightness currentBrightness) async {
    ThemeMode newMode;
    if (_mode == ThemeMode.system) {
      newMode = currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      newMode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    await setMode(newMode);
  }

  ThemeMode _stringToThemeMode(String v) => v == 'light' ? ThemeMode.light : (v == 'dark' ? ThemeMode.dark : ThemeMode.system);
  String _themeModeToString(ThemeMode m) => m == ThemeMode.light ? 'light' : (m == ThemeMode.dark ? 'dark' : 'system');
}
```

3) `main.dart` (pequena adaptação):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await PrefsService.init();

  final themeController = ThemeController();
  await themeController.load();

  await Supabase.initialize(...);
  runApp(FixItApp(themeController: themeController));
}
```

4) `FixItApp` (usar `ListenableBuilder` para rebuild do MaterialApp):

```dart
class FixItApp extends StatelessWidget {
  final ThemeController themeController;
  const FixItApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return MaterialApp(
          // ...
          themeMode: themeController.mode,
        );
      },
    );
  }
}
```

5) Toggle no Drawer (`lib/widgets/app_drawer.dart`):

```dart
final brightness = MediaQuery.platformBrightnessOf(context);
SwitchListTile(
  secondary: Icon(controller.isDarkMode ? Icons.dark_mode : Icons.light_mode_outlined),
  title: const Text('Tema escuro'),
  subtitle: Text(controller.isSystemMode ? 'Seguindo sistema' : (controller.isDarkMode ? 'Ativado' : 'Desativado')),
  value: controller.isSystemMode ? (brightness == Brightness.dark) : controller.isDarkMode,
  onChanged: (v) async => await controller.toggle(brightness),
),
```

Viabilidade para FixIt Home (análise rápida)
-------------------------------------------
- Complexidade: baixa a moderada. Projeto já inicializa `PrefsService`, tem MaterialApp definido, e usa `ColorScheme.fromSeed`; isso facilita a integração.
- Riscos: mínimos — mudanças locais no `main.dart` e `FixItApp` exigem atenção nas rotas/const constructors e na passagem do controller para telas. Testes manuais são suficientes.
- Compatibilidade: completamente compatível com Material 3 e `ColorScheme.fromSeed` já em uso.
- Tempo estimado (implementação com testes manuais): ~30–90 minutos, dependendo se desejar `Provider`/`get_it` em vez de passar o controller por construtor.

Recomendações práticas
---------------------
- Use `PrefsService` para persistência (consistência no projeto).
- Inicialize `ThemeController` em `main.dart` após `PrefsService.init()` para ler preferência antes do `runApp()`.
- Para escalabilidade, registre `ThemeController` no `GetIt` ou `Provider` (opcional) em vez de passar por construtor para todas as rotas.
- Adicione testes manuais: alternar tema, fechar app, abrir app — preferência deve persistir.
- Considere adicionar um pequeno `SnackBar` ao alternar para mostrar: "Tema salvo" (opcional).

Se quiser, eu implemento essas mudanças agora (edito `PrefsService`, crio `ThemeController`, atualizo `main.dart` e `FixItApp`, e adapto o Drawer). Diga apenas se prefere que eu:

- (A) Aplique a implementação mínima (ChangeNotifier + PrefsService methods + pequenas mudanças em `main.dart`/`FixItApp`), ou
- (B) Faça a versão com `Provider`/`get_it` (mais infraestrutura, melhor para testes e injeção). 

````
