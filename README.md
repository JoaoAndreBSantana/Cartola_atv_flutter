Cartola App

Projeto dividido em duas partes: um backend Python que prepara e expõe dados, e um frontend Flutter que consome esses dados para mostrar estatísticas do Cartola (temporada 2025).

O que utiliza
- Backend: Python, FastAPI e SQLite para servir os dados; um script de processamento usa bibliotecas de análise (ex.: pandas) para transformar dados brutos em tabelas prontas para consulta.
- Frontend: Flutter (Dart) que consome a API HTTP e exibe telas de lista, detalhes, comparação e rankings.
- Dados: fontes públicas em JSON são normalizadas e agregadas em tabelas como `historico_completo` e `ranking_geral`.

Como funciona
- Coleta e normalização: um script baixa dados brutos, renomeia e limpa colunas, mapeia posições e trata valores ausentes.
- Cálculo de métricas: a partir dos scouts por rodada são aplicados pesos e regras para calcular pontuações por categoria (ataque, defesa, penalidades) e a pontuação fantasy total; essas métricas são agregadas por jogador ao longo da temporada.
- Persistência: os resultados são gravados em um banco SQLite com tabelas que representam o histórico por rodada e o ranking consolidado da temporada.
- API: o backend lê o banco e expõe endpoints simples para listar jogadores, obter detalhes e histórico por rodada, comparar jogadores, retornar tops por scout e fornecer a última rodada disponível.
- Frontend: consulta a API e apresenta as informações em telas como Mercado (lista filtrável), Detalhe do Jogador, Comparar Jogadores, Dashboard e Rankings/Tops.

Visão resumida das responsabilidades
- `processo_dados.py`: transforma os dados brutos em tabelas analíticas e calcula métricas agregadas.
- `Cartola-backend/main.py`: camada de API que consulta o SQLite e entrega JSON para o app.
- `Cartola-frontend/lib`: interface do usuário que consome os endpoints e monta a experiência (filtros, listagens, comparações).

Extensibilidade
- A arquitetura é simples e modular: novos endpoints, métricas ou visualizações podem ser adicionados sem alterar toda a estrutura; o pipeline de dados pode ser ajustado para suportar novas fontes ou regras de cálculo.


