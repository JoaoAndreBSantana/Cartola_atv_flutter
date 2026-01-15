import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  //função generica para get de Listas
  static Future<List<dynamic>> _getList(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      }
      throw Exception('Erro: ${resp.statusCode}');
    } catch (e) {
      throw Exception('Falha na conexão: $e');
    }
  }

 
  //busca a lista completa de jogadores com filtros opcionas
  static Future<List<dynamic>> fetchJogadores({
    String nome = '',
    String posicao = 'Todas',
    String clube = 'Todos',
  }) async {
    String params = '?nome=${Uri.encodeComponent(nome)}';
    if (posicao != 'Todas') params += '&posicao=${Uri.encodeComponent(posicao)}';
    if (clube != 'Todos') params += '&clube=${Uri.encodeComponent(clube)}';

    return _getList('jogadores$params');
  }
  
  static Future<Map<String, dynamic>> fetchJogadorDetalhe(int id) async {
    final resp = await http.get(Uri.parse('$baseUrl/jogadores/$id'));
    return jsonDecode(resp.body);
  }
// Busca o histórico de rodadas de um jogador
  static Future<List<dynamic>> fetchHistoricoJogador(int id, {int limite = 50}) => _getList('jogadores/$id/rodadas?limite=$limite');

  
  // Top jogadores em gols, assistencias etc
  static Future<List<dynamic>> fetchTopGols() => _getList('scouts/ataque/top-gols');
  // Retorna a lista de jogadores com mais assistencias
  static Future<List<dynamic>> fetchTopAssistencias() => _getList('scouts/ataque/top-assistencias');
  // Retorna a lista de jogadores com mais finalizações perigosas
  static Future<List<dynamic>> fetchTopFinalizacoes() => _getList('scouts/ataque/top-finalizacoes-perigosas');
  // Retorna a lista de jogadores com mais faltas sofridas
  static Future<List<dynamic>> fetchTopFaltasSofridas() => _getList('scouts/ataque/top-faltas-sofridas');

  
  // Top jogadores em desarmes, faltas cometidas, jogos sem gol, defesas difíceis e pênaltis defendidos
  static Future<List<dynamic>> fetchTopDesarmes() => _getList('scouts/defesa/top-desarmes');
  // Retorna a lista de jogadores com mais faltas cometidas
  static Future<List<dynamic>> fetchTopFaltasCometidas() => _getList('scouts/defesa/top-faltas-cometidas');
  // Retorna a lista de goleiros com mais jogos sem sofrer gol
  static Future<List<dynamic>> fetchTopSG() => _getList('scouts/defesa/top-jogos-sem-gol');
  // Retorna a lista de goleiros com mais defesas difíceis
  static Future<List<dynamic>> fetchTopDefesasGoleiro() => _getList('scouts/goleiros/top-defesas-dificeis');
  // Retorna a lista de goleiros com mais pênaltis defendidos
  static Future<List<dynamic>> fetchTopPenaltisDefendidos() => _getList('scouts/goleiros/top-penaltis-defendidos');

  
  // Busca jogadores por posição
  static Future<List<dynamic>> fetchPorClube(String clube) => _getList('estatisticas/clube/$clube');
  // Busca a lista de clubes disponíveis
  static Future<List<dynamic>> fetchClubesDisponiveis() => _getList('clubs');
  // Busca a lista de nomes de clubes
  static Future<List<String>> fetchClubesNomes() async {
    final list = await _getList('clubs');
    return List<String>.from(list);
  }
// Busca o ranking da rodada ou temporada com filtro opcional por posição
  static Future<List<dynamic>> fetchRankingRodada({
    required int rodada,
    String? posicao,
    int limite = 10,
  }) async {
    final posParam = (posicao == null || posicao == 'Todas') ? '' : '&posicao=${Uri.encodeComponent(posicao)}';
    return _getList('ranking/rodada?rodada=$rodada&limite=$limite$posParam');
  }

  // Busca genérica por path com parâmetros 
  static Future<List<dynamic>> fetchByPath(String path, [Map<String, String>? params]) async {
    String p = path.startsWith('/') ? path.substring(1) : path;
    if (params != null && params.isNotEmpty) {
      final qp = Uri(queryParameters: params).query; // qp query parameters 
      p = '$p?$qp';// p path o caminho 
    }
    return _getList(p);
  }
  // Busca a última rodada
  static Future<Map<String, dynamic>> fetchUltimaRodada() async {
    final resp = await http.get(Uri.parse('$baseUrl/rodada/ultima'));//endpoint para buscar a última rodada
    return jsonDecode(resp.body);
  }

  
  // Compara dois jogadores pelo ID
  static Future<List<dynamic>> fetchComparacao(int id1, int id2) => _getList('comparacao?id1=$id1&id2=$id2');
}