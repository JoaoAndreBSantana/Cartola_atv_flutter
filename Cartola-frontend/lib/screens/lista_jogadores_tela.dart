import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detalhe_jogador_tela.dart';
import 'comparar_jogador_tela.dart';
import 'rankings_tela.dart';

class ListaJogadoresTela extends StatefulWidget {
  const ListaJogadoresTela({Key? key}) : super(key: key);

  @override
  State<ListaJogadoresTela> createState() => _ListaJogadoresTelaState();
}

class _ListaJogadoresTelaState extends State<ListaJogadoresTela> {
  List<dynamic> jogadores = [];
  List<String> clubes = ['Todos'];
  
  // Filtros
  String queryNome = '';
  String posicaoSelecionada = 'Todas';
  String clubeSelecionado = 'Todos';
  
  bool loading = true;
  // variaveis pra comparação
  bool modoComparacao = false;
  Set<int> selecionadosParaComparar = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => loading = true);
    await fetchClubs();
    await fetchJogadores();
    setState(() => loading = false);
  }

  Future<void> fetchClubs() async {// Busca a lista de clubes disponíveis
    try {
      final nomes = await ApiService.fetchClubesNomes();
      setState(() {
        clubes = ['Todos', ...nomes];
      });
    } catch (e) { /* ignore */ }
  }

  Future<void> fetchJogadores() async {// Busca a lista de jogadores com os filtros aplicados
    setState(() => loading = true);
    try {
      final lista = await ApiService.fetchJogadores(
        nome: queryNome,
        posicao: posicaoSelecionada,
        clube: clubeSelecionado,
      );
      setState(() => jogadores = lista);
    } catch (e) { /* ignore */ }
    setState(() => loading = false);
  }

  Widget _buildSearchBar() {// Barra de busca por nome, chama fetchJogadores ao digitar
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar jogador (nome)',
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
          onChanged: (v) {
            queryNome = v;
            // busca os jogadores com o novo filtro
            fetchJogadores();
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {// Controles de filtro por posição e clube
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtro — Posição', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              _buildDropdownFilter('Posição', posicaoSelecionada, 
                ['Todas', 'Goleiro', 'Lateral', 'Zagueiro', 'Meia', 'Atacante'], 
                (v) => setState(() { posicaoSelecionada = v!; fetchJogadores(); })),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtro — Clube', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              _buildDropdownFilter('Clube', clubeSelecionado, clubes, 
                (v) => setState(() { clubeSelecionado = v!; fetchJogadores(); })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> items, Function(String?) onChanged) {// Dropdown para filtro
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  modoComparacao = !modoComparacao;
                  if (!modoComparacao) selecionadosParaComparar.clear();
                });
              },
              icon: Icon(modoComparacao ? Icons.check : Icons.compare_arrows, size: 18),
              label: Text(modoComparacao ? 'Selecionando...' : 'Comparar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modoComparacao ? Colors.green : Colors.white,
                foregroundColor: modoComparacao ? Colors.white : Colors.blue[800],
              ),
            ),
          ),
          // Botão para abrir a tela de Tops/Rankings
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: IconButton(
              icon: const Icon(Icons.emoji_events, color: Colors.white),
              tooltip: 'Tops',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingsTela()));
              },
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 8),
                _buildFilterChips(),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : jogadores.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'Ops, esse jogador não existe aqui',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Barra de ação que aparece quando há 2 ou mais selecionados
                          if (modoComparacao && selecionadosParaComparar.length >= 2)
                            Container(
                              width: double.infinity,
                              color: Colors.green[700],
                              child: TextButton(
                                onPressed: () {
                                  // pass os ids selecionados para a tela de comparação
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CompararJogadorTela(playerIds: selecionadosParaComparar),
                                    ),
                                  );
                                },
                                child: Text(
                                  'REALIZAR COMPARAÇÃO (${selecionadosParaComparar.length})',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            
                          Expanded(
                            child: ListView.separated(
                              itemCount: jogadores.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final j = jogadores[index];
                                final idRaw = j['id'] ?? j['atletas.atleta_id'];
                                final int id = idRaw is int ? idRaw : int.parse(idRaw.toString());
                                final bool estaSelecionado = selecionadosParaComparar.contains(id);

                                return ListTile(
                                  leading: modoComparacao
                                      ? Checkbox(value: estaSelecionado, onChanged: (_) => _tratarSelecao(id))
                                      : _buildAvatar(j),
                                  title: Text(j['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text("${j['posicao_nome'] ?? j['posicao']} | ${j['clube_nome'] ?? j['clube']}"),
                                  tileColor: estaSelecionado ? Colors.green.withOpacity(0.1) : null,
                                  onTap: () {
                                    if (modoComparacao) {
                                      _tratarSelecao(id);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => DetalheJogadorTela(jogadorId: id)),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  void _tratarSelecao(int id) {
    setState(() {
      if (selecionadosParaComparar.contains(id)) selecionadosParaComparar.remove(id);
      else {
        if (selecionadosParaComparar.length >= 2) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apenas 2 jogadores podem ser selecionados')));
        } else {
          selecionadosParaComparar.add(id);
        }
      }
    });
  }

  Widget _buildAvatar(dynamic j) {
    final String urlFoto = (j['foto_url'] ?? j['foto'] ?? '').toString();
    final bool ehSilhueta = urlFoto.contains('FORMATO.png');
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
      child: ClipOval(
        child: ehSilhueta || urlFoto.isEmpty
            ? Icon(Icons.person, color: Colors.grey[400])
            : Image.network(urlFoto, fit: BoxFit.cover),
      ),
    );
  }
}