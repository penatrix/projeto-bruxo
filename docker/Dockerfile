FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Toolchain de build + dependências do engine + cliente mysql para o schema.
#
# Por que Ubuntu 24.04: é a base que o próprio engine usa no CI, e traz
# Boost 1.83. O CMakeLists exige Boost >= 1.75 quando o suporte a HTTP está
# ligado (é o padrão) porque precisa de boost-json — Debian bookworm, que é a
# escolha mais óbvia, congelou no Boost 1.74 e não serve.
#
# Se um build futuro falhar por dependência faltando, o erro do CMake diz
# exatamente qual find_package quebrou — é só adicionar o -dev correspondente
# aqui e rodar `make build` de novo.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      ninja-build \
      ccache \
      git \
      pkg-config \
      ca-certificates \
      curl \
      netcat-openbsd \
      mariadb-client \
      libboost-dev \
      libboost-system-dev \
      libboost-iostreams-dev \
      libboost-filesystem-dev \
      libboost-date-time-dev \
      libboost-thread-dev \
      libboost-locale-dev \
      libboost-json-dev \
      liblua5.4-dev \
      libmariadb-dev \
      libmariadb-dev-compat \
      libpugixml-dev \
      libfmt-dev \
      libssl-dev \
      zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ENV CCACHE_DIR=/root/.ccache
ENV PATH="/usr/lib/ccache:${PATH}"

COPY build.sh /usr/local/bin/build.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/build.sh /usr/local/bin/entrypoint.sh

WORKDIR /srv
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
