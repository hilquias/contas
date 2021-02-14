include .env

.PHONY: start deploy create-db drop-db

start:
	postgrest finances_api.conf

deploy: | create-db
	psql -f finances.sql -f finances_api.sql

create-db:
	createdb

drop-db:
	dropdb $(PGDATABASE)

.EXPORT_ALL_VARIABLES:
