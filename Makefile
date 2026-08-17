ENGINE_REPO ?= https://github.com/MillhioreBT/forgottenserver-downgrade.git
ENGINE_REF  ?= main

.PHONY: help init build up down restart logs shell db-shell seed status clean

help:
	@echo "init      - clona o engine em ./server (rode uma vez)"
	@echo "build     - compila o engine dentro do container"
	@echo "up        - sobe banco + servidor + adminer"
	@echo "down      - derruba tudo"
	@echo "restart   - reinicia só o servidor (após mexer em Lua)"
	@echo "logs      - segue os logs do servidor"
	@echo "shell     - bash dentro do container do servidor"
	@echo "db-shell  - cliente mysql conectado no banco"
	@echo "seed      - cria a conta de desenvolvimento (admin/admin + god 'Deus')"
	@echo "status    - consulta o servidor e mostra o IP que ele anuncia aos clientes"
	@echo "clean     - remove build artifacts (mantém o banco)"

init:
	@test -f .env || (cp .env.example .env && echo ">> .env criado a partir do .env.example")
	@if [ -d server/.git ]; then \
		echo ">> ./server já existe, pulando clone."; \
	else \
		echo ">> Clonando $(ENGINE_REPO) ($(ENGINE_REF))..."; \
		git clone --depth 1 --branch $(ENGINE_REF) $(ENGINE_REPO) server; \
		rm -rf server/.git; \
		echo ">> Engine em ./server. O .git foi removido: esse código agora é seu."; \
	fi

build:
	docker compose --profile tools run --rm build

up:
	docker compose up -d db adminer
	docker compose up server

down:
	docker compose down

restart:
	docker compose restart server

logs:
	docker compose logs -f server

shell:
	docker compose exec server bash

db-shell:
	docker compose exec db sh -c 'mariadb -u"$$MARIADB_USER" -p"$$MARIADB_PASSWORD" "$$MARIADB_DATABASE"'

seed:
	docker compose exec -T db sh -c \
	  'mariadb -u"$$MARIADB_USER" -p"$$MARIADB_PASSWORD" "$$MARIADB_DATABASE"' < docker/seed-dev.sql
	@echo ">> Conta criada: admin / admin  (personagem: Deus)"

# Protocolo de status do TFS: 0x06 0x00 0xFF 0xFF + "info". Não é criptografado,
# então serve de teste de vida sem precisar de cliente. O atributo ip= da resposta
# é exatamente o endereço que o login server manda o cliente usar pro mundo.
status:
	@docker compose exec -T server sh -c \
	  'printf "\006\000\377\377info" | nc -w 2 127.0.0.1 7171'
	@echo

clean:
	rm -rf server/build
