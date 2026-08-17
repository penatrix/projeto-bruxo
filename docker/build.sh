#!/usr/bin/env bash
set -euo pipefail

SRC=/srv
BUILD_DIR="$SRC/build"

if [ ! -f "$SRC/CMakeLists.txt" ]; then
  echo "ERRO: não encontrei CMakeLists.txt em $SRC."
  echo "Rode 'make init' primeiro para clonar o engine em ./server."
  exit 1
fi

# Quantos jobs paralelos. O engine usa unity build: cada job junta vários .cpp
# numa unidade só e chega a pedir ~2 GB de RAM. Com mais jobs do que a memória
# aguenta, o kernel mata o compilador e o cmake reporta
# "fatal error: Killed signal terminated program cc1plus" — que parece erro de
# compilação e não é. Por isso o padrão é limitado pela memória, não só pelos
# núcleos. Dá para forçar: BUILD_JOBS=2 make build
CPUS=$(nproc)
MEM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
MEM_GB=$((MEM_KB / 1024 / 1024))
MEM_JOBS=$((MEM_GB / 2))
[ "$MEM_JOBS" -lt 1 ] && MEM_JOBS=1

JOBS="${BUILD_JOBS:-$([ "$MEM_JOBS" -lt "$CPUS" ] && echo "$MEM_JOBS" || echo "$CPUS")}"

echo ">> Recursos disponíveis para o build: ${CPUS} CPUs, ${MEM_GB} GB de RAM."
if [ "$MEM_GB" -lt 4 ]; then
  echo ">> AVISO: menos de 4 GB. Se o build morrer com 'Killed signal terminated"
  echo ">>        program cc1plus', aumente a memória da VM do Docker"
  echo ">>        (Docker Desktop: Settings > Resources > Memory)."
fi

# UNITY_BUILD=OFF compila arquivo a arquivo: bem mais lento, mas com um pico de
# memória muito menor. É a saída para máquinas onde nem BUILD_JOBS=1 passa.
UNITY="${UNITY_BUILD:-ON}"

# SKIP_GIT: o engine tenta gravar metadados de commit via git_watcher, e o
# ./server não é um repositório git próprio (o .git é removido no make init).
echo ">> Configurando CMake..."
cmake -S "$SRC" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DSKIP_GIT=ON \
  -DENABLE_UNITY_BUILD="$UNITY" \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache

echo ">> Compilando com $JOBS job(s), unity build $UNITY..."
if ! cmake --build "$BUILD_DIR" -j "$JOBS"; then
  echo
  echo ">> O build falhou. Se a mensagem acima foi 'Killed signal terminated"
  echo ">> program cc1plus', foi falta de memória, não erro de código. Tente:"
  echo ">>   1. aumentar a RAM da VM do Docker (Settings > Resources > Memory)"
  echo ">>   2. BUILD_JOBS=2 make build"
  echo ">>   3. UNITY_BUILD=OFF BUILD_JOBS=1 make build   (lento, último recurso)"
  exit 1
fi

# O nome do binário varia entre forks (tfs, theforgottenserver, otbr...).
BIN=$(find "$BUILD_DIR" -maxdepth 2 -type f -executable \
      \( -name 'tfs' -o -name 'theforgottenserver' -o -name '*server*' \) \
      ! -name '*.so*' | head -n1 || true)

if [ -z "$BIN" ]; then
  echo ">> Build terminou, mas não localizei o binário automaticamente."
  echo ">> Procure em $BUILD_DIR e ajuste TFS_BINARY no .env"
  exit 1
fi

echo ">> Binário: $BIN"

# Só cria o symlink se o binário tiver outro nome — senão o ln -f apagaria
# o próprio executável e o substituiria por um link apontando para si mesmo.
if [ "$BIN" != "$BUILD_DIR/tfs" ]; then
  ln -sf "$BIN" "$BUILD_DIR/tfs"
  echo ">> Symlink criado: build/tfs"
fi
