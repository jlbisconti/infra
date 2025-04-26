#!/bin/bash

LOG="/var/log/guemes-gw.log"
exec > >(tee -a "$LOG") 2>&1

LAN_IFACE="lan"
WAN_IFACE="wan"
LAN_IP="10.10.10.5"
LAN_NETMASK="255.255.255.0"

echo "🕒 $(date '+%F %T') - [guemes-gw] Iniciando configuración..."

echo "🛠️ Configurando LAN ($LAN_IFACE)..."
/sbin/ip addr flush dev "$LAN_IFACE"
/sbin/ip addr add "$LAN_IP/$LAN_NETMASK" dev "$LAN_IFACE"
/sbin/ip link set "$LAN_IFACE" up

echo "⏳ Esperando DHCP en $WAN_IFACE..."
/sbin/ip link set "$WAN_IFACE" up
/sbin/dhclient "$WAN_IFACE"

for i in {1..15}; do
  if /sbin/ip -4 addr show dev "$WAN_IFACE" | grep -q "inet "; then
    echo "✅ WAN tiene IP:"
    /sbin/ip -4 addr show dev "$WAN_IFACE" | grep inet
    break
  fi
  sleep 1
done

echo "📡 Habilitando IP forwarding"
/bin/echo 1 > /proc/sys/net/ipv4/ip_forward
/bin/sed -i '/^#*net.ipv4.ip_forward/s/^#*//;s/0/1/' /etc/sysctl.conf
/sbin/sysctl -p

echo "🔥 Aplicando reglas iptables..."
/sbin/iptables -F
/sbin/iptables -t nat -F
/sbin/iptables -t nat -A POSTROUTING -o "$WAN_IFACE" -j MASQUERADE
/sbin/iptables -A FORWARD -i "$LAN_IFACE" -o "$WAN_IFACE" -j ACCEPT
/sbin/iptables -A FORWARD -i "$WAN_IFACE" -o "$LAN_IFACE" -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "💾 Guardando reglas iptables"
/sbin/iptables-save > /etc/iptables/rules.v4

echo "🌐 Verificando conectividad..."
if ping -c 2 -I "$WAN_IFACE" 1.1.1.1 >/dev/null; then
  echo "✅ Conectividad básica OK"
else
  echo "⚠️ No hay conectividad desde WAN. Reiniciando interfaz y reintentando..."
  /sbin/ip link set "$WAN_IFACE" down
  sleep 3
  /sbin/ip link set "$WAN_IFACE" up
  /sbin/dhclient "$WAN_IFACE"
  sleep 5

  if ping -c 2 -I "$WAN_IFACE" 1.1.1.1 >/dev/null; then
    echo "✅ Conectividad recuperada tras reiniciar WAN"
  else
    echo "❌ Aún sin conectividad tras reintentar. Revisar conexión o módem."
  fi
fi

echo "🌎 Obteniendo IP pública..."
PUBLIC_IP=$(curl -s --interface "$WAN_IFACE" https://ifconfig.me)
if [ -n "$PUBLIC_IP" ]; then
  echo "✅ IP pública: $PUBLIC_IP"
else
  echo "⚠️ No se pudo obtener la IP pública desde ifconfig.me"
fi

echo "🎉 $(date '+%F %T') - [guemes-gw] Configuración finalizada."
