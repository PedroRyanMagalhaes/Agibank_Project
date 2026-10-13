PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS fato_carteira;
DROP TABLE IF EXISTS dim_produto;

CREATE TABLE dim_produto (
    cd_produto INTEGER PRIMARY KEY,
    nm_produto TEXT NOT NULL,
    nm_subproduto TEXT NOT NULL
);

CREATE TABLE fato_carteira (
    mesref TEXT NOT NULL,
    safra TEXT NOT NULL,
    mob INTEGER NOT NULL,
    cd_produto INTEGER NOT NULL,
    qt_contratos INTEGER NOT NULL,
    saldo REAL NOT NULL,
    bruto REAL NOT NULL,
    fx_atraso TEXT NOT NULL,
    receita_credito REAL NOT NULL,
    custo_captacao REAL NOT NULL,
    despesas_pdd REAL NOT NULL,
    PRIMARY KEY (cd_produto, safra, fx_atraso, mesref),
    FOREIGN KEY (cd_produto) REFERENCES dim_produto(cd_produto)
    
);

CREATE INDEX idx_fato_carteira_mesref ON fato_carteira(mesref);
CREATE INDEX idx_fato_carteira_safra_mob ON fato_carteira(safra, mob);
