import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RankingsTela extends StatefulWidget {
  const RankingsTela({Key? key}) : super(key: key);

  @override
  State<RankingsTela> createState() => _RankingsTelaState();
}

class _RankingsTelaState extends State<RankingsTela> {
  bool loading = true;
  List<dynamic> items = [];

  // filtros
  String tipoSelecionado = 'Artilheiros';
  bool usarRodada = true;
  int? rodada;
  String posicaoSelecionada = 'Todas';
  String clubeSelecionado = 'Todos';

  List<String> tipos = [
    'Artilheiros',
    'Assistências',
    'Finalizadores',
    'Desarmes',
    'Faltas Sofridas',
    'Faltas Cometidas',
    'Goleiros - Pênaltis Defendidos'
  ];

  List<String> clubes = ['Todos'];
  final List<String> posicoes = ['Todas', 'Goleiro', 'Lateral', 'Zagueiro', 'Meia', 'Atacante'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => loading = true);
    await Future.wait([_fetchUltimaRodada(), _fetchClubs()]);
    await _buscar();
    setState(() => loading = false);
  }

  Future<void> _fetchUltimaRodada() async {
    try {
      final j = await ApiService.fetchUltimaRodada();
      rodada = (j['ultima_rodada'] as int?) ?? rodada ?? 1;
    } catch (_) {}
  }

  Future<void> _fetchClubs() async {
    try {
      final nomes = await ApiService.fetchClubesNomes();
      setState(() => clubes = ['Todos', ...nomes]);
    } catch (_) {}
  }

  String _endpointForTipo(String tipo) {
    switch (tipo) {
      case 'Artilheiros':
        return '/scouts/ataque/top-gols';
      case 'Assistências':
        return '/scouts/ataque/top-assistencias';
      case 'Finalizadores':
        return '/scouts/ataque/top-finalizacoes-perigosas';
      case 'Desarmes':
        return '/scouts/defesa/top-desarmes';
      case 'Faltas Sofridas':
        return '/scouts/ataque/top-faltas-sofridas';
      case 'Faltas Cometidas':
        return '/scouts/defesa/top-faltas-cometidas';
      case 'Goleiros - Pênaltis Defendidos':
        return '/scouts/goleiros/top-penaltis-defendidos';
      default:
        return '/scouts/ataque/top-gols';
    }
  }

  Future<void> _buscar() async {
    setState(() { loading = true; items = []; });
    try {
      final path = _endpointForTipo(tipoSelecionado);
      final params = <String, String>{'limite': '100'};
      if (usarRodada && (rodada != null)) params['rodada'] = rodada!.toString();
      if (clubeSelecionado != 'Todos') params['clube'] = clubeSelecionado;
      if (posicaoSelecionada != 'Todas') params['posicao'] = posicaoSelecionada;

      final list = await ApiService.fetchByPath(path, params);
      setState(() => items = list);
    } catch (e) {
      setState(() => items = []);
    } finally {
      setState(() => loading = false);
    }
  }

  

  Widget _buildAvatar(Map j) {
    final String urlFoto = (j['foto_url'] ?? j['foto'] ?? '').toString();
    final bool ehSilhueta = urlFoto.contains('FORMATO.png');
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
      child: ClipOval(
        child: ehSilhueta || urlFoto.isEmpty
            ? Icon(Icons.person, color: Colors.grey[400])
            : Image.network(urlFoto, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tops')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: tipoSelecionado,
                            items: tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setState(() { tipoSelecionado = v!; }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _buscar, child: const Text('Atualizar')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(value: usarRodada, onChanged: (v) => setState(() => usarRodada = v ?? false)),
                        const Text('Filtrar por rodada'),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            enabled: usarRodada,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(isDense: true, hintText: rodada?.toString() ?? ''),
                            onChanged: (t) => rodada = int.tryParse(t) ?? rodada,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: posicaoSelecionada,
                            items: posicoes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (v) => setState(() => posicaoSelecionada = v ?? 'Todas'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: clubeSelecionado,
                            items: clubes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => clubeSelecionado = v ?? 'Todos'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? const Center(child: Text('Nenhum resultado'))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final it = items[i] as Map<String, dynamic>;
                            final nome = it['nome'] ?? it['nome_completo'] ?? it['apelido'] ?? '—';
                            final clube = it['clube_nome'] ?? it['clube'] ?? '';
                            final total = it['total'] ?? it['pontuacao_fantasy'] ?? it['media_fantasy'] ?? it['gols_total'];
                            return ListTile(
                              leading: _buildAvatar(it),
                              title: Text(nome.toString()),
                              subtitle: Text(clube.toString()),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(total != null ? total.toString() : '-'),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
