import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DetalheJogadorTela extends StatefulWidget {
  final int jogadorId;
  const DetalheJogadorTela({Key? key, required this.jogadorId}) : super(key: key);

  @override
  State<DetalheJogadorTela> createState() => _DetalheJogadorTelaState();
}

class _DetalheJogadorTelaState extends State<DetalheJogadorTela> {
  Map<String, dynamic>? jogador;
  List<dynamic> rodadas = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      final resultados = await Future.wait([
        ApiService.fetchJogadorDetalhe(widget.jogadorId),
        ApiService.fetchHistoricoJogador(widget.jogadorId, limite: 50),
      ]);

      setState(() {
        jogador = resultados[0] as Map<String, dynamic>;
        rodadas = resultados[1] as List<dynamic>;
        rodadas.sort((a, b) => (b['rodada'] ?? 0).compareTo(a['rodada'] ?? 0));
        loading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar detalhes: $e");
      setState(() {
        errorMessage = 'Falha ao carregar dados do atleta.';
        loading = false;
      });
    }
  }

  double _valueFromRow(Map r) {
    final v = r['pontuacao_fantasy'] ?? r['pontos_oficial'] ?? r['pontos'] ?? r['pontos_num'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  String _formatDouble(dynamic v) {
    if (v is num) return v.toStringAsFixed(2);
    final parsed = double.tryParse(v?.toString() ?? '');
    return parsed != null ? parsed.toStringAsFixed(2) : '0.00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do Jogador')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                ))
              : jogador == null
                  ? const Center(child: Text('Jogador não encontrado'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
                                child: ClipOval(
                                  child: Image.network(
                                    (jogador!['foto_url'] ?? jogador!['foto'] ?? jogador!['foto'] ?? '').toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.person, size: 40, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(jogador!['nome_completo'] ?? jogador!['nome'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('${jogador!['posicao_nome'] ?? jogador!['posicao'] ?? '-'} • ${jogador!['clube_nome'] ?? jogador!['clube'] ?? '-'}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Estatísticas resumidas
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Estatísticas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Média temporada', style: TextStyle(color: Colors.black54)),
                                          Text(_formatDouble(jogador!['media_oficial'] ?? jogador!['media_fantasy'] ?? 0)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Média últimas 5', style: TextStyle(color: Colors.black54)),
                                          Builder(builder: (_) {
                                            final last5 = rodadas.take(5).toList();
                                            if (last5.isEmpty) return const Text('0.00');
                                            final avg = last5.map((r) => _valueFromRow(r)).reduce((a, b) => a + b) / last5.length;
                                            return Text(avg.toStringAsFixed(2));
                                          }),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Pontos', style: TextStyle(color: Colors.black54)),
                                          Builder(builder: (_) {
                                            if (rodadas.isEmpty) return const Text('0.00');
                                            final values = rodadas.map((r) => _valueFromRow(r)).toList();
                                            final mx = values.reduce((a, b) => a > b ? a : b);
                                            return Text('${mx.toStringAsFixed(2)}');
                                          }),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Text('Histórico por rodada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),

                          // Lista de rodadas
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rodadas.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final r = rodadas[i];
                              final pts = _valueFromRow(r);
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Text('${r['rodada'] ?? '-'}')),
                                title: Text('Rodada ${r['rodada'] ?? '-'}'),
                                subtitle: Text((r['partida'] ?? r['opponent'] ?? '').toString()),
                                trailing: Text(
                                  pts.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: pts >= 5 ? Colors.green[700] : (pts < 0 ? Colors.red[700] : Colors.blue),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }
}
