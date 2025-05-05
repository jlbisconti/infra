#!/bin/bash

# Ruta de salida para el archivo .rules
OUTFILE="/opt/suricata/var/lib/suricata/rules/clamav_hashes.rules"
> "$OUTFILE"

echo "[+] Generando reglas DROP de Suricata a partir de firmas de ClamAV..."

# Buscar archivos con firmas
HASHFILES=$(find /var/lib/clamav -type f \( -name '*.hdb' -o -name '*.ndb' -o -name '*.ldb' \))

SID_BASE=4000000
SID=$SID_BASE

# Procesar cada archivo de firmas
for file in $HASHFILES; do
  while IFS= read -r line; do
    HASH=$(echo "$line" | grep -Eo '^[a-fA-F0-9]{32,64}$')
    if [[ "$HASH" != "" ]]; then
      case ${#HASH} in
        32)
          echo "drop http any any -> any any (msg:\"ClamAV match (MD5) $HASH\"; filemd5:$HASH; sid:$SID; rev:1;)" >> "$OUTFILE"
          ;;
        40)
          echo "drop http any any -> any any (msg:\"ClamAV match (SHA1) $HASH\"; filesha1:$HASH; sid:$SID; rev:1;)" >> "$OUTFILE"
          ;;
        64)
          echo "drop http any any -> any any (msg:\"ClamAV match (SHA256) $HASH\"; filesha256:$HASH; sid:$SID; rev:1;)" >> "$OUTFILE"
          ;;
      esac
      ((SID++))
    fi
  done < <(cut -d: -f1 "$file")
done

echo "[✓] Reglas generadas en: $OUTFILE"
root@Guemes:/home/jlb#
root@Guemes:/home/jlb# cat scripts-guemes/generate_clamav_suricata_rules.sh
#!/bin/bash

# Ruta de salida para el archivo .rules
OUTFILE="/opt/suricata/var/lib/suricata/rules/clamav_hashes.rules"
> "$OUTFILE"

echo "[+] Generando reglas DROP de Suricata a partir de firmas de ClamAV..."

# Buscar archivos con firmas
HASHFILES=$(find /var/lib/clamav -type f \( -name '*.hdb' -o -name '*.ndb' -o -name '*.ldb' \))

SID_BASE=4000000
SID=$SID_BASE

# Procesar cada archivo de firmas
for file in $HASHFILES; do
  while IFS= read -r line; do
    HASH=$(echo "$line" | grep -Eo '^[a-fA-F0-9]{32,64}$')
    if [[ "$HASH" != "" ]]; then
      case ${#HASH} in
        32)
          echo "drop http any any -> any any (msg:\"ClamAV match (MD5) $HASH\"; filemd5:$HASH; sid:$SID; rev:1;)" >> "$OUTFILE"
          ;;
        40)
          echo "drop http any any -> any any (msg:\"ClamAV match (SHA1) $HASH\"; filesha1:$HASH; sid:$SID; rev:1;)" >> "$OUTFILE"
          ;;
        64)
          echo "drop http any any -> any any (msg:\"ClamAV match (SHA256) $HASH\"; filesha256:$HASH; sid:$SID; rev:1;)" >> "$OUTFILE"
          ;;
      esac
      ((SID++))
    fi
  done < <(cut -d: -f1 "$file")
done

echo "[✓] Reglas generadas en: $OUTFILE"