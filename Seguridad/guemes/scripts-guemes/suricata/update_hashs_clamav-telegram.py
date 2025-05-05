#!/usr/bin/env python3
import requests
import yaml
import os
import datetime
import subprocess
from pathlib import Path

# Configuraciones
URL = "https://bazaar.abuse.ch/export/txt/sha256/recent/"
HASHLIST_PATH = "/opt/suricata/etc/suricata/hashlist/hashes.yaml"
LOG_PATH = "/var/log/update_hashs_clamav.log"
TELEGRAM_TOKEN = "7893384536:AAHa-LQpW73QVyXM9UVk_mee-r9RBaZgvEY"
TELEGRAM_CHAT_ID = "2135636660"

def log(msg):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_PATH, "a") as log_file:
        log_file.write(f"[{timestamp}] {msg}\n")

def enviar_telegram(msg):
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    data = {"chat_id": TELEGRAM_CHAT_ID, "text": msg, "parse_mode": "Markdown"}
    try:
        requests.post(url, data=data)
    except Exception as e:
        log(f"❌ Error enviando mensaje a Telegram: {e}")

# Crear archivo si no existe
if not os.path.exists(HASHLIST_PATH):
    with open(HASHLIST_PATH, "w") as f:
        f.write("file_hashes:\n")

with open(HASHLIST_PATH, "r") as f:
    data = yaml.safe_load(f) or {}

if "file_hashes" not in data:
    data["file_hashes"] = []

hashlist = data["file_hashes"]
hashes_existentes = {entry["sha256"] for entry in hashlist}

# Descargar hashes
print("📥 Descargando nuevos hashes...")
response = requests.get(URL)
nuevos_hashes = [line.strip() for line in response.text.splitlines() if line and not line.startswith("#")]

agregados = 0
for sha256 in nuevos_hashes:
    if sha256 not in hashes_existentes:
        hashlist.append({
            "sha256": sha256,
            "action": "drop",
            "msg": f"MalwareBazaar SHA256 Match {sha256[:8]}...",
            "sid": 9000000 + len(hashlist) + 1,
            "rev": 1,
            "date_added": datetime.datetime.now().strftime("%Y-%m-%d")
        })
        agregados += 1

# Eliminar hashes con más de 12 meses
ahora = datetime.datetime.now()
original_len = len(hashlist)
hashlist = [
    h for h in hashlist
    if "date_added" in h and (ahora - datetime.datetime.strptime(h["date_added"], "%Y-%m-%d")).days <= 365
]
eliminados = original_len - len(hashlist)
data["file_hashes"] = hashlist

# Guardar YAML
with open(HASHLIST_PATH, "w") as f:
    yaml.dump(data, f, default_flow_style=False)

# Reiniciar Suricata
subprocess.run(["systemctl", "restart", "suricata-q0"])

# Log y Telegram
mensaje = (
    "📡 *Actualización de hashes para Suricata*\n"
    f"🟢 Nuevos agregados: `{agregados}`\n"
    f"🗑️ Hashes eliminados (más de 12 meses): `{eliminados}`\n"
    f"📊 Total actual: `{len(hashlist)}`\n"
    f"🕒 Fecha: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
)

print(mensaje)
log(mensaje)
enviar_telegram(mensaje)
