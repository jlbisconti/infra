#!/bin/bash

# Banner legal que se mostrará antes del login
BANNER_TEXT="*** ATENCIÓN: Sistema restringido ***
Este sistema es para uso exclusivo de usuarios autorizados.
Toda actividad es registrada y monitoreada. El acceso no autorizado será penalizado."

# Crear /etc/issue
echo "$BANNER_TEXT" | sudo tee /etc/issue > /dev/null
# Crear /etc/issue.net
echo "$BANNER_TEXT" | sudo tee /etc/issue.net > /dev/null

# Verificar permisos adecuados
sudo chmod 644 /etc/issue /etc/issue.net

echo "[✔] Banners legales configurados correctamente en /etc/issue y /etc/issue.net"
