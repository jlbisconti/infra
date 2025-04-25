#!/bin/bash

# Script para endurecer la configuración de SSH según recomendaciones de Lynis

SSH_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak"

echo "Realizando backup de $SSH_CONFIG en $BACKUP_CONFIG..."
cp $SSH_CONFIG $BACKUP_CONFIG

echo "Aplicando configuraciones recomendadas por Lynis..."

# Establecer valores recomendados o modificarlos si existen
sed -i 's/^#\?AllowTcpForwarding.*/AllowTcpForwarding no/' $SSH_CONFIG || echo "AllowTcpForwarding no" >> $SSH_CONFIG
sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 2/' $SSH_CONFIG || echo "ClientAliveCountMax 2" >> $SSH_CONFIG
sed -i 's/^#\?LogLevel.*/LogLevel VERBOSE/' $SSH_CONFIG || echo "LogLevel VERBOSE" >> $SSH_CONFIG
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' $SSH_CONFIG || echo "MaxAuthTries 3" >> $SSH_CONFIG
sed -i 's/^#\?MaxSessions.*/MaxSessions 2/' $SSH_CONFIG || echo "MaxSessions 2" >> $SSH_CONFIG
sed -i 's/^#\?TCPKeepAlive.*/TCPKeepAlive no/' $SSH_CONFIG || echo "TCPKeepAlive no" >> $SSH_CONFIG
sed -i 's/^#\?AllowAgentForwarding.*/AllowAgentForwarding no/' $SSH_CONFIG || echo "AllowAgentForwarding no" >> $SSH_CONFIG

echo "Reiniciando el servicio SSH..."
systemctl restart ssh || systemctl restart sshd

echo "✅ Configuración endurecida aplicada exitosamente."
