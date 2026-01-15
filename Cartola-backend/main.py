from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import sqlite3
from typing import Optional

app = FastAPI(title="Cartola API temporada 2025")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Função auxiliar para evitar repetição de código
def db_query(query: str, params: tuple = ()):
    conn = sqlite3.connect('cartola.db')
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute(query, params)
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]


# Função genérica para simplificar nas consultas
def get_top_scout(col_rodada: str, col_geral: str, rodada, limite: int, clube: Optional[str], posicao: Optional[str], tabela_especifica: Optional[str] = None):
    tabela = tabela_especifica if (tabela_especifica and not rodada) else ("historico_completo" if rodada else "ranking_geral")
    col = col_rodada if rodada else col_geral

    query = f"SELECT *, {col} as total FROM {tabela} WHERE {col} > 0"
    params = []

    if rodada:
        query += " AND rodada = ?"; params.append(rodada)
    if clube:
        query += f" AND {'clube_nome' if rodada else 'clube'} = ?"; params.append(clube)
    if posicao:
        query += f" AND {'posicao_nome' if rodada else 'posicao'} = ?"; params.append(posicao)

    query += f" ORDER BY {col} DESC LIMIT ?"; params.append(limite)
    return db_query(query, tuple(params))

# busca jogadores com filtros opcionais
@app.get("/jogadores")
def get_jogadores(clube: Optional[str] = None, posicao: Optional[str] = None, nome: Optional[str] = None):
    query = "SELECT * FROM ranking_geral WHERE 1=1"
    params = []
    if clube: query += " AND clube = ?"; params.append(clube)
    if posicao: query += " AND posicao = ?"; params.append(posicao)
    if nome: query += " AND nome LIKE ?"; params.append(f"%{nome}%")
    return db_query(query, tuple(params))

# Endpoint para obter detalhes de um jogador especifico pelo id
@app.get("/jogadores/{id_jogador}")
def get_jogador_id(id_jogador: int):
    res = db_query("SELECT * FROM ranking_geral WHERE id = ?", (id_jogador,))
    if not res: raise HTTPException(status_code=404, detail="Jogador não encontrado")
    return res[0]

# Endpoint para obter o histórico de rodadas de um jogador
@app.get("/jogadores/{id_jogador}/rodadas")
def get_jogador_rodadas(id_jogador: int, limite: int = 5):
    return db_query("SELECT * FROM historico_completo WHERE id = ? ORDER BY rodada DESC LIMIT ?", (id_jogador, limite))


# Endpoint para obter o ranking de uma rodada específica, com filtros opcionais
@app.get("/ranking/rodada")
def get_ranking_rodada(rodada: int, posicao: Optional[str] = None, limite: int = 10):
    query = "SELECT * FROM historico_completo WHERE rodada = ?"
    params = [rodada]
    if posicao: query += " AND posicao_nome = ?"; params.append(posicao)
    query += " ORDER BY pontuacao_fantasy DESC LIMIT ?"; params.append(limite)
    return db_query(query, tuple(params))


# Endpoint para comparar dois jogadores pelo id
@app.get("/comparacao")
def get_comparacao(id1: int, id2: int):
    return db_query("SELECT * FROM ranking_geral WHERE id IN (?, ?)", (id1, id2))


# Endpoint para obter estatísticas de um clube específico
@app.get("/estatisticas/clube/{clube}")
def get_stats_clube(clube: str):
    return db_query("SELECT * FROM ranking_geral WHERE clube = ? ORDER BY media_fantasy DESC", (clube,))

#endpoints para os top scouts melhores em cada categoria
@app.get("/scouts/ataque/top-assistencias")
def top_assistencias(rodada: Optional[int] = None, limite: int = 10, clube: Optional[str] = None, posicao: Optional[str] = None):
    return get_top_scout("A", "assist_total", rodada, limite, clube, posicao)


@app.get("/scouts/defesa/top-desarmes")
def top_desarmes(rodada: Optional[int] = None, limite: int = 10, clube: Optional[str] = None, posicao: Optional[str] = None):
    return get_top_scout("DS", "desarmes_total", rodada, limite, clube, posicao)


@app.get("/scouts/ataque/top-gols")
def top_gols(rodada: Optional[int] = None, limite: int = 10, clube: Optional[str] = None, posicao: Optional[str] = None):
    return get_top_scout("G", "gols_total", rodada, limite, clube, posicao)


@app.get("/scouts/ataque/top-finalizacoes-perigosas")
def top_finalizacoes(rodada: Optional[int] = None, limite: int = 10, clube: Optional[str] = None, posicao: Optional[str] = None):
    return get_top_scout("(FD + FT)", "finalizacoes_perigosas", rodada, limite, clube, posicao, tabela_especifica="top_finalizadores")


@app.get("/scouts/ataque/top-faltas-sofridas")
def top_fs(rodada: Optional[int] = None, limite: int = 10, clube: Optional[str] = None, posicao: Optional[str] = None):
    return get_top_scout("FS", "FS", rodada, limite, clube, posicao)


@app.get("/scouts/defesa/top-faltas-cometidas")
def top_fc(rodada: Optional[int] = None, limite: int = 10, clube: Optional[str] = None, posicao: Optional[str] = None):
    return get_top_scout("FC", "FC", rodada, limite, clube, posicao)


@app.get("/scouts/goleiros/top-defesas-dificeis")
def top_de(rodada: Optional[int] = None, limite: int = 10, clube: Optional[str] = None, posicao: Optional[str] = None):
    pos = posicao if posicao else "Goleiro"
    return get_top_scout("DE", "DE", rodada, limite, clube, pos)


@app.get("/scouts/goleiros/top-penaltis-defendidos")
def top_dp(limite: int = 10, clube: Optional[str] = None, posicao: Optional[str] = None):
    return get_top_scout("DP", "DP", None, limite, clube, posicao)


@app.get("/scouts/defesa/top-jogos-sem-gol")
def top_sg(rodada: Optional[int] = None, limite: int = 10, clube: Optional[str] = None, posicao: Optional[str] = None):
    return get_top_scout("SG", "SG", rodada, limite, clube, posicao)

# dashboard endpoints
# Endpoint para obter a última rodada disponível
@app.get("/rodada/ultima")
def get_ultima_rodada():
    res = db_query("SELECT MAX(rodada) as ultima FROM historico_completo")
    if not res or res[0].get('ultima') is None:
        raise HTTPException(status_code=404, detail="Não foi possível determinar a última rodada")
    return {"ultima_rodada": int(res[0].get('ultima'))}

# Endpoint para obter a lista de clubes disponíveis
@app.get("/clubs")
def get_clubes():
    rows = db_query("SELECT DISTINCT clube as clube FROM ranking_geral")
    return [r.get('clube') for r in rows]