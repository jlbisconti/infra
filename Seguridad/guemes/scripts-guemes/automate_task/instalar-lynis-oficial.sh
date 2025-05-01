#!/bin/bash

echo "[+] Descargando clave GPG oficial de Lynis..."
curl -s https://packages.cisofy.com/keys/cisofy-software-public.key -o /tmp/cisofy.key

echo "[+] Convertiendo clave a formato GPG..."
gpg --dearmor /tmp/cisofy.key

echo "[+] Moviendo clave a /usr/share/keyrings/..."
mv /tmp/cisofy.key.gpg /usr/share/keyrings/cisofy-archive-keyring.gpg

echo "[+] Agregando repositorio oficial de Lynis..."
echo "deb [signed-by=/usr/share/keyrings/cisofy-archive-keyring.gpg] https://packages.cisofy.com/community/lynis/deb/ stable main" > /etc/apt/sources.list.d/cisofy-lynis.list

echo "[+] Actualizando repositorios..."
apt update

echo "[+] Instalando o actualizando Lynis..."
apt install -y lynis

echo "[+] Versión instalada:"
lynis --version

echo "[✔] ¡Listo! Lynis quedó instalado desde el repositorio oficial de CISOfy."
