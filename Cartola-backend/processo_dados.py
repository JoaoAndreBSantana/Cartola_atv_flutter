import pandas as pd
import sqlite3

# caminho dos dados
BASE_URL = "https://raw.githubusercontent.com/henriquepgomide/caRtola/master/data/01_raw/2025/"

#crio uma lista vazia para guardar cada tabela de cada rodada
tabelas_por_rodada = []

print("Iniciando o carregamento dos dados das rodadas de 2025...")

#Loop para carregar os dados de todas as 38 rodadas
for rodada in range(1, 39):
    try:
        url = f"{BASE_URL}rodada-{rodada}.csv"
        df_rodada = pd.read_csv(url)
        tabelas_por_rodada.append(df_rodada)
        print(f"Rodada {rodada} carregada com sucesso.")
    except Exception as e:
        print(f"Aviso: Não foi possível carregar a rodada {rodada}. Erro: {e}")

#concatena todas as rodadas em um unico dataFrame
if tabelas_por_rodada:
    df_scouts_2025 = pd.concat(tabelas_por_rodada, ignore_index=True)
    print("\n Todos os dados das rodadas foram consolidados.")
else:
    print("\n Nenhum dado foi carregado. Verifique a URL e sua conexão.")
    exit() # Encerra o script se não houver dados


# Definimos o dicionário de pesos
pesos = {
    'G': 8.0, 'A': 5.0, 'FT': 3.0, 'FD': 1.2, 'FF': 0.8, 'FS': 0.5, 'PS': 1.0, 
    'DS': 1.2, 'SG': 5.0, 'DE': 1.0, 'DP': 7.0, 'GC': -3.0, 'CV': -3.0,      
    'CA': -1.0, 'GS': -1.0, 'FC': -0.3, 'PC': -1.0, 'I': -0.1, 'PP': -4.0    
}

# tratamento de nulos
df_analise = df_scouts_2025.copy()
scouts_colunas = list(pesos.keys())
df_analise[scouts_colunas] = df_analise[scouts_colunas].fillna(0)

# normalizar os nomes das colunas
colunas_renomear = {
    'atletas.atleta_id': 'id',
    'atletas.apelido': 'nome',
    'atletas.nome': 'nome_completo',
    'atletas.foto': 'foto_url',
    'atletas.clube_id': 'clube_id',
    'atletas.clube.id.full.name': 'clube_nome',
    'atletas.posicao_id': 'posicao_id',
    'atletas.rodada_id': 'rodada',
    'atletas.status_id': 'status_id',
    'atletas.pontos_num': 'pontos_oficial',
    'atletas.media_num': 'media_oficial',
    'atletas.preco_num': 'preco',
    'atletas.variacao_num': 'variacao_preco',
    'atletas.minimo_para_valorizar': 'minimo_valorizar',
    'atletas.jogos_num': 'jogos_acumulados'
}
df_analise = df_analise.rename(columns=colunas_renomear)


mapa_posicoes = {
    1: 'Goleiro', 2: 'Lateral', 3: 'Zagueiro',
    4: 'Meia', 5: 'Atacante', 6: 'Técnico'
}
df_analise['posicao_nome'] = df_analise['posicao_id'].map(mapa_posicoes)

print(" Normalização Completa: Colunas renomeadas e prontas para o App.")

# agrupo os scouts por categoria conforme a regra de negocio
scouts_ataque = ['G', 'A', 'FT', 'FD', 'FF', 'FS', 'PS']
scouts_defesa = ['DS', 'SG', 'DE', 'DP']
scouts_penalidades = ['GC', 'CV', 'CA', 'GS', 'FC', 'PC', 'I', 'PP']

# funçoes de cálculo para cada categoria
def calc_ataque(row):
    return sum(row[s] * pesos[s] for s in scouts_ataque if s in row)

def calc_defesa(row):
    return sum(row[s] * pesos[s] for s in scouts_defesa if s in row)

def calc_penalidades(row):
    return sum(row[s] * pesos[s] for s in scouts_penalidades if s in row)

# calculos para criar colunas específicas no dataframe
df_analise['pontos_ataque'] = df_analise.apply(calc_ataque, axis=1)
df_analise['pontos_defesa'] = df_analise.apply(calc_defesa, axis=1)
df_analise['pontos_penalidades'] = df_analise.apply(calc_penalidades, axis=1)

# pontuação fantasy total é a soma das 3 categorias
df_analise['pontuacao_fantasy'] = (
    df_analise['pontos_ataque'] +
    df_analise['pontos_defesa'] +
    df_analise['pontos_penalidades']
).round(2)

print(" Métricas Segmentadas calculadas: Ataque, Defesa e Penalidades separadas.")

# agrupamento Consolidado etc
df_temporada = df_analise.groupby(['id', 'nome', 'posicao_nome', 'clube_nome']).agg({
    'foto_url': 'first',
    'pontuacao_fantasy': 'sum',
    'pontos_ataque': 'mean',
    'pontos_defesa': 'mean',
    'pontos_penalidades': 'mean',
    'G': 'max',   
    'A': 'max',   
    'DS': 'max', 
    'FT': 'max', 'FD': 'max', 'FF': 'max', 'FS': 'max', 'PS': 'max',
    'SG': 'max', 'DE': 'max', 'DP': 'max', 'GC': 'max', 'CV': 'max',
    'CA': 'max', 'GS': 'max', 'FC': 'max', 'PC': 'max', 'I': 'max', 'PP': 'max',
    'rodada': 'count',
    'preco': 'last',
    'variacao_preco': 'sum'
}).reset_index()

