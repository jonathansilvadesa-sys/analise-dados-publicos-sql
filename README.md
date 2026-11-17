# 📊 Análise de Dados Públicos com SQL

> Consultas analíticas sobre o mercado de trabalho formal brasileiro (Novo CAGED), usando CTEs, window functions e percentis em PostgreSQL.

![SQL](https://img.shields.io/badge/SQL-CC2927?style=flat-square&logo=microsoftsqlserver&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=flat-square&logo=postgresql&logoColor=white)

---

## 🎯 Objetivo

Responder perguntas de negócio sobre emprego formal com SQL analítico: onde e em quais setores se gera emprego, como o saldo evolui mês a mês e quanto a escolaridade pesa no salário de admissão.

---

## 📁 Estrutura

```
analise-dados-publicos-sql/
├── queries/
│   └── 02_analise_mercado_trabalho.sql   # 5 consultas comentadas
└── README.md
```

---

## 🔍 Consultas

| # | Pergunta de negócio | Técnicas |
|---|---------------------|----------|
| 1 | Quais setores mais geraram emprego em 2023–2024? | `GROUP BY`, `NULLIF` contra divisão por zero |
| 2 | Quais os 5 estados com maior saldo em 2024 e quanto representam do total do Brasil? | CTE, `RANK()`, `SUM() OVER ()` calculado antes do filtro |
| 3 | Como o saldo evoluiu mês a mês? | Média móvel de 3 meses (`ROWS BETWEEN`), acumulado no ano (`PARTITION BY`) |
| 4 | Quanto ganha, na admissão, cada grau de instrução? | Média ponderada, mediana com `PERCENTILE_CONT` |
| 5 | Quais setores desligam mais do que contratam? | CTE + `RANK()` com `NULLS LAST` |

### Exemplo — média móvel e acumulado no ano

```sql
SELECT
    TO_CHAR(competencia, 'YYYY-MM')  AS mes_referencia,
    saldo,
    ROUND(AVG(saldo) OVER (
        ORDER BY competencia
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 0)                            AS media_movel_3m,
    SUM(saldo) OVER (
        PARTITION BY EXTRACT(YEAR FROM competencia)
        ORDER BY competencia
    )                                AS saldo_acumulado_ano
FROM base
ORDER BY competencia;
```

---

## 💡 Decisões de análise

- **Total do Brasil antes do filtro (consulta 2).** O `WHERE` roda antes das window functions do `SELECT`. Por isso o total nacional é calculado dentro da CTE; calculado depois do filtro, somaria só os 5 estados do topo.
- **Média ponderada (consulta 4).** Cada linha da tabela já é a média de um grupo. Uma média simples daria o mesmo peso a um grupo com 3 admissões e a outro com 3.000, então o salário é ponderado pelo número de admissões.
- **Por que não "taxa de rotatividade" (consulta 5).** Rotatividade se calcula sobre o estoque de vínculos ativos, que vem da RAIS e não está no CAGED. A consulta mede a razão entre desligamentos e admissões, que o CAGED permite calcular.

---

## ▶️ Como usar

As consultas esperam uma tabela `caged_mensal` em PostgreSQL, já agregada a partir dos microdados do [Novo CAGED](https://www.gov.br/trabalho-e-emprego/pt-br/acesso-a-informacao/acoes-e-programas/programas-projetos-acoes-obras-e-atividades/estatisticas-trabalho/microdados-rais-e-caged):

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| ano, mes | int | Competência |
| uf, nome_estado | text | Unidade da federação |
| setor_atividade | text | Seção da CNAE |
| grau_instrucao | text | Escolaridade |
| admissoes, desligamentos | int | Movimentações no grupo |
| salario_medio | numeric | Salário médio de admissão do grupo |

---

## 🚧 Próximos passos

- Script em Python para baixar os microdados e montar a tabela `caged_mensal`
- Consultas de exploração inicial e de tendências (sazonalidade, comparação ano contra ano)
- Seção de resultados com os números reais

---

## 📌 Contexto profissional

O mesmo tipo de SQL que usei no trabalho, aplicado a dados públicos para não expor informações confidenciais:

- **Icatu Seguros:** consultas para análise de processos jurídicos, aging e KPIs de honorários
- **Ipiranga:** consultas para alimentar dashboards Power BI e análises de performance
- **Grupo Dupla:** extração e transformação de dados de múltiplas fontes

---

## 📬 Contato

**Jonathan Silva de Sá** · [LinkedIn](https://linkedin.com/in/jonathan-de-sa) · jonathansilvadesa@gmail.com
