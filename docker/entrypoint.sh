#!/usr/bin/env bash
set -euo pipefail

SRC=/srv
BIN="${TFS_BINARY:-$SRC/build/tfs}"

# ---------------------------------------------------------------------------
# 1. Espera o MariaDB aceitar conexão
# ---------------------------------------------------------------------------
echo ">> Aguardando o banco em ${DB_HOST}:${DB_PORT}..."
for i in $(seq 1 60); do
  if mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --silent 2>/dev/null; then
    echo ">> Banco respondendo."
    break
  fi
  sleep 2
  if [ "$i" -eq 60 ]; then
    echo "ERRO: banco não respondeu em 120s."
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# 2. Importa o schema se o banco estiver vazio
# ---------------------------------------------------------------------------
TABLES=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
         -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" 2>/dev/null || echo 0)

if [ "$TABLES" = "0" ]; then
  SCHEMA=$(find "$SRC" -maxdepth 2 -name 'schema.sql' | head -n1 || true)
  if [ -n "$SCHEMA" ]; then
    echo ">> Banco vazio. Importando $SCHEMA..."
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$SCHEMA"
    echo ">> Schema importado."
  else
    echo ">> AVISO: banco vazio e nenhum schema.sql encontrado em $SRC."
  fi
else
  echo ">> Banco já tem $TABLES tabelas. Pulando import."
fi

# ---------------------------------------------------------------------------
# 3. Gera o config.lua na primeira execução
# ---------------------------------------------------------------------------
if [ ! -f "$SRC/config.lua" ]; then
  if [ -f "$SRC/config.lua.dist" ]; then
    echo ">> Gerando config.lua a partir do config.lua.dist..."
    cp "$SRC/config.lua.dist" "$SRC/config.lua"
  else
    echo "ERRO: não achei config.lua nem config.lua.dist em $SRC."
    exit 1
  fi
fi

# Reescreve só as chaves de infraestrutura, preservando o resto do arquivo.
set_cfg() {
  local key="$1" val="$2"
  if grep -qE "^\s*${key}\s*=" "$SRC/config.lua"; then
    sed -i -E "s|^\s*${key}\s*=.*|${key} = ${val}|" "$SRC/config.lua"
  else
    echo "${key} = ${val}" >> "$SRC/config.lua"
  fi
}

set_cfg mysqlHost     "\"$DB_HOST\""
set_cfg mysqlUser     "\"$DB_USER\""
set_cfg mysqlPass     "\"$DB_PASSWORD\""
set_cfg mysqlDatabase "\"$DB_NAME\""
set_cfg mysqlPort     "$DB_PORT"
set_cfg ip            "\"$SERVER_IP\""
set_cfg serverName    "\"$SERVER_NAME\""
set_cfg motd          "\"$SERVER_MOTD\""

# ---------------------------------------------------------------------------
# 4. Sobe o servidor
# ---------------------------------------------------------------------------
if [ ! -x "$BIN" ]; then
  echo "ERRO: binário não encontrado em $BIN."
  echo "Rode 'make build' antes de 'make up'."
  exit 1
fi

echo ">> Iniciando o servidor..."
exec "$BIN"