# outras renomeações para o padrao do app, fiz isso depois do groupby para evitar conflitos
df_temporada = df_temporada.rename(columns={
    'posicao_nome': 'posicao',
    'clube_nome': 'clube',
    'foto_url': 'foto',
    'pontuacao_fantasy': 'total_pontos',
    'rodada': 'jogos',
    'variacao_preco': 'valorizacao',
    'G': 'gols_total',
    'A': 'assist_total',
    'DS': 'desarmes_total',
    'pontos_defesa': 'media_defesa',   
    'pontos_ataque': 'media_ataque',
    'pontos_penalidades': 'media_penalidades'
})


#as siglas curtas para gols, assistencias e desarmes
df_temporada['G'] = df_temporada.get('gols_total', 0)
df_temporada['A'] = df_temporada.get('assist_total', 0)
df_temporada['DS'] = df_temporada.get('desarmes_total', 0)

# Cálculo da Média Fantasy Real
df_temporada['media_fantasy'] = (df_temporada['total_pontos'] / df_temporada['jogos']).round(2)

#arredondamento para 2 casas decimais
df_temporada = df_temporada.round(2)

# ordenacao de mediafantasy
df_temporada = df_temporada.sort_values(by='media_fantasy', ascending=False)

print(" Métricas Agregadas da Temporada 2025 concluídas.")


# Ordenado por média fantasy decrescente
df_ranking_geral = df_temporada.sort_values(by='media_fantasy', ascending=False)


#dataframe dos maiores artilheiros da temporada
df_artilheiros = df_temporada.sort_values(by='gols_total', ascending=False).head(20)


# dataframe dos melhores defensores 
df_melhores_defesa = df_temporada[
    df_temporada['posicao'].isin(['Goleiro', 'Zagueiro', 'Lateral'])
].sort_values(by='media_defesa', ascending=False).head(20)


# dataframe dos jogadores com média fantasy 
df_bons_baratos = df_temporada[
    (df_temporada['media_fantasy'] > 5) & (df_temporada['preco'] < 10)
].sort_values(by='media_fantasy', ascending=False)

#jogadores com mais jogos realizados
df_mais_jogados = df_temporada.sort_values(by='jogos', ascending=False).head(30)

# Jogadores com as menores médias 
df_menores_notas = df_temporada[df_temporada['jogos'] >= 3].sort_values(by='media_fantasy', ascending=True).head(20)


# jogadores mais indisciplinados
df_mais_indisciplinados = df_temporada.sort_values(by='media_penalidades', ascending=True).head(20)


#finalizadores perrigosos
df_finalizadores = df_analise.groupby(['id', 'nome', 'clube_nome']).agg({
    'FD': 'sum',
    'FT': 'sum'
}).reset_index()
df_finalizadores['finalizacoes_perigosas'] = df_finalizadores['FD'] + df_finalizadores['FT']
df_finalizadores = df_finalizadores.sort_values(by='finalizacoes_perigosas', ascending=False).head(20)


#melhores goleiros
df_paredoes = df_temporada[df_temporada['posicao'] == 'Goleiro'].sort_values(by='media_defesa', ascending=False).head(15)


#garçons
df_garcons = df_temporada.sort_values(by='assist_total', ascending=False).head(20)


# DataFrame da última forma (última rodada)
ultima_rodada = df_analise['rodada'].max()
df_ultima_forma = df_analise[df_analise['rodada'] == ultima_rodada][['id', 'nome', 'pontuacao_fantasy', 'rodada']]

print("Todos os DataFrames para o banco de dados foram criados")

#salvamento no banco de dados sqlite

conn = sqlite3.connect('cartola.db')
print("\nConectado ao banco de dados 'cartola.db'.")
#salva o DataFrame completo do historico como uma tabela
df_analise.to_sql('historico_completo', conn, if_exists='replace', index=False)

# Salva os DataFrames principais como tabelas no banco de dados

df_ranking_geral.to_sql('ranking_geral', conn, if_exists='replace', index=False)
df_artilheiros.to_sql('artilheiros', conn, if_exists='replace', index=False)
df_melhores_defesa.to_sql('melhores_defesa', conn, if_exists='replace', index=False)
df_bons_baratos.to_sql('bons_baratos', conn, if_exists='replace', index=False)
df_mais_jogados.to_sql('mais_jogados', conn, if_exists='replace', index=False)
df_menores_notas.to_sql('menores_notas', conn, if_exists='replace', index=False)
df_mais_indisciplinados.to_sql('mais_indisciplinados', conn, if_exists='replace', index=False)
df_finalizadores.to_sql('top_finalizadores', conn, if_exists='replace', index=False)
df_paredoes.to_sql('melhores_goleiros', conn, if_exists='replace', index=False)
df_garcons.to_sql('garcons', conn, if_exists='replace', index=False)
df_ultima_forma.to_sql('ultima_forma', conn, if_exists='replace', index=False)

print("Tabelas de ranking e histórico salvos.")

# Salva os DataFrames de cada posição
posicoes = df_temporada['posicao'].unique()
for pos in posicoes:
    # Ignora valores nulos
    if pd.isna(pos):
        continue
    df_pos = df_temporada[df_temporada['posicao'] == pos].sort_values(by='media_fantasy', ascending=False)
    
    table_name = f"posicao_{pos.lower().replace(' ', '_')}"
    df_pos.to_sql(table_name, conn, if_exists='replace', index=False)
    print(f"Tabela '{table_name}' salva.")

# Fecha a conexão com o banco de dados
conn.close()
conn.close()

print("\nBanco de dados 'cartola.db' foi criado/atualizado com sucesso! (Inclui histórico_completo e fotos)")