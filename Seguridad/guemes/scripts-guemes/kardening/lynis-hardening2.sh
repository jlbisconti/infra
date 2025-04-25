#!/bin/bash
# Script para seguir endureciendo el sistema y subir el hardening index con Lynis

set -e

echo "[+] Instalando y configurando auditd..."
apt install -y auditd audispd-plugins
systemctl enable auditd

cat > /etc/audit/rules.d/hardening.rules <<EOF
-w /etc/passwd -p wa -k passwd
-w /etc/shadow -p wa -k shadow
-w /etc/group -p wa -k group
-w /etc/gshadow -p wa -k gshadow
-w /etc/sudoers -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k ssh_config
EOF

auditctl -R /etc/audit/rules.d/hardening.rules
systemctl restart auditd
