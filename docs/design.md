# Projeto [nome a definir] — Documento de Design v0.1

OT Server customizado com temática de escola de magia.
Base técnica: The Forgotten Server (TFS) 1.4/1.5 downgrade 8.60 + OTClient V8.

---

## 1. Premissa

Uma escola de magia brasileira, escondida em algum ponto do interior — um casarão colonial
que cresceu por dentro, com alas que não deveriam caber no terreno.

Alunos entram como aprendizes, escolhem uma trilha de estudo, aprendem feitiços através de
aulas (não comprando em NPC), preparam poções, competem pela pontuação da sua casa e
enfrentam o que vive na mata ao redor.

**Por que folclore brasileiro:** o bestiário é 100% domínio público, é inexplorado em MMOs,
e resolve o problema de identidade — o servidor deixa de ser "cópia do HP" e vira algo
próprio que ocupa o mesmo espaço emocional.

### Nomes candidatos para o servidor

| Nome | Comentário |
|---|---|
| **Vallenmoor** | Neutro, soa a fantasia clássica. Fácil de lembrar, domínio provavelmente livre. |
| **Colégio Aurífice** | "Aurífice" = ourives/artífice do ouro. Sonoridade alquímica. |
| **Vigília** | Curto, forte, funciona como nome de servidor e de ordem interna. |
| **Sortilégio** | Muito temático, mas genérico demais para registrar. |
| **Vaharis** | Inventado, sem colisão. Bom se quiser algo que não signifique nada ainda. |

Checar antes de fixar: domínio `.com` / `.com.br`, busca no INPI, e se não existe OT com o nome.

---

## 2. Regra de nomenclatura (a única coisa realmente inegociável)

**Nunca usar, em nenhum lugar do código, mapa, site ou material de divulgação:**

- Hogwarts, Beauxbatons, Durmstrang, Castelobruxo, Ilvermorny
- Nomes das quatro casas do HP, seus fundadores, brasões e mascotes
- Quadribol / Quidditch, pomo, balaço, artilheiro, apanhador
- Trouxa / muggle, aurores, Ministério da Magia, comensais
- Qualquer nome de personagem (Harry, Hermione, Dumbledore, Snape, Voldemort...)
- Feitiços cunhados pela autora: Expelliarmus, Wingardium Leviosa, Avada Kedavra,
  Lumos, Expecto Patronum, Alohomora, Accio, Petrificus Totalus
- Dementadores, horcruxes, pensadeira, mapa do maroto, capa da invisibilidade
- Qualquer arte, tipografia ou paleta derivada dos filmes

**Livre para usar:**

- Latim real (é domínio público — só evite as combinações específicas da lista acima)
- Escola de magia, casas rivais, varinhas, poções, professores, dormitórios, torneios
- Todo o folclore e mitologia: basilisco, grifo, fênix, centauro, mandrágora, salamandra,
  banshee, quimera, golem, lobisomem — e o folclore brasileiro inteiro

---

## 3. Tabela de conversão — Tibia → universo do jogo

| Sistema no TFS | Vira | Notas de implementação |
|---|---|---|
| Vocations | **Trilhas de estudo** | 4 trilhas, ver seção 4 |
| Mana | **Fluxo** | Só renomear na interface e mensagens |
| Soul points | **Foco** | Consumido ao selar pergaminhos |
| Spells (`data/spells`) | **Feitiços** | Gramática própria, ver seção 5 |
| Runes | **Pergaminhos selados** | Item de uso único, preparado pelo jogador |
| Guilds | **Casas** | Com placar sazonal — ver seção 6 |
| Weapons (sword/axe/club) | **Varinhas, bastões, adagas rituais** | Varinha vira o item central |
| Distance weapons | **Focos de longo alcance** | Cristais, penas encantadas |
| Shields | **Amuletos e brasões** | |
| Potions | **Poções** | Preparo por receita, não compra |
| Fishing | **Colheita de ingredientes** | Mesma mecânica, outro asset |
| Quests | **Aulas e provas** | Quest chain por matéria |
| Depot | **Baú do dormitório** | |
| Player houses | **Aposentos** | Desbloqueia por nível de estudo |
| Boats / travel NPCs | **Rede de braseiros** | Viagem por lareira acesa |
| Temple / respawn | **Enfermaria** | |
| Death penalty | **Desmaio** | Perda de Foco em vez de XP puro (opcional) |
| Bosses | **Entidades do folclore** | Boitatá, mula-sem-cabeça, cuca |
| Monsters | Fauna encantada da mata | |

---

## 4. As quatro trilhas (vocations)

Mapeadas em cima das quatro vocações do TFS para reaproveitar todo o balanceamento existente.

| Trilha | Base TFS | Identidade | Recurso principal |
|---|---|---|---|
| **Evocador** | Sorcerer | Dano elemental direto, área | Fluxo alto, defesa baixa |
| **Herbolário** | Druid | Cura, venenos, invocação de plantas | Suporte + controle |
| **Sentinela** | Paladin | Distância, precisão, armadilhas | Híbrido |
| **Duelista** | Knight | Corpo a corpo com magia defensiva | Vida alta, Fluxo baixo |

Promoção (segunda vocação) vira **Mestrado**: Evocador → Arquievocador, etc.

---

## 5. Gramática de feitiços

Estrutura de duas palavras: **[elemento/domínio] + [forma]**. Latim real, combinações próprias.

**Domínios:** Ignis (fogo) · Gelu (gelo) · Fulgor (raio) · Terra · Ventus · Umbra (sombra) ·
Vitae (vida) · Venenum (veneno) · Lux (luz)

**Formas:** Vora (projétil) · Ictus (golpe em linha) · Nimbus (área ao redor) · Vincire (prender) ·
Murus (parede) · Velum (véu/ocultar) · Fluere (fluir/contínuo) · Pello (empurrar)

