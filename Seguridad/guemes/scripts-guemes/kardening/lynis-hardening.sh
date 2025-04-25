#!/bin/bash

echo "[+] Aplicando mejoras de seguridad sugeridas por Lynis..."

# 1. Establecer permisos más estrictos por defecto (umask 027)
sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs

# 2. Configurar expiración de contraseñas para cuentas actuales
for user in $(awk -F: '$2 ~ /^\$/ {print $1}' /etc/shadow); do
    chage --maxdays 90 --warndays 7 "$user"
done

# 3. Instalar y configurar auditd
apt-get update && apt-get install -y auditd audispd-plugins
systemctl enable auditd
systemctl start auditd

# 4. Instalar sysstat para accounting
apt-get install -y sysstat
sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
systemctl enable sysstat
systemctl start sysstat

# 5. Instalar debsums para verificación de paquetes
apt-get install -y debsums

# 6. Instalar herramienta de integridad de archivos (aide)
apt-get install -y aide
aideinit
cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# 7. Banners legales
echo "ACCESO RESTRINGIDO: Todo acceso no autorizado será registrado y sancionado." > /etc/issue
echo "ACCESO RESTRINGIDO: Todo acceso no autorizado será registrado y sancionado." > /etc/issue.net

# 8. Desactivar módulos no necesarios (ejemplo: usb-storage)
echo "blacklist usb-storage" > /etc/modprobe.d/disable-usb-storage.conf

# 9. Agregar valores básicos a sysctl.conf si no existen
SYSCTL_FILE="/etc/sysctl.d/99-hardening.conf"
echo "kernel.randomize_va_space = 2" >> "$SYSCTL_FILE"
echo "fs.protected_hardlinks = 1" >> "$SYSCTL_FILE"
echo "fs.protected_symlinks = 1" >> "$SYSCTL_FILE"
sysctl -p "$SYSCTL_FILE"

echo "[+] Listo. Por favor, reiniciá el sistema o servicios afectados para que todos los cambios tengan efecto."
