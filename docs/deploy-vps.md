# Subindo o servidor num VPS

Guia alternativo ao [`rodando.md`](rodando.md), para quando o servidor mora numa
máquina Linux na internet em vez do seu computador.

## Antes: rodar é leve, compilar é que é pesado

Vale separar as duas coisas, porque elas têm custos muito diferentes:

| | RAM | Quando acontece |
|---|---|---|
| **Rodar** o servidor | ~100–200 MB (mais ~400 MB do MariaDB) | sempre |
| **Compilar** o engine | ~2 GB por job paralelo | uma vez, e a cada mexida em C++ |

Quem rodou OT server no passado baixava um `.exe` já compilado e só executava — por
isso a lembrança é de algo leve. A lembrança está certa: o que pesa aqui é o passo de
compilação, que antigamente outra pessoa tinha feito por você.

Consequência prática: **não adianta pegar o VPS mais barato**. Uma máquina de 1 GB roda
o servidor tranquilamente, mas não compila. Duas saídas:

- VPS com **4 GB de RAM** (2 vCPU, ~40 GB de disco) — compila sem drama;
- VPS de 2 GB + `UNITY_BUILD=OFF BUILD_JOBS=1 make build` — compila devagar, mas passa.

## Passo 1 — Provisionar a máquina

Qualquer provedor serve; o documento de design cita Hetzner e Contabo. Peça:

- **Ubuntu 24.04 LTS** (é a mesma base do container, o caminho mais testado)
- 2 vCPU, 4 GB RAM, 40 GB de disco
- autenticação por **chave SSH**, não por senha

Anote o **IP público** da máquina. Ele faz aqui o papel que o IP do Wi-Fi fazia no
guia local.

## Passo 2 — Preparar o sistema

Conecte e instale o necessário:

```bash
ssh root@SEU.IP.PUBLICO

apt update && apt upgrade -y
apt install -y docker.io docker-compose-v2 git make
systemctl enable --now docker
```

Crie um usuário comum em vez de trabalhar como root:

```bash
adduser bruxo
usermod -aG docker,sudo bruxo
rsync --archive --chown=bruxo:bruxo ~/.ssh /home/bruxo
```

Saia e reconecte como ele: `ssh bruxo@SEU.IP.PUBLICO`.

## Passo 3 — Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 7171/tcp     # login
sudo ufw allow 7172/tcp     # mundo
sudo ufw enable
sudo ufw status
```

> **Atenção a uma pegadinha do Docker:** ele escreve as próprias regras de iptables
> *antes* das do ufw. Uma porta publicada em `0.0.0.0` fica acessível na internet mesmo
> com o ufw negando. Por isso o `docker-compose.yml` deste projeto publica MySQL e
> Adminer em `127.0.0.1` — não desfaça isso. Só 7171 e 7172 devem ser públicas.

## Passo 4 — Clonar e configurar

```bash
git clone https://github.com/penatrix/projeto-bruxo.git
cd projeto-bruxo
cp .env.example .env
```

Ajuste o `.env` — aqui o `SERVER_IP` é o **IP público do VPS**:

```bash
sed -i "s/^DB_ROOT_PASSWORD=.*/DB_ROOT_PASSWORD=$(openssl rand -hex 12)/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$(openssl rand -hex 12)/" .env
sed -i 's/^SERVER_IP=.*/SERVER_IP=203.0.113.10/' .env      # ← o IP público
cat .env
```

(no Linux o `sed -i` não leva o `''` que o macOS exige)

## Passo 5 — Compilar

```bash
make build
```

Numa máquina de 4 GB o `build.sh` escolhe os jobs sozinho. Se a memória for menor e o
build morrer com `Killed signal terminated program cc1plus`:

```bash
UNITY_BUILD=OFF BUILD_JOBS=1 make build
```

É bem mais lento, mas é uma vez só — o ccache guarda o resultado.

## Passo 6 — Subir

```bash
docker compose up -d db adminer server
make seed
make status
```

Confira no `make status` que o `ip=` é o IP público. Para acompanhar os logs sem
prender o terminal: `make logs`.

### Deixar de pé depois que você desconectar

Os containers têm `restart: unless-stopped`, então sobrevivem a fechar o SSH e a
reinícios da máquina. Não precisa de `screen`/`tmux` para isso.

## Passo 7 — Trocar a senha do god

O `make seed` cria `admin` / `admin`. Isso é aceitável na sua rede local; num servidor
público é um convite. Troque **antes** de anunciar o IP para alguém:

```bash
make db-shell
```

```sql
UPDATE accounts SET password = SHA1('uma-senha-de-verdade') WHERE name = 'admin';
```

## Passo 8 — Conectar do cliente

Igual ao guia local, trocando o IP da rede pelo IP público: no `init.lua` do OTCv8,

```lua
Servers = {
  Bruxo = "203.0.113.10:7171:860"
}
```

## O dia a dia depois disso

O fluxo de trabalho muda: você edita no seu computador, envia por git, e o servidor
puxa.

```bash
# no seu Mac
git add -A && git commit -m "..." && git push

# no VPS
cd projeto-bruxo && git pull && make restart
```

`make restart` recarrega os scripts Lua. Só mexida em C++ exige `make build` de novo.

## Quando der errado

| Sintoma | Causa provável |
|---|---|
| `Killed signal terminated program cc1plus` | memória — use `UNITY_BUILD=OFF BUILD_JOBS=1` |
| Cliente não conecta, mas `make status` responde no VPS | ufw sem 7171/7172, ou firewall do provedor (Hetzner e Contabo têm firewall próprio no painel, separado do ufw) |
| Trava ao entrar com o personagem | `SERVER_IP` não é o IP público — `make status` mostra o que ele anuncia |
| `permission denied` no docker | faltou relogar depois do `usermod -aG docker` |