### Feitiços iniciais do MVP

| Incantação | Efeito | Equivalente TFS |
|---|---|---|
| `ignis vora` | Projétil de fogo | exori flam |
| `ignis nimbus` | Explosão em área | exevo flam hur |
| `gelu vincire` | Paralisa o alvo | exori frigo |
| `fulgor ictus` | Raio em linha reta | exevo vis lux |
| `vitae fluere` | Cura o conjurador | exura |
| `vitae dono` | Cura o alvo | exura sio |
| `terra murus` | Parede de pedra temporária | adevo grav tera |
| `ventus pello` | Empurra criaturas adjacentes | — (custom) |
| `umbra velum` | Reduz visibilidade do jogador | utana vid |
| `lux perpetua` | Luz | utevo lux |

> Regra de ouro ao criar novos: se soar como algo dito num filme, troque.

---

## 6. Sistemas mínimos do MVP

Estes cinco são o que faz o servidor **ser** o projeto, e não Tibia com nomes trocados.
Tudo o mais pode ficar padrão do TFS na primeira versão.

### 6.1 Varinha com núcleo — *o sistema central*

A varinha é o item mais importante do jogo. Composta por duas propriedades armazenadas
em `ItemAttributes` customizados:

- **Madeira** → modifica custo de Fluxo e velocidade de conjuração
- **Núcleo** → modifica dano por domínio elemental

| Núcleo | Efeito | Origem |
|---|---|---|
| Pena de fênix | +15% dano de Ignis e Lux | Drop raro |
| Escama de boitatá | +15% Ignis, -10% Gelu | Boss |
| Crina de curupira | +12% Terra e Ventus | Drop |
| Fio de iara | +15% cura, -10% dano | Evento |
| Osso de cuca | +15% Umbra e Venenum | Boss |

Implementação: `movements` para detectar equipar, `creaturescript` no cast lendo o atributo
do item na mão e aplicando multiplicador antes do combat. É a peça que quero atacar primeiro
porque ela toca em quase todo o pipeline de combate.

### 6.2 Aprendizado por aula

Feitiços **não são comprados de NPC**. O jogador lê um livro/assiste uma aula (quest simples)
e o feitiço é liberado via storage value. Muda completamente a sensação de progressão.

- Tabela `player_spells` já existe no TFS — dá pra reaproveitar
- Cada matéria = uma quest chain de 5 aulas
- Matérias do MVP: Feitiços Elementares, Herbologia, Defesa Prática

### 6.3 Casas com placar

Sistema de guild do TFS, mas com atribuição automática na criação do personagem e um
placar global.

- 4 casas, jogador entra numa delas no tutorial
- Ações que dão pontos: matar boss, completar aula, vencer duelo em arena
- Placar visível no site e num quadro dentro do jogo
- Reset sazonal com recompensa cosmética para a casa vencedora

### 6.4 Poções por preparo

- Ingredientes colhidos no mapa (reaproveita mecânica de fishing/pick)
- Receita = combinar N ingredientes num caldeirão (item de ação no mapa)
- Falha na receita gera um item de efeito negativo — vale o risco, cria história
- MVP: 6 receitas

### 6.5 Mapa inicial — o castelo como hub

Escopo do primeiro mapa, deliberadamente pequeno:

- Saguão de entrada + escadaria
- 3 salas de aula (uma por matéria do MVP)
- 4 dormitórios (um por casa)
- Enfermaria (respawn)
- Pátio externo com saída para a mata
- Uma área de caça de nível 1-20 na mata

---

## 7. Fase 2 (depois do MVP, não antes)

- Torneio aéreo (evento de captura, substituto conceitual do esporte)
- Duelos formais com ranking
- Sistema de artefatos e encantamento de itens
- Segunda escola / região rival
- Mapa expandido, níveis 20-80
- Substituição gradual de sprites por arte própria

---

## 8. Stack

| Camada | Escolha |
|---|---|
| Servidor | TFS 1.4/1.5 downgrade 8.60 (fork nekiro) |
| Cliente | OTClient V8 ou o fork do mehah |
| Banco | MySQL 8 / MariaDB |
| Site | MyAAC |
| Mapa | Remere's Map Editor 3.x |
| Sprites/dat | Object Builder + ItemEditor |
| Ambiente local | Docker Compose (server + db + aac) |
| Deploy | VPS Linux (Hetzner / Contabo) |

---

## 9. Roadmap por fim de semana

| # | Objetivo | Entregável |
|---|---|---|
| 1 | Ambiente rodando | docker-compose sobe TFS + MySQL, conecta com OTClient |
| 2 | Camada de renomeação | Vocações, mana→Fluxo, mensagens do sistema |
| 3 | Feitiços | Os 10 feitiços da seção 5 funcionando |
| 4 | Varinha com núcleo | Sistema 6.1 completo |
| 5 | Aprendizado por aula | Sistema 6.2 + primeira matéria |
| 6 | Primeiro mapa | Saguão + 1 sala de aula + pátio |

Regra: nada de mapear antes do fim de semana 6. Mapa é o buraco negro de tempo que
mata OT custom — só vale a pena com os sistemas já funcionando.

---

## 10. Nota sobre riscos

- **Sprites da CipSoft:** decisão consciente para a fase de protótipo. Risco baixo na
  prática, mas mantenha a camada de assets isolada para poder trocar depois.
- **Nomenclatura:** é onde mora o risco que importa. Seguir a seção 2 sem exceções.
- **Monetização:** donation shop transforma o projeto em comercial aos olhos de qualquer
  rightsholder. Se um dia for monetizar, revisar tudo antes.
- Nada disso é aconselhamento jurídico.
