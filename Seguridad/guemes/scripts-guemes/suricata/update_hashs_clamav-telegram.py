#!/usr/bin/env python3
import requests
import datetime
import subprocess
import logging
import os

# Config
TOR_EXIT_URL = "https://check.torproject.org/torbulkexitlist"
RULES_DIR = "/opt/suricata/var/lib/suricata/rules"
RULE_FILE = f"{RULES_DIR}/tor-exit-block.rules"
LOG_FILE = "/var/log/update_tor_rules.log"
TELEGRAM_TOKEN = "7893384536:AAHa-LQpW73QVyXM9UVk_mee-r9RBaZgvEY"
TELEGRAM_CHAT_ID = "2135636660"
SURICATA_RESTART_CMD = ["/bin/systemctl", "restart", "suricata-q0"]
SID_BASE = 10000000

# Logging setup
logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format='[%(asctime)s] %(message)s')

def log_and_print(msg):
    print(msg)
    logging.info(msg)

def enviar_telegram(msg):
    try:
        requests.post(f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage", data={
            "chat_id": TELEGRAM_CHAT_ID,
            "text": msg
        })
    except Exception as e:
        logging.error(f"❌ Error enviando a Telegram: {e}")

def descargar_ips_tor():
    response = requests.get(TOR_EXIT_URL)
    return [line.strip() for line in response.text.splitlines() if line and not line.startswith("#")]

def generar_reglas_tor(ips):
    reglas = []
    for i, ip in enumerate(ips):
        sid = SID_BASE + i
        regla = f'drop ip {ip} any -> $HOME_NET any (msg:"TOR Exit Node - {ip}"; sid:{sid}; rev:1;)'
        reglas.append(regla)
    return reglas

def guardar_reglas(rules):
    with open(RULE_FILE, "w") as f:
        f.write("\n".join(rules) + "\n")

def reiniciar_suricata():
    subprocess.run(SURICATA_RESTART_CMD)

def main():
    log_and_print("📥 Descargando lista de IPs Tor...")
    ips = descargar_ips_tor()
    log_and_print(f"📦 {len(ips)} IPs descargadas.")

    reglas = generar_reglas_tor(ips)
    guardar_reglas(reglas)
    log_and_print(f"🛡️ {len(reglas)} reglas generadas y guardadas en {RULE_FILE}")

    reiniciar_suricata()
    log_and_print("✅ Suricata reiniciado con nuevas reglas.")

    enviar_telegram(f"🛡️ Reglas Tor actualizadas: {len(reglas)} IPs bloqueadas. Suricata reiniciado.")

if __name__ == "__main__":
    main()