#!/usr/bin/env bash
set -euo pipefail

SRC=/srv
BUILD_DIR="$SRC/build"

if [ ! -f "$SRC/CMakeLists.txt" ]; then
  echo "ERRO: não encontrei CMakeLists.txt em $SRC."
  echo "Rode 'make init' primeiro para clonar o engine em ./server."
  exit 1
fi

# SKIP_GIT: o engine tenta gravar metadados de commit via git_watcher, e o
# ./server não é um repositório git próprio (o .git é removido no make init).
echo ">> Configurando CMake..."
cmake -S "$SRC" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DSKIP_GIT=ON \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache

echo ">> Compilando com $(nproc) jobs..."
cmake --build "$BUILD_DIR" -j "$(nproc)"

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
