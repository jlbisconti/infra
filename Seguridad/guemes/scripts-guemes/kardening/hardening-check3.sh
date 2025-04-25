# Script para aplicar medidas de endurecimiento recomendadas por Lynis (sin modificar GRUB)

set -e

# 1. Aumentar rondas de hash para contraseñas
sed -i 's/^\(SHA_CRYPT_MIN_ROUNDS\).*/\1 640000/' /etc/login.defs || echo "SHA_CRYPT_MIN_ROUNDS 640000" >> /etc/login.defs
sed -i 's/^\(SHA_CRYPT_MAX_ROUNDS\).*/\1 640000/' /etc/login.defs || echo "SHA_CRYPT_MAX_ROUNDS 640000" >> /etc/login.defs

# 2. Deshabilitar drivers de almacenamiento externo innecesarios
if ! grep -q 'install usb-storage /bin/true' /etc/modprobe.d/disable-usb-storage.conf; then
  echo 'install usb-storage /bin/true' >> /etc/modprobe.d/disable-usb-storage.conf
fi

# 3. DNS config placeholder (debe revisarse manualmente si se requiere dominio local)
echo "[INFO] Verificá tu configuración DNS en /etc/resolv.conf o /etc/systemd/resolved.conf"

# 4. Aplicar reglas SHA512 en AIDE
sed -i 's/^Checksums.*/Checksums = sha512/' /etc/aide/aide.conf

# 5. Agregar banners legales
cat << 'EOF' > /etc/issue
Autorización requerida. El acceso no autorizado está prohibido.
EOF

cat << 'EOF' > /etc/issue.net
Autorización requerida. El acceso no autorizado está prohibido.
EOF

# 6. Endurecer compilers: restringir acceso
chmod o-rwx /usr/bin/gcc || true
chmod o-rwx /usr/bin/cc || true

# 7. Habilitar process accounting (acct)
apt-get install acct -y
systemctl enable acct
systemctl start acct

# 8. Activar freshclam con actualizaciones automáticas
sed -i 's/^Checks.*/Checks 12/' /etc/clamav/freshclam.conf || true
systemctl enable clamav-freshclam.service
systemctl restart clamav-freshclam.service

# 9. Revisión de permisos estrictos en /home
chmod 750 /home/* || true

# 10. Configuración automática de upgrades (unattended-upgrades)
apt-get install unattended-upgrades -y
systemctl enable unattended-upgrades

# 11. Mensaje final
echo "[+] Endurecimiento aplicado. Revisá manualmente cualquier mensaje de advertencia."
echo "Podés volver a correr 'lynis audit system' para verificar los cambios."

exit 0
