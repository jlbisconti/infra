#!/bin/bash

RULES_FILE="/opt/suricata-7/etc/suricata/rules/tor-exit-block.rules"
TOR_LIST_URL="https://check.torproject.org/torbulkexitlist"
SID_BASE=2000000

echo "[+] Descargando lista de nodos de salida TOR..."
curl -s "$TOR_LIST_URL" | grep -Eo '^[0-9.]+$' > /tmp/tor_ips.txt

if [ ! -s /tmp/tor_ips.txt ]; then
    echo "[!] No se pudieron obtener IPs TOR. Abortando."
    exit 1
fi

echo "[+] Generando reglas DROP para Suricata..."
rm -f "$RULES_FILE"
SID=$SID_BASE
while read -r ip; do
    echo "drop ip $ip any -> \$HOME_NET any (msg:\"[DROP] TOR exit node $ip\"; sid:$SID; rev:1;)" >> "$RULES_FILE"
    ((SID++))
done < /tmp/tor_ips.txt

echo "[+] Reglas guardadas en: $RULES_FILE"
echo "[+] Reiniciando Suricata..."
systemctl restart suricata-q0 && echo "[✓] Suricata reiniciado con nuevas reglas TOR"
