import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardTela extends StatefulWidget {
  const DashboardTela({Key? key}) : super(key: key);

  @override
  State<DashboardTela> createState() => _DashboardTelaState();
}

class _DashboardTelaState extends State<DashboardTela> {
  final String baseUrl = 'http://10.0.2.2:8000'; 

  int? ultimaRodada;// Guarda a última rodada disponível
  int rodadaSelecionada = 0;// Guarda a rodada selecionada no filtro, começa em 0

  String posicaoSelecionada = 'Todas';
  String? clubeSelecionado;// Guarda o clube selecionado no filtro

// Listas de clubes disponíveis e dados carregados
  List<String> clubes = [];
  List<dynamic> topLiga = [];
  List<dynamic> topClube = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => loading = true);
    await fetchUltimaRodada();// Busca a última rodada
    await fetchClubs();// Busca a lista de clubes
    await fetchAll();// Busca os dados iniciais
    setState(() => loading = false);
  }

  Future<void> fetchUltimaRodada() async {
    try {
      final data = await ApiService.fetchUltimaRodada();// Busca a última rodada pela api
      setState(() {
        ultimaRodada = (data['ultima_rodada'] as int?) ?? 1;
        rodadaSelecionada = ultimaRodada ?? 1;
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> fetchClubs() async {
    try {
      final nomes = await ApiService.fetchClubesNomes();
      setState(() {
        clubes = nomes;
        if (clubes.isNotEmpty) clubeSelecionado ??= clubes.first;
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> fetchAll() async {// Busca os dados iniciais
    final rodada = _resolveRodada();
    await Future.wait([fetchTopLiga(rodada), fetchTopLigaAllForClubFilter(rodada)]);
  }

  int _resolveRodada() {
    return rodadaSelecionada > 0 ? rodadaSelecionada : 1;
  }
// Busca top da rodada com filtros de posição
  Future<void> fetchTopLiga(int rodada) async {
    try {
      final lista = await ApiService.fetchRankingRodada(
        rodada: rodada,
        posicao: posicaoSelecionada,
        limite: 5,
      );
      setState(() => topLiga = lista);
    } catch (e) {
      // ignore
    }
  }

  // Busca top da rodada e filtra pelo clube selecionado 
  Future<void> fetchTopLigaAllForClubFilter(int rodada) async {
    try {
      final lista = await ApiService.fetchRankingRodada(
        rodada: rodada,
        posicao: posicaoSelecionada,
        limite: 100,
      );

      final filtered = clubeSelecionado == null
          ? []
          : lista.where((e) => (e['clube_nome'] ?? e['clube']) == clubeSelecionado).toList();
      setState(() => topClube = filtered.take(5).toList());
    } catch (e) {
      // ignore
    }
  }

  Widget _buildFilters() {// Constrói os controles de filtro
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildRodadaControl()),
            SizedBox(width: 12),
            Expanded(child: _buildPosicaoControl()),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildClubeControl()),
            SizedBox(width: 12),
            ElevatedButton(onPressed: () => fetchAll(), child: Text('Aplicar')),
          ],
        )
      ],
    );
  }

  Widget _buildRodadaControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Número da Rodada'),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Ex: 5',
            isDense: true,
          ),
          // Atualiza a variável rodadaSelecionada diretamente
          onChanged: (t) => rodadaSelecionada = int.tryParse(t) ?? 1,
        ),
      ],
    );
  }

  Widget _buildPosicaoControl() {
    final posicoes = ['Todas', 'Goleiro', 'Lateral', 'Zagueiro', 'Meia', 'Atacante'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Posição'),
        DropdownButton<String>(
          value: posicaoSelecionada,
          items: posicoes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => setState(() => posicaoSelecionada = v ?? 'Todas'),
        ),
      ],
    );
  }

  Widget _buildClubeControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clube'),
        DropdownButton<String>(
          isExpanded: true,
          value: clubeSelecionado,
          items: clubes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => clubeSelecionado = v),
        )
      ],
    );
  }

  Widget _buildCard(String title, List<dynamic> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...items.map((j) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(j['nome'] ?? j['nome_completo'] ?? ''),
                  subtitle: Text(j['clube_nome'] ?? j['clube'] ?? ''),
                  trailing: Text((j['pontuacao_fantasy'] ?? j['total_pontos'] ?? j['pontuacao'] ?? 0).toString()),
                ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: loading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilters(),
                    SizedBox(height: 12),
                    _buildCard('Top 5 da Liga (rodada ${_resolveRodada()})', topLiga),
                    SizedBox(height: 12),
                    _buildCard('Top 5 do Clube (${clubeSelecionado ?? '-'})', topClube),
                  ],
                ),
              ),
      ),
    );
  }
}
