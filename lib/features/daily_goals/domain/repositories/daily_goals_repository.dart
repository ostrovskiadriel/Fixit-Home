/// Interface de repositório para a entidade DailyGoal.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que a entidade DailyGoal possui métodos de conversão robustos (ex: aceitar id como int ou string, datas como DateTime ou String).
/// - Ao implementar esta interface, adicione prints/logs (usando kDebugMode) nos métodos principais para facilitar o diagnóstico de problemas de cache, conversão e sync.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está "mounted" antes de chamar setState, evitando exceções de widget desmontado.
/// - Consulte os arquivos de debug do projeto para exemplos de logs, prints e soluções de problemas reais.

import '../entities/daily_goal_entity.dart';

abstract class DailyGoalsRepository {
  /// Carrega as metas do cache local para render inicial rápido.
  ///
  /// Use este método na inicialização da tela para exibir dados imediatamente
  /// sem esperar pela sincronização com o servidor. Ideal para melhorar a UX.
  /// Retorna uma lista vazia se não houver cache disponível.
  Future<List<DailyGoalEntity>> loadFromCache();

  /// Sincroniza as metas com o servidor de forma incremental.
  ///
  /// Recupera apenas as metas modificadas desde a última sincronização (baseado em lastSync).
  /// Retorna a quantidade de registros que foram criados, atualizados ou deletados.
  /// Use este método para manter o cache sempre atualizado sem sobrecarregar a rede.
  Future<int> syncFromServer();

  /// Retorna a lista completa de metas do cache (após sincronização).
  ///
  /// Normalmente este método é chamado após syncFromServer() para garantir
  /// que os dados estejam atualizados. Use para popular a UI com a lista completa.
  Future<List<DailyGoalEntity>> listAll();

  /// Retorna apenas as metas em destaque (filtradas por flag 'featured' ou critério similar).
  ///
  /// Use para exibir metas prioritárias ou sugeridas na home screen.
  /// O filtro pode ser definido no banco local ou no servidor durante a sincronização.
  Future<List<DailyGoalEntity>> listFeatured();

  /// Busca uma meta específica pelo ID no cache.
  ///
  /// Use para obter detalhes de uma meta individual (ex: ao abrir a tela de edição).
  /// Retorna null se a meta não for encontrada.
  Future<DailyGoalEntity?> getById(String id);

  /// Salva ou atualiza uma meta no cache local.
  ///
  /// Use após editar uma meta para persistir as mudanças localmente.
  /// Retorna true se bem-sucedido, false caso contrário.
  Future<bool> save(DailyGoalEntity goal);

  /// Deleta uma meta do cache local pelo ID.
  ///
  /// Use com cuidado, pois esta operação é geralmente irreversível no cache local.
  /// Retorna true se bem-sucedido, false caso contrário.
  Future<bool> delete(String id);
}

/*
// Exemplo de uso:
import 'package:fixit_home/features/daily_goals/domain/repositories/daily_goals_repository.dart';

class MinhaImplementacaoDeDailyGoalsRepository implements DailyGoalsRepository {
  // Implementação com DAO local e datasource remoto
  
  @override
  Future<List<DailyGoalEntity>> loadFromCache() async {
    // Buscar do SharedPreferences ou SQLite
    return [];
  }
  
  @override
  Future<int> syncFromServer() async {
    // Sincronizar com Supabase
    return 0;
  }
  
  // ... outros métodos
}

// Uso na tela:
final repository = MinhaImplementacaoDeDailyGoalsRepository();
final metas = await repository.listAll();

// Dica: implemente esta interface usando um DAO local e um datasource remoto (Supabase).
// Para testes, crie um mock que retorna dados fixos.

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (ex: id como string): ajuste o fromMap/toMap da entidade/DTO para aceitar múltiplos formatos.
// - Falha ao atualizar UI após sync: verifique se o widget está mounted antes de chamar setState.
// - Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão.
// - Problemas com Supabase (RLS, inicialização): consulte documentação e debug prompts.

// Referências úteis:
// - DailyGoalEntity (entidade de domínio)
// - DailyGoalDTO (data transfer object para serialização)
// - Supabase Flutter package
*/
