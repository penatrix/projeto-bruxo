# Projeto Bruxo — ambiente de desenvolvimento

OT Server com temática de escola de magia, folclore brasileiro no bestiário.
O documento de design está em [`docs/design.md`](docs/design.md) — inclusive a
**regra de nomenclatura da seção 2**, que é a única parte inegociável do projeto.

Stack local em Docker: MariaDB + engine TFS 1.5 (downgrade 8.60) + Adminer.
O código do engine fica em `./server`, montado como volume — você edita Lua no host e
reinicia o container, sem rebuild.

## Pré-requisitos

- Docker, com o subcomando `docker compose` (com espaço, não o `docker-compose` antigo)
- `make`
- Um cliente OTClient V8 configurado para `127.0.0.1:7171`, protocolo 8.60

## Setup

```bash
make init     # cria o .env e clona o engine em ./server
# edite o .env: troque as senhas
make build    # compila (primeira vez ~5-15 min)
make up       # sobe banco + servidor
make seed     # cria a conta de desenvolvimento (admin / admin)
```

Adminer em http://localhost:8080 (servidor `db`, usuário e senha do `.env`).

Depois do `make seed`, logue com **admin / admin** no personagem **Deus** (god,
level 100). O `schema.sql` também traz uma conta `1` / `1` de fábrica.

## Comandos do dia a dia

| Comando | O quê |
|---|---|
| `make restart` | reinicia o servidor — use depois de mexer em Lua |
| `make logs` | segue os logs |
| `make shell` | bash dentro do container |
| `make db-shell` | cliente mariadb |
| `make seed` | (re)cria a conta de desenvolvimento — idempotente |
| `make status` | teste de vida: mostra o IP que o servidor anuncia aos clientes |
| `make build` | recompila — só necessário ao mexer em C++ |
| `make down` | derruba tudo (o banco persiste no volume) |

`docker compose down -v` apaga o volume do banco — é o jeito de recomeçar do zero.

## Jogando de outra máquina na rede

Cenário: **servidor no Mac, cliente no Windows**, os dois no mesmo Wi-Fi. É o arranjo
natural porque não existe build pronta de cliente 8.60 para macOS, e existe para Windows.

O passo a passo completo, do zero até entrar no jogo, está em
[`docs/rodando.md`](docs/rodando.md) — e, para hospedar o servidor numa máquina
Linux na internet em vez do seu computador, em [`docs/deploy-vps.md`](docs/deploy-vps.md).
O resumo:

### 1. Descubra o IP do Mac na rede local

```bash
ipconfig getifaddr en0   # Wi-Fi; se vier vazio, tente en1
```

### 2. Ponha esse IP no `.env`

```
SERVER_IP=192.168.0.42
```

Isto **não** é cosmético. O login server responde a lista de personagens com o endereço
do `config.lua`, e é para lá que o cliente abre a segunda conexão (a do mundo, porta
7172). Com `127.0.0.1`, o Windows recebe "conecte em 127.0.0.1", tenta conectar em si
mesmo e trava depois de escolher o personagem — sintoma clássico e enganoso, porque a
tela de login funciona normalmente.

```bash
docker compose up -d server   # o entrypoint reescreve o config.lua a cada boot
make status                   # confira: ip="192.168.0.42", client="860"
```

### 3. Libere o firewall do Mac

Ajustes do Sistema → Rede → Firewall. Se estiver ligado, permita conexões de entrada
para o Docker. Numa rede doméstica confiável, desligar durante o teste também resolve.

### 4. No Windows

Teste a rota antes de abrir o cliente — separa problema de rede de problema de cliente:

```powershell
Test-NetConnection 192.168.0.42 -Port 7171
Test-NetConnection 192.168.0.42 -Port 7172
```

