#!/bin/bash

echo "[+] Configurando ruteo en guemes..."

# 1. Borrar ruta por Forti si existe
ip route del default via 10.10.10.1 dev lan 2>/dev/null && \
echo "[✓] Ruta por Forti eliminada"

# 2. Agregar ruta default por WAN si no está
ip route | grep -q "default via 192.168.100.1" || {
    ip route add default via 192.168.100.1 dev wan
    echo "[✓] Ruta por WAN agregada"
}

# 3. Asegurar NAT por WAN
iptables -t nat -C POSTROUTING -o wan -j MASQUERADE 2>/dev/null || {
    iptables -t nat -A POSTROUTING -o wan -j MASQUERADE
    echo "[✓] NAT habilitado por WAN"
}

# 4. (Opcional) Bloquear salida directa al Forti desde LAN
iptables -C FORWARD -s 10.10.10.0/24 -d 10.10.10.1 -j REJECT 2>/dev/null || {
    iptables -A FORWARD -s 10.10.10.0/24 -d 10.10.10.1 -j REJECT
    echo "[✓] Bloqueo de reenvío directo a Forti agregado"
}

# 5. Mostrar estado final
echo
echo "[✓] Configuración de ruteo completada"
ip route | grep default
iptables -t nat -L POSTROUTING -n -v --line-numbers | grep MASQUERADE
