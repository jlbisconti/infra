#!/bin/bash

# Ruta donde guardar copias de seguridad de los archivos de servicio
BACKUP_DIR="/etc/systemd/system-hardened-backups"
mkdir -p "$BACKUP_DIR"

# Servicios que endureceremos (agregá más si querés)
SERVICIOS=(
  ssh.service
  fail2ban.service
  unbound.service
  clamav-daemon.service
  squid.service
  suricata-q0.service
  cron.service
)

for svc in "${SERVICIOS[@]}"; do
    echo "⚙️  Endureciendo $svc..."

    ORIG_FILE="/lib/systemd/system/$svc"
    DEST_FILE="/etc/systemd/system/$svc"

    # Hacemos backup
    if [[ -f "$ORIG_FILE" ]]; then
        cp "$ORIG_FILE" "$BACKUP_DIR/$svc"
        cp "$ORIG_FILE" "$DEST_FILE"
    elif [[ ! -f "$DEST_FILE" ]]; then
        echo "❌ No se encontró el archivo del servicio $svc, saltando..."
        continue
    fi

    # Agregamos configuraciones de seguridad si no existen
    grep -q 'NoNewPrivileges=' "$DEST_FILE" || echo 'NoNewPrivileges=true' >> "$DEST_FILE"
    grep -q 'PrivateTmp=' "$DEST_FILE" || echo 'PrivateTmp=true' >> "$DEST_FILE"
    grep -q 'ProtectSystem=' "$DEST_FILE" || echo 'ProtectSystem=strict' >> "$DEST_FILE"
    grep -q 'ProtectHome=' "$DEST_FILE" || echo 'ProtectHome=yes' >> "$DEST_FILE"
    grep -q 'ProtectControlGroups=' "$DEST_FILE" || echo 'ProtectControlGroups=yes' >> "$DEST_FILE"
    grep -q 'ProtectKernelModules=' "$DEST_FILE" || echo 'ProtectKernelModules=yes' >> "$DEST_FILE"
    grep -q 'ProtectKernelTunables=' "$DEST_FILE" || echo 'ProtectKernelTunables=yes' >> "$DEST_FILE"

    echo "🔁 Recargando configuración..."
    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl restart "$svc"

    echo "✅ $svc endurecido con éxito"
    echo "-----------------------------------"
done

echo "🏁 Hardening completo. Reiniciá el sistema si querés validar comportamiento a fondo."