Depois, no OTClientV8 (existe uma distribuição dedicada ao 8.60, já com sprites e lista
de servidores): adicione um servidor com IP `192.168.0.42`, porta `7171`, versão `860`.
Se usar a build genérica do [OTCv8](https://github.com/OTCv8/otclientv8), ela não vem
com sprites — é preciso pôr `Tibia.spr` e `Tibia.dat` do cliente 8.60 em `data/things/860`.

Login: **admin / admin**, personagem **Deus** (depois do `make seed`).

### Docker no Mac

Docker Desktop, OrbStack ou colima — qualquer um serve. Todas as imagens usadas têm
build arm64, então em Apple Silicon roda nativo. Se o compilador engasgar em arm64,
o plano B é forçar x86 via Rosetta acrescentando `platform: linux/amd64` aos serviços
`build` e `server` no `docker-compose.yml` (compila mais devagar, mas funciona).

> Os arquivos `Tibia.spr` / `Tibia.dat` são assets da CipSoft. É a mesma decisão
> consciente de fase de protótipo registrada na seção 10 do documento de design.

## Sobre a escolha do engine

O `make init` clona **MillhioreBT/forgottenserver-downgrade**, e não o nekiro que é a
referência mais citada em tutoriais. Motivo: o repositório do nekiro foi arquivado em
agosto de 2022 e está read-only desde então. O fork do MillhioreBT partiu dele, seguiu
acompanhando o TFS upstream e migrou para Lua 5.4.

Para usar outro engine, sobrescreva na chamada:

```bash
make init ENGINE_REPO=https://github.com/fulano/outro-fork.git ENGINE_REF=8.60
```

O `.git` é removido depois do clone de propósito: `./server` passa a ser o seu código,
versionado neste repositório.

## Decisões do ambiente

Três coisas que quebraram no primeiro teste e por que estão do jeito que estão:

- **Base Ubuntu 24.04 e não Debian bookworm.** Com suporte a HTTP ligado (padrão), o
  `CMakeLists.txt` do engine exige Boost >= 1.75, porque precisa de `boost-json`.
  Bookworm congelou no Boost 1.74. Ubuntu 24.04 traz 1.83 e é a base que o próprio
  engine usa no CI.
- **`-DSKIP_GIT=ON` no build.** O engine grava metadados de commit via `git_watcher`,
  e `./server` não é um repositório git próprio — o `.git` sai no `make init`.
- **Adminer com `command` explícito.** A imagem escuta em `[::]:8080` por padrão e
  entra em loop de restart em host sem IPv6.

O cliente de linha de comando da imagem `mariadb:11` chama-se `mariadb`, não `mysql` —
por isso o `db-shell` usa esse nome.

## Se o build falhar

O ponto mais provável de falha é dependência faltando — cada fork usa um conjunto um
pouco diferente. O erro do CMake sempre diz qual `find_package` quebrou. Adicione o
pacote `-dev` correspondente em `docker/Dockerfile` e rode `make build` de novo.

Casos comuns:

| Erro do CMake | Pacote |
|---|---|
| `Could NOT find Boost ... 1.75` | base velha demais; ver seção acima |
| `Could NOT find PugiXML` | `libpugixml-dev` |
| `Could NOT find fmt` | `libfmt-dev` |
| `Could NOT find Lua` | `liblua5.4-dev`, ou `-DUSE_LUAJIT=ON` se o fork quiser LuaJIT |
| `mysql.h: No such file` | `libmariadb-dev-compat` |

## Estrutura

```
.
├── docker-compose.yml
├── Makefile
├── .env                  # não versionado
├── docs/
│   └── design.md         # documento de design do jogo
├── docker/
│   ├── Dockerfile        # toolchain + deps
│   ├── build.sh          # compilação
│   ├── entrypoint.sh     # espera o banco, importa schema, gera config.lua
│   └── seed-dev.sql      # conta de desenvolvimento
└── server/               # o engine (seu código)
    ├── data/             # datapack: spells, monsters, npcs, scripts
    ├── src/              # C++
    └── config.lua        # gerado no primeiro boot, não versionado
```

## Onde o trabalho do MVP acontece

| Sistema | Diretório |
|---|---|
| Feitiços | `server/data/spells/` |
| Varinha com núcleo | `server/data/movements/` + `server/data/creaturescripts/` |
| Poções | `server/data/actions/` |
| Aulas | `server/data/npc/` + storage values |
| Casas | `server/data/creaturescripts/` + tabelas de guild |
| Criaturas | `server/data/monster/` |
| Mapa | `server/data/world/*.otbm` (Remere's Map Editor) |
