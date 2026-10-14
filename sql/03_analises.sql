-- P1: Por que o Over 90 da carteira piorou?
-- P2: Qual produto/modalidade está puxando o LA das safras recentes para baixo?


-- =============================================================================
-- 2.1 VISÃO GERAL DA CARTEIRA
-- =============================================================================

-- Q1. Evolução do estoque: a carteira está crescendo ou encolhendo?
SELECT
    mesref,
    SUM(qt_contratos)    AS qt_contratos,
    ROUND(SUM(saldo), 2) AS saldo_total
FROM fato_carteira
GROUP BY mesref
ORDER BY mesref;


-- =============================================================================
-- 2.2 P1 — OVER 90 DA CARTEIRA
-- Over 90 Carteira = saldo Over90 / saldo total da foto
-- =============================================================================

-- Q3. Over 90 da carteira total, mês a mês (+ variação vs mês anterior)
WITH over90_mes AS (
    SELECT
        mesref,
        SUM(CASE WHEN fx_atraso = '> 90' THEN saldo ELSE 0 END) AS saldo_over90,
        SUM(saldo)                                           AS saldo_total
    FROM fato_carteira
    GROUP BY mesref
)
SELECT
    mesref,
    ROUND(saldo_over90 / NULLIF(saldo_total, 0), 4) AS over90,
    ROUND(saldo_over90 / NULLIF(saldo_total, 0)
        - LAG(saldo_over90 / NULLIF(saldo_total, 0)) OVER (ORDER BY mesref), 4)        AS var_mes_anterior
FROM over90_mes
ORDER BY mesref;


-- Q4. Over 90 por subproduto, mês a mês: algum produto piorou a própria taxa?
SELECT
    f.mesref,
    d.nm_subproduto,
    ROUND(SUM(CASE WHEN f.fx_atraso = '> 90' THEN f.saldo ELSE 0 END)
          / NULLIF(SUM(f.saldo), 0), 4) AS over90
FROM fato_carteira f
JOIN dim_produto d ON d.cd_produto = f.cd_produto
GROUP BY f.mesref, d.nm_subproduto
ORDER BY d.nm_subproduto, f.mesref;


-- Q5. MIX x TAXA: a piora veio de taxa (produto piorou) ou de mix (produto
--     arriscado ganhou peso)? Compara um período inicial com o mais recente.
WITH base AS (
    SELECT
        f.mesref,
        d.nm_subproduto,
        SUM(CASE WHEN f.fx_atraso = '> 90' THEN f.saldo ELSE 0 END) AS saldo_over90,
        SUM(f.saldo)                                                AS saldo
    FROM fato_carteira f
    JOIN dim_produto d ON d.cd_produto = f.cd_produto
    WHERE f.mesref IN ('2025-10', '2026-04')          -- escolha 2 meses para comparar
    GROUP BY f.mesref, d.nm_subproduto
)
SELECT
    mesref,
    nm_subproduto,
    ROUND(saldo / SUM(saldo) OVER (PARTITION BY mesref), 4) AS pct_carteira,
    ROUND(saldo_over90 / NULLIF(saldo, 0), 4)                          AS over90
FROM base
ORDER BY nm_subproduto, mesref;


-- =============================================================================
-- 2.3 P2 — LA DAS SAFRAS
-- LA = (Receita - Custo) / PDD
-- Over 90 Safra = bruto Over90 / bruto do MOB 0 da safra
-- Regra de ouro: comparar safras NO MESMO MOB.
-- =============================================================================

-- Q6. LA por safra e subproduto, acumulado até um MOB fixo (comparação justa)
SELECT
    f.safra,
    d.nm_subproduto,
    ROUND((SUM(f.receita_credito) - SUM(f.custo_captacao)) / NULLIF(SUM(f.despesas_pdd), 0), 4) AS la
FROM fato_carteira f
JOIN dim_produto d ON d.cd_produto = f.cd_produto
WHERE f.mob <= 3
GROUP BY f.safra, d.nm_subproduto
HAVING COUNT(DISTINCT f.mob) = 4
ORDER BY d.nm_subproduto, f.safra;


-- Q7. Over 90 Safra por MOB (curva de safra)
WITH bruto_mob0 AS (
    SELECT safra, cd_produto, SUM(bruto) AS bruto_mob0
    FROM fato_carteira
    WHERE mob = 0
    GROUP BY safra, cd_produto
),
bruto_over90 AS (
    SELECT safra, cd_produto, mob, SUM(bruto) AS bruto_over90
    FROM fato_carteira
    WHERE fx_atraso = '> 90'
    GROUP BY safra, cd_produto, mob
)
SELECT
    o.safra,
    d.nm_subproduto,
    o.mob,
    ROUND(o.bruto_over90 / NULLIF(m.bruto_mob0, 0), 4) AS over90_safra
FROM bruto_over90 o
JOIN bruto_mob0  m ON m.safra = o.safra AND m.cd_produto = o.cd_produto
JOIN dim_produto d ON d.cd_produto = o.cd_produto
ORDER BY d.nm_subproduto, o.safra, o.mob;



