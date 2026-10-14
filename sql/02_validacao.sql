SELECT 'dim_produto' AS tabela, COUNT(*) AS qt_banco, 4 AS qt_csv
FROM dim_produto
UNION ALL
SELECT 'fato_carteira', COUNT(*), 30580
FROM fato_carteira;

SELECT
    'saldo'           AS coluna, ROUND(SUM(saldo), 2)           AS total_banco, 17403426924.56 AS total_csv FROM fato_carteira
UNION ALL SELECT
    'bruto',                     ROUND(SUM(bruto), 2),                          55990510638.96              FROM fato_carteira
UNION ALL SELECT
    'receita_credito',           ROUND(SUM(receita_credito), 2),                3073785804.01               FROM fato_carteira
UNION ALL SELECT
    'custo_captacao',            ROUND(SUM(custo_captacao), 2),                 286239715.52                FROM fato_carteira
UNION ALL SELECT
    'despesas_pdd',              ROUND(SUM(despesas_pdd), 2),                   1830407954.14               FROM fato_carteira;

SELECT f.cd_produto, COUNT(*) AS qt_linhas_orfas
FROM fato_carteira f
LEFT JOIN dim_produto d ON d.cd_produto = f.cd_produto
WHERE d.cd_produto IS NULL
GROUP BY f.cd_produto;

SELECT d.cd_produto, d.nm_subproduto
FROM dim_produto d
LEFT JOIN fato_carteira f ON f.cd_produto = d.cd_produto
WHERE f.cd_produto IS NULL;

SELECT COUNT(*) AS qt_mob_inconsistente
FROM fato_carteira
WHERE mob <> (CAST(substr(mesref, 1, 4) AS INTEGER) * 12 + CAST(substr(mesref, 6, 2) AS INTEGER))
           - (CAST(substr(safra, 1, 4) AS INTEGER) * 12 + CAST(substr(safra, 6, 2) AS INTEGER));

SELECT fx_atraso, COUNT(*) AS qt_linhas
FROM fato_carteira
GROUP BY fx_atraso
ORDER BY fx_atraso;
