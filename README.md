# 📊 Análise de Dados Públicos com SQL

> Análise exploratória de dados públicos brasileiros utilizando SQL avançado — CTEs, Window Functions, subqueries e geração de insights de negócio a partir de dados reais do IBGE e IPEA.

![SQL](https://img.shields.io/badge/SQL-CC2927?style=flat-square&logo=microsoftsqlserver&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=flat-square&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)

---

## 🎯 Objetivo

Demonstrar habilidades em SQL analítico aplicado a cenários reais de negócio: análise de mercado de trabalho, indicadores econômicos e tendências setoriais, usando dados públicos abertos do Brasil.

---

## 📁 Estrutura do Projeto

```
analise-dados-publicos-sql/
│
├── dados/
│   ├── README_dados.md          # Fonte e descrição dos datasets
│   └── setup_database.sql       # Script para criar e popular o banco
│
├── queries/
│   ├── 01_exploracao_inicial.sql
│   ├── 02_analise_mercado_trabalho.sql
│   ├── 03_ranking_e_comparativos.sql
│   ├── 04_tendencias_temporais.sql
│   └── 05_kpis_negocio.sql
│
├── python/
│   └── carregar_dados.py        # Script para download e carga dos dados
│
└── README.md
```

---

## 📊 Datasets Utilizados

| Dataset | Fonte | Descrição |
|---------|-------|-----------|
| PNADC (Pesquisa Nacional por Amostra de Domicílios) | IBGE | Indicadores de emprego, renda e escolaridade |
| PIB por municípios | IBGE | Produto Interno Bruto municipal |
| IPCA histórico | IPEA | Índice de inflação mensal |
| Empregos formais (CAGED) | MTE | Admissões e desligamentos mensais |

> Todos os dados são públicos e disponíveis nas APIs abertas do IBGE (sidra.ibge.gov.br) e IPEA (ipeadata.gov.br)

---

## 🔍 Análises Desenvolvidas

### 1. Exploração Inicial
- Distribuição de dados por região e período
- Identificação de outliers e valores nulos
- Estatísticas descritivas por categoria

### 2. Mercado de Trabalho
- Taxa de desemprego por estado (ranking)
- Evolução da renda média formal ao longo do tempo
- Setores com maior crescimento de vagas

### 3. Rankings e Comparativos
- Top 10 municípios por PIB per capita
- Comparativo Norte vs Sudeste: emprego formal e renda
- Window functions para ranking dinâmico

### 4. Tendências Temporais
- Análise de sazonalidade no CAGED (admissões por mês)
- Moving average de 3 meses para suavizar ruídos
- YoY (year-over-year) de indicadores-chave

### 5. KPIs de Negócio
- Ticket médio salarial por setor
- Taxa de rotatividade por região
- Índice de formalização do emprego

---

## 💡 Técnicas SQL Utilizadas

```sql
-- Exemplo: Window Function para ranking por estado
SELECT
    estado,
    setor,
    total_empregos,
    RANK() OVER (PARTITION BY estado ORDER BY total_empregos DESC) AS rank_setor,
    SUM(total_empregos) OVER (PARTITION BY estado) AS total_estado,
    ROUND(100.0 * total_empregos / SUM(total_empregos) OVER (PARTITION BY estado), 2) AS pct_participacao
FROM vw_empregos_formais
WHERE ano = 2024;
```

```sql
-- Exemplo: CTE para análise de tendência com Moving Average
WITH base AS (
    SELECT
        ano_mes,
        admissoes,
        desligamentos,
        admissoes - desligamentos AS saldo_mensal
    FROM caged_mensal
    WHERE ano BETWEEN 2022 AND 2024
),
moving_avg AS (
    SELECT
        ano_mes,
        saldo_mensal,
        ROUND(AVG(saldo_mensal) OVER (
            ORDER BY ano_mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 0) AS media_movel_3m
    FROM base
)
SELECT * FROM moving_avg ORDER BY ano_mes;
```

```sql
-- Exemplo: YoY com LAG
SELECT
    ano,
    mes,
    taxa_desemprego,
    LAG(taxa_desemprego, 12) OVER (ORDER BY ano, mes) AS taxa_ano_anterior,
    ROUND(taxa_desemprego - LAG(taxa_desemprego, 12) OVER (ORDER BY ano, mes), 2) AS variacao_pp
FROM pnadc_trimestral
ORDER BY ano, mes;
```

---

## ▶️ Como Executar

```bash
# 1. Clone o repositório
git clone https://github.com/jonathansilvadesa-sys/analise-dados-publicos-sql
cd analise-dados-publicos-sql

# 2. Instale as dependências Python
pip install pandas requests psycopg2-binary python-dotenv

# 3. Configure o banco PostgreSQL e o .env
cp .env.example .env
# Edite .env com suas credenciais

# 4. Baixe e carregue os dados
python python/carregar_dados.py

# 5. Execute as queries na sua IDE favorita
# (DBeaver, Azure Data Studio, pgAdmin, etc.)
```

---

## 📌 Aprendizados e Contexto Profissional

Esta análise reflete o tipo de trabalho que realizei profissionalmente:

- Na **Icatu Seguros**: queries para análise de processos jurídicos, aging e KPIs de honorários
- Na **Ipiranga**: consultas para alimentar dashboards Power BI e análises de performance
- No **Grupo Dupla**: queries para extração e transformação de dados multi-fonte

A diferença é que aqui usamos dados públicos para demonstrar as mesmas técnicas sem expor informações confidenciais.

---

## 📬 Contato

**Jonathan Silva de Sá** · [LinkedIn](https://linkedin.com/in/jonathan-de-sa) · jonathansilvadesa@gmail.com
