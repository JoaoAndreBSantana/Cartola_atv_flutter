import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CompararJogadorTela extends StatefulWidget {
  final Set<int> playerIds;
  const CompararJogadorTela({Key? key, required this.playerIds}) : super(key: key);

  @override
  State<CompararJogadorTela> createState() => _CompararJogadorTelaState();
}

class _CompararJogadorTelaState extends State<CompararJogadorTela> {
  List<dynamic> jogadores = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarDados();
  }

  Future<void> _buscarDados() async {
    setState(() => carregando = true);
    try {
      final ids = widget.playerIds.toList();
      if (ids.length < 2) {
        setState(() {
          jogadores = [];
          carregando = false;
        });
        return;
      }

      final lista = await ApiService.fetchComparacao(ids[0], ids[1]);
      setState(() {
        jogadores = lista;
        carregando = false;
      });
    } catch (e) {
      debugPrint("Erro na comparação: $e");
      setState(() => carregando = false);
    }
  }

  Widget _buildStatRow(String label, String key) {
    if (jogadores.length < 2) return const SizedBox();

    // Busca a chave direta ou a versão com sufixo '_total' (ex: gols_total)
    var v1Raw = jogadores[0][key] ?? jogadores[0]['${key.toLowerCase()}_total'] ?? 0;
    var v2Raw = jogadores[1][key] ?? jogadores[1]['${key.toLowerCase()}_total'] ?? 0;

    double v1 = double.tryParse(v1Raw.toString()) ?? 0.0;
    double v2 = double.tryParse(v2Raw.toString()) ?? 0.0;

    bool j1Vence = v1 > v2;
    bool j2Vence = v2 > v1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildValueBadge(v1, j1Vence),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: LinearProgressIndicator(
                    value: (v1 + v2 == 0) ? 0.5 : v1 / (v1 + v2),
                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                    color: Colors.blueAccent,
                    minHeight: 6,
                  ),
                ),
              ),
              _buildValueBadge(v2, j2Vence),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueBadge(double val, bool vence) {
    return Container(
      width: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: vence ? Colors.green : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: vence ? Colors.green : Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1),
          style: TextStyle(fontWeight: FontWeight.bold, color: vence ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Duelo de Atletas")),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    children: [
                      _buildStatRow("GOLS", "G"),
                      _buildStatRow("ASSISTÊNCIAS", "A"),
                      _buildStatRow("DESARMES", "DS"),
                      _buildStatRow("FALTAS SOFRIDAS", "FS"),
                      _buildStatRow("PREÇO", "preco"),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _playerAvatar(jogadores[0]),
          const Text("VS", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
          _playerAvatar(jogadores[1]),
        ],
      ),
    );
  }

  Widget _playerAvatar(dynamic j) {
    String url = j['foto_url'] ?? '';
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          // Se a URL for vazia, mostra ícone para não dar erro de "No host specified"
          backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
          child: url.isEmpty ? const Icon(Icons.person) : null,
        ),
        const SizedBox(height: 5),
        Text(j['nome'] ?? '?', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)),
        child: const Text("FECHAR", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}