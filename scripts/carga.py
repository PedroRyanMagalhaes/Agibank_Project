import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
DDL_PATH = ROOT / "sql" / "01_ddl.sql"
DB_PATH = ROOT / "data" / "carteira.db"

CSV_PRODUTO = RAW_DIR / "depara_produto.csv"
CSV_CARTEIRA = RAW_DIR / "cubo_carteira_credito.csv"


def executar_ddl(conn: sqlite3.Connection) -> None:
    ddl = DDL_PATH.read_text(encoding="utf-8")
    conn.executescript(ddl)


def ler_csv(caminho: Path, dtype: dict | None = None) -> pd.DataFrame:
    return pd.read_csv(
        caminho,
        sep=";",
        decimal=",",
        encoding="latin-1",
        dtype=dtype,
    )


def inserir(conn: sqlite3.Connection, df: pd.DataFrame, tabela: str) -> None:
    df.to_sql(tabela, conn, if_exists="append", index=False)


def validar(conn: sqlite3.Connection, df: pd.DataFrame, tabela: str) -> None:
    """Confere se a tabela no banco tem a mesma quantidade de linhas do CSV."""
    count = conn.execute(f"SELECT COUNT(*) FROM {tabela}").fetchone()[0]
    if count != len(df):
        raise ValueError(f"Validação falhou para {tabela}: {count} != {len(df)}")
    print(f"Validação OK para {tabela}: {count} linhas")


def main() -> None:
    """ leitura -> inserção -> validação -> commit."""
    conn = sqlite3.connect(DB_PATH)
    try:
        executar_ddl(conn)

        df_produto = ler_csv(CSV_PRODUTO)
        df_carteira = ler_csv(CSV_CARTEIRA, dtype={"fx_atraso": str})

        inserir(conn, df_produto, "dim_produto")
        inserir(conn, df_carteira, "fato_carteira")

        validar(conn, df_produto, "dim_produto")
        validar(conn, df_carteira, "fato_carteira")

        conn.commit()
        print(f"Carga concluída em {DB_PATH}")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
