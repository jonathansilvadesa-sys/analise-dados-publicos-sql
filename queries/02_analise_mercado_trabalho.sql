-- ============================================================
-- ANÁLISE DE MERCADO DE TRABALHO — CAGED + PNADC
-- Autor: Jonathan Silva de Sá
-- Fonte dos dados: Ministério do Trabalho (CAGED) / IBGE (PNADC)
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. SALDO DE EMPREGOS FORMAIS POR SETOR (2023-2024)
-- ────────────────────────────────────────────────────────────
SELECT
    setor_atividade,
    SUM(admissoes)                          AS total_admissoes,
    SUM(desligamentos)                      AS total_desligamentos,
    SUM(admissoes) - SUM(desligamentos)     AS saldo_total,
    ROUND(
        100.0 * (SUM(admissoes) - SUM(desligamentos)) / NULLIF(SUM(desligamentos), 0),
        2
    )                                       AS variacao_pct
FROM caged_mensal
WHERE ano BETWEEN 2023 AND 2024
GROUP BY setor_atividade
ORDER BY saldo_total DESC;


-- ────────────────────────────────────────────────────────────
-- 2. TOP 5 ESTADOS COM MAIOR GERAÇÃO DE EMPREGOS (YTD 2024)
-- ────────────────────────────────────────────────────────────
WITH ranking_estados AS (
    SELECT
        uf,
        nome_estado,
        SUM(admissoes - desligamentos)      AS saldo_ytd,
        RANK() OVER (ORDER BY SUM(admissoes - desligamentos) DESC) AS posicao
    FROM caged_mensal
    WHERE ano = 2024
    GROUP BY uf, nome_estado
)
SELECT
    posicao,
    nome_estado,
    uf,
    saldo_ytd,
    SUM(saldo_ytd) OVER ()                  AS total_brasil,
    ROUND(100.0 * saldo_ytd / SUM(saldo_ytd) OVER (), 2) AS pct_participacao
FROM ranking_estados
WHERE posicao <= 5
ORDER BY posicao;


-- ────────────────────────────────────────────────────────────
-- 3. EVOLUÇÃO MENSAL COM MOVING AVERAGE (3 MESES)
-- ────────────────────────────────────────────────────────────
WITH base AS (
    SELECT
        MAKE_DATE(ano, mes, 1)              AS competencia,
        SUM(admissoes)                      AS admissoes,
        SUM(desligamentos)                  AS desligamentos,
        SUM(admissoes - desligamentos)      AS saldo
    FROM caged_mensal
    WHERE ano BETWEEN 2022 AND 2024
    GROUP BY ano, mes
)
SELECT
    TO_CHAR(competencia, 'YYYY-MM')         AS mes_referencia,
    admissoes,
    desligamentos,
    saldo,
    ROUND(AVG(saldo) OVER (
        ORDER BY competencia
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 0)                                   AS media_movel_3m,
    SUM(saldo) OVER (
        PARTITION BY EXTRACT(YEAR FROM competencia)
        ORDER BY competencia
    )                                       AS saldo_acumulado_ano
FROM base
ORDER BY competencia;


-- ────────────────────────────────────────────────────────────
-- 4. COMPARATIVO RENDA MÉDIA POR GRAU DE INSTRUÇÃO
-- ────────────────────────────────────────────────────────────
SELECT
    grau_instrucao,
    COUNT(*)                                AS qtd_trabalhadores,
    ROUND(AVG(salario_medio), 2)            AS salario_medio,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salario_medio), 2) AS mediana_salario,
    ROUND(MIN(salario_medio), 2)            AS salario_minimo,
    ROUND(MAX(salario_medio), 2)            AS salario_maximo,
    ROUND(AVG(salario_medio) / MIN(AVG(salario_medio)) OVER (), 2) AS multiplicador_vs_menor
FROM caged_mensal
WHERE ano = 2024
  AND salario_medio > 0
GROUP BY grau_instrucao
ORDER BY salario_medio DESC;


-- ────────────────────────────────────────────────────────────
-- 5. TAXA DE ROTATIVIDADE POR SETOR
-- (Rotatividade = desligamentos / ((admissões + saldo)/2) * 100)
-- ────────────────────────────────────────────────────────────
SELECT
    setor_atividade,
    SUM(admissoes)                          AS admissoes,
    SUM(desligamentos)                      AS desligamentos,
    SUM(admissoes + desligamentos) / 2      AS estoque_medio,
    ROUND(
        100.0 * SUM(desligamentos) /
        NULLIF((SUM(admissoes) + SUM(desligamentos)) / 2, 0),
        2
    )                                       AS taxa_rotatividade_pct,
    RANK() OVER (
        ORDER BY
            100.0 * SUM(desligamentos) /
            NULLIF((SUM(admissoes) + SUM(desligamentos)) / 2, 0) DESC
    )                                       AS ranking_rotatividade
FROM caged_mensal
WHERE ano = 2024
GROUP BY setor_atividade
ORDER BY taxa_rotatividade_pct DESC;
