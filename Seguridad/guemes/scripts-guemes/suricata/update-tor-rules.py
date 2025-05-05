#!/usr/bin/env python3
import requests
import datetime
import subprocess

# Configuraciones
TOR_EXIT_URL = "https://check.torproject.org/torbulkexitlist"
RULES_FILE = "/opt/suricata/var/lib/suricata/rules/tor-exit-block.rules"
SURICATA_RESTART_CMD = ["systemctl", "restart", "suricata-q0"]

def descargar_ips_tor():
    print("📥 Descargando lista de nodos de salida TOR...")
    response = requests.get(TOR_EXIT_URL)
    response.raise_for_status()
    return [ip.strip() for ip in response.text.splitlines() if ip.strip() and not ip.startswith("#")]

def generar_reglas_tor(ips):
    fecha = datetime.datetime.now().strftime("%Y-%m-%d")
    reglas = []
    sid_base = 5000000
    for i, ip in enumerate(ips, start=1):
        reglas.append(
            f'drop ip [{ip}] any -> $HOME_NET any (msg:"TOR Exit Node {ip} bloqueado"; sid:{sid_base + i}; rev:1; metadata:created_at {fecha};)'
        )
    return reglas

def guardar_reglas(reglas):
    print(f"💾 Guardando {len(reglas)} reglas en {RULES_FILE}...")
    with open(RULES_FILE, "w") as f:
        for regla in reglas:
            f.write(regla + "\n")

def reiniciar_suricata():
    print("🔄 Reiniciando Suricata...")
    subprocess.run(SURICATA_RESTART_CMD)

def main():
    try:
        ips = descargar_ips_tor()
        reglas = generar_reglas_tor(ips)
        guardar_reglas(reglas)
        reiniciar_suricata()
        print(f"✅ Listo. Se generaron {len(reglas)} reglas.")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
