DATABASE_URL ?= postgresql://postgres:postgres@localhost:54329/iris

export DATABASE_URL

.PHONY: db-up db-down wait reset migrate seed verify test

db-up:
	docker compose up -d db

db-down:
	docker compose down

wait:
	./scripts/wait_for_db.sh

reset: db-up wait
	./scripts/reset_db.sh

migrate: db-up wait
	./scripts/migrate.sh

seed:
	./scripts/seed.sh

verify:
	./scripts/verify.sh

test: verify
	python -m pytest
