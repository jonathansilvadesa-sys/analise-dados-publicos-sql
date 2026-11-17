-- ============================================================
-- ANÁLISE DE MERCADO DE TRABALHO — CAGED
-- Autor: Jonathan Silva de Sá
-- Fonte dos dados: Ministério do Trabalho (Novo CAGED)
-- Dialeto: PostgreSQL
--
-- Tabela esperada: caged_mensal (dados já agregados), com as colunas
--   ano, mes, uf, nome_estado, setor_atividade, grau_instrucao,
--   admissoes, desligamentos, salario_medio
-- Cada linha = um grupo (UF × setor × grau de instrução × mês),
-- com o salário médio de admissão daquele grupo.
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- 1. SALDO DE EMPREGOS FORMAIS POR SETOR (2023-2024)
-- saldo_pct_desligamentos = saldo ÷ desligamentos
-- (quantos empregos líquidos o setor criou para cada 100 desligamentos)
-- ────────────────────────────────────────────────────────────
SELECT
    setor_atividade,
    SUM(admissoes)                          AS total_admissoes,
    SUM(desligamentos)                      AS total_desligamentos,
    SUM(admissoes) - SUM(desligamentos)     AS saldo_total,
    ROUND(
        100.0 * (SUM(admissoes) - SUM(desligamentos)) / NULLIF(SUM(desligamentos), 0),
        2
    )                                       AS saldo_pct_desligamentos
FROM caged_mensal
WHERE ano BETWEEN 2023 AND 2024
GROUP BY setor_atividade
ORDER BY saldo_total DESC;


-- ────────────────────────────────────────────────────────────
-- 2. TOP 5 ESTADOS COM MAIOR GERAÇÃO DE EMPREGOS (2024)
-- O total do Brasil é calculado na CTE, ANTES do filtro de top 5.
-- (WHERE roda antes das window functions do SELECT: se o total
--  fosse calculado depois do filtro, somaria só os 5 estados.)
-- ────────────────────────────────────────────────────────────
WITH saldo_por_estado AS (
    SELECT
        uf,
        nome_estado,
        SUM(admissoes - desligamentos)                               AS saldo_ano,
        SUM(SUM(admissoes - desligamentos)) OVER ()                  AS total_brasil,
        RANK() OVER (ORDER BY SUM(admissoes - desligamentos) DESC)   AS posicao
    FROM caged_mensal
    WHERE ano = 2024
    GROUP BY uf, nome_estado
)
SELECT
    posicao,
    nome_estado,
    uf,
    saldo_ano,
    total_brasil,
    ROUND(100.0 * saldo_ano / NULLIF(total_brasil, 0), 2)           AS pct_participacao
FROM saldo_por_estado
WHERE posicao <= 5
ORDER BY posicao;


-- ────────────────────────────────────────────────────────────
-- 3. EVOLUÇÃO MENSAL COM MÉDIA MÓVEL (3 MESES)
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
-- 4. SALÁRIO DE ADMISSÃO POR GRAU DE INSTRUÇÃO (2024)
-- Média PONDERADA pelo número de admissões: cada linha da tabela
-- já é uma média de um grupo, e grupos têm tamanhos diferentes.
-- Uma média simples daria o mesmo peso a 3 e a 3.000 admissões.
-- ────────────────────────────────────────────────────────────
WITH por_instrucao AS (
    SELECT
        grau_instrucao,
        SUM(admissoes)                                              AS qtd_admissoes,
        SUM(salario_medio * admissoes) / NULLIF(SUM(admissoes), 0)  AS salario_medio_ponderado,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salario_medio)  AS mediana_entre_grupos,
        MIN(salario_medio)                                          AS menor_media_de_grupo,
        MAX(salario_medio)                                          AS maior_media_de_grupo
    FROM caged_mensal
    WHERE ano = 2024
      AND salario_medio > 0
      AND admissoes > 0
    GROUP BY grau_instrucao
)
SELECT
    grau_instrucao,
    qtd_admissoes,
    ROUND(salario_medio_ponderado::NUMERIC, 2)                      AS salario_medio_ponderado,
    ROUND(mediana_entre_grupos::NUMERIC, 2)                         AS mediana_entre_grupos,
    ROUND(menor_media_de_grupo::NUMERIC, 2)                         AS menor_media_de_grupo,
    ROUND(maior_media_de_grupo::NUMERIC, 2)                         AS maior_media_de_grupo,
    ROUND((salario_medio_ponderado
           / MIN(salario_medio_ponderado) OVER ())::NUMERIC, 2)     AS multiplicador_vs_menor
FROM por_instrucao
ORDER BY salario_medio_ponderado DESC;


-- ────────────────────────────────────────────────────────────
-- 5. RAZÃO DESLIGAMENTOS / ADMISSÕES POR SETOR (2024)
-- Acima de 100 = o setor desligou mais do que contratou.
--
-- Por que não "taxa de rotatividade": a rotatividade de verdade
-- divide pelo ESTOQUE de vínculos ativos (dado da RAIS), que esta
-- tabela não tem. (Admissões + desligamentos) ÷ 2 não é estoque.
-- ────────────────────────────────────────────────────────────
WITH por_setor AS (
    SELECT
        setor_atividade,
        SUM(admissoes)                                                   AS admissoes,
        SUM(desligamentos)                                               AS desligamentos,
        ROUND(100.0 * SUM(desligamentos) / NULLIF(SUM(admissoes), 0), 2) AS razao_deslig_admissoes_pct
    FROM caged_mensal
    WHERE ano = 2024
    GROUP BY setor_atividade
)
SELECT
    setor_atividade,
    admissoes,
    desligamentos,
    razao_deslig_admissoes_pct,
    RANK() OVER (ORDER BY razao_deslig_admissoes_pct DESC NULLS LAST) AS ranking
FROM por_setor
ORDER BY ranking;
