#!/bin/bash

# Variables de configuración
PG_USER="suricata"
PG_DB="suricata"
PG_HOST="localhost"  # Cambia si tu servidor PostgreSQL está en otro host
PG_PORT="5432"        # Cambia si tu servidor PostgreSQL usa otro puerto
PG_PASSWORD="murdok44"

# Exportar la variable de entorno para la contraseña
export PGPASSWORD="$PG_PASSWORD"

# Comando para obtener el tamaño de la base de datos
psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$PG_DB" -c "SELECT pg_size_pretty(pg_database_size('$PG_DB')) AS db_size;"

# Limpiar la variable de entorno después de usarla
unset PGPASSWORD
