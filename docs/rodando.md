# Rodando o servidor e entrando no jogo

Cenário deste guia: **servidor no Mac, cliente no Windows**, os dois na mesma rede.
É o arranjo natural porque não existe build pronta de cliente 8.60 para macOS e existe
para Windows.

Duas portas importam:

| Porta | Para quê |
|---|---|
| 7171 | login (lista de personagens) e protocolo de status |
| 7172 | o mundo — a segunda conexão, aberta depois que você escolhe o personagem |

---

# Parte 1 — Mac: subir o servidor

## Passo 0 — Pré-requisitos

Instale o Docker (Docker Desktop, OrbStack ou colima — qualquer um serve) e as
ferramentas de linha de comando da Apple:

```bash
xcode-select --install     # traz git e make
```

Confira antes de seguir:

```bash
docker compose version     # precisa ser v2.x
make -v
git --version
```

O Docker precisa estar **rodando** (ícone na barra de menu), não só instalado.

## Passo 1 — Clonar o repositório

```bash
git clone https://github.com/penatrix/projeto-bruxo.git
cd projeto-bruxo
```

O engine já vem versionado em `./server` — não precisa clonar nada além disso.
Rodar `make init` aqui é opcional: ele detecta que o engine já existe, só cria o `.env`.

## Passo 2 — Descobrir o IP do Mac na rede

```bash
ipconfig getifaddr en0     # Wi-Fi. Se vier vazio, tente en1
```

Anote — por exemplo `192.168.0.42`. É o endereço que o Windows vai usar.

> Esse IP costuma vir do DHCP do roteador e **pode mudar** quando você reconecta o
> Wi-Fi. Se um dia o cliente parar de conectar do nada, confira este passo primeiro.
> Reservar o IP no roteador resolve de vez.

## Passo 3 — Criar e editar o `.env`

```bash
cp .env.example .env
```

Abra e ajuste:

```
DB_ROOT_PASSWORD=algumaCoisaQueVoceEscolheu
DB_PASSWORD=outraCoisaQueVoceEscolheu
SERVER_NAME=Vallenmoor
SERVER_IP=192.168.0.42          # ← o IP do passo 2, NÃO 127.0.0.1
```

**Por que o `SERVER_IP` é o passo mais importante deste guia:** quando o cliente
faz login, o servidor responde a lista de personagens carregando dentro dela o
endereço do `config.lua`. É para *esse* endereço que o cliente abre a conexão do
mundo. Se ficar `127.0.0.1`, o Windows recebe "conecte em 127.0.0.1", tenta conectar
em si mesmo e **trava depois de escolher o personagem** — com a tela de login
funcionando normalmente, o que faz você procurar o problema no lugar errado.

## Passo 4 — Compilar

```bash
make build
```

Primeira vez: 5 a 15 minutos. As seguintes são rápidas (ccache). Só precisa repetir
isto ao mexer em C++ — mexer em Lua não exige recompilar.

Em Apple Silicon o build roda nativo em arm64. Se o compilador engasgar, o plano B é
forçar x86 via Rosetta: acrescente `platform: linux/amd64` aos serviços `build` e
`server` no `docker-compose.yml` e rode `make build` de novo.

## Passo 5 — Subir

```bash
make up
```

Isso sobe o banco e o Adminer em segundo plano e deixa o **servidor em primeiro
plano**, com os logs na tela. Você deve ver, no fim:

```
>> Loading map
> Map size: 2048x2048.
>> Loaded all modules, server starting up...
>> Vallenmoor Server Online!
```

`Ctrl+C` nesse terminal derruba o servidor. Para deixá-lo rodando solto e liberar o
terminal, use `docker compose up -d server` em vez de `make up`, e acompanhe com
`make logs`.

## Passo 6 — Criar a conta (só na primeira vez)

Em **outro terminal**, na mesma pasta:

```bash
make seed
```

Cria a conta `admin` / `admin` com o personagem **Deus** (god, level 100). O comando é
idempotente: pode rodar de novo sem estragar nada.

## Passo 7 — Conferir antes de sair do Mac

```bash
make status
```

Resposta esperada — confira os três campos:

```xml
<serverinfo uptime="..." ip="192.168.0.42" servername="Vallenmoor" port="7171"
            server="Millhiore TFS Downgrade" version="1.5+" client="860"/>
```

- `ip=` tem que ser o IP do Mac. Se estiver `127.0.0.1`, volte ao passo 3 e reinicie
  o servidor (`docker compose up -d server`) — o `config.lua` é reescrito a cada boot.
- `client="860"` confirma a versão de protocolo que o cliente precisa usar.

## Passo 8 — Liberar o firewall do Mac

Ajustes do Sistema → Rede → Firewall. Se estiver ligado, permita conexões de entrada
para o Docker. Numa rede doméstica confiável, desligá-lo durante o teste também resolve.

---

# Parte 2 — Windows: entrar no jogo

## Passo 1 — Testar a rede antes de abrir o cliente

No PowerShell, troque pelo IP do Mac:

```powershell
Test-NetConnection 192.168.0.42 -Port 7171
Test-NetConnection 192.168.0.42 -Port 7172
```

As duas precisam responder `TcpTestSucceeded : True`. Se falharem, o problema é rede
(firewall, IP errado, containers parados) e nenhum cliente vai funcionar — resolva
aqui antes de continuar.

## Passo 2 — Baixar o cliente

Use o **OTClientV8**. Existe uma distribuição dedicada ao 8.60 que já vem com sprites
e lista de servidores — é o caminho mais curto, e está no site oficial
([otclient.ovh](https://otclient.ovh/)) e no tópico de release no OTLand.

Se usar a build genérica do [OTCv8](https://github.com/OTCv8/otclientv8), ela **não vem
com sprites**: é preciso pôr `Tibia.spr` e `Tibia.dat` do cliente 8.60 em
`data/things/860`.

> Esses arquivos são assets da CipSoft. É a mesma decisão consciente de fase de
> protótipo registrada na seção 10 do documento de design.

## Passo 3 — Apontar o cliente para o Mac

O OTCv8 lê a lista de servidores do `init.lua`, na raiz da pasta do cliente. O formato
de cada entrada é `"ip:porta:versao"`:

```lua
Servers = {
  Bruxo = "192.168.0.42:7171:860"
}
```

Alternativa sem editar arquivo: no mesmo `init.lua`, garanta

```lua
ALLOW_CUSTOM_SERVERS = true
```

Isso faz aparecer a opção **ANOTHER** na lista de servidores da tela de login, onde
você digita IP, porta e versão na hora.

De qualquer forma: IP do Mac, porta **7171**, versão **860**.

## Passo 4 — Logar

- Conta: `admin`
- Senha: `admin`
- Personagem: **Deus**

Não é preciso configurar chave RSA: o engine usa a chave OT padrão, que é a mesma que
o OTClient já traz embutida.

---

# Quando der errado

| Sintoma | Causa provável |
|---|---|
| Tela de login OK, trava **ao entrar com o personagem** | `SERVER_IP` errado. `make status` e confira o `ip=` |
| Lista de personagens vazia | faltou `make seed` |
| "Unable to connect" / timeout já no login | firewall do Mac, IP mudou (DHCP), ou os containers não estão de pé (`docker compose ps`) |
| Conectava e parou de conectar do nada | o IP do Mac mudou. Refaça os passos 2, 3 e reinicie o servidor |
| Cliente reclama de versão de protocolo | a entrada no `init.lua` precisa terminar em `:860` |
| `make build` falha em Apple Silicon | `platform: linux/amd64` nos serviços `build` e `server` |
| Erro de CMake com `find_package` | dependência faltando — ver a tabela no README |
| Servidor não sobe: "binário não encontrado" | faltou `make build` |

Comandos de diagnóstico, na ordem em que valem a pena:

```bash
docker compose ps      # os três containers estão de pé?
make status            # o servidor responde? qual ip ele anuncia?
make logs              # o que ele disse ao subir?
```

## Recomeçar do zero

```bash
docker compose down -v   # derruba tudo e APAGA o banco
make up
make seed
```
