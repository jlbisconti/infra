#!/usr/bin/env python3

import requests
import yaml
import os
from datetime import datetime, timedelta

HASHLIST_FILE = "/opt/suricata/etc/suricata/hashlist/hashes.yaml"
DAYS_TO_KEEP = 365
LOG_FILE = "/var/log/update_hashs_clamav.log"

def log(msg):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{now}] {msg}\n")

def cargar_hashes_existentes():
    if not os.path.exists(HASHLIST_FILE):
        return []
    with open(HASHLIST_FILE, "r") as f:
        data = yaml.safe_load(f) or {}
        return data.get("file_hashes", [])

def guardar_hashes_actualizados(hashlist):
    with open(HASHLIST_FILE, "w") as f:
        yaml.dump({"file_hashes": hashlist}, f)

def main():
    log("📥 Iniciando descarga de nuevos hashes desde MalwareBazaar...")
    url = "https://bazaar.abuse.ch/export/txt/sha256/recent/"
    response = requests.get(url)
    response.raise_for_status()
    nuevos_hashes = [line.strip() for line in response.text.splitlines() if line and not line.startswith("#")]

    hashlist = cargar_hashes_existentes()
    hashes_existentes = {entry["sha256"] for entry in hashlist}
    hoy = datetime.utcnow()

    nuevos = []
    sid_base = max([entry["sid"] for entry in hashlist], default=9000000)

    for h in nuevos_hashes:
        if h in hashes_existentes:
            continue
        sid_base += 1
        nuevos.append({
            "sha256": h,
            "action": "drop",
            "msg": f"MalwareBazaar SHA256 Match {h[:8]}...",
            "sid": sid_base,
            "rev": 1,
            "added": hoy.strftime("%Y-%m-%d")
        })

    hace_un_ano = hoy - timedelta(days=DAYS_TO_KEEP)
    hashlist_filtrada = []
    eliminados = 0

    for entry in hashlist:
        fecha = entry.get("added")
        if not fecha:
            hashlist_filtrada.append(entry)
            continue
        try:
            fecha_dt = datetime.strptime(fecha, "%Y-%m-%d")
            if fecha_dt >= hace_un_ano:
                hashlist_filtrada.append(entry)
            else:
                eliminados += 1
        except ValueError:
            hashlist_filtrada.append(entry)

    hashlist_actualizada = hashlist_filtrada + nuevos
    guardar_hashes_actualizados(hashlist_actualizada)

    log(f"💾 Agregados {len(nuevos)} nuevos hashes.")
    log(f"🧹 Eliminados {eliminados} hashes con más de {DAYS_TO_KEEP} días.")
    log("🔄 Reiniciando Suricata...")

    rc = os.system("systemctl restart suricata-q0")
    if rc == 0:
        log("✅ Suricata reiniciado correctamente.")
    else:
        log("❌ Error al reiniciar Suricata.")

if __name__ == "__main__":
    main()
