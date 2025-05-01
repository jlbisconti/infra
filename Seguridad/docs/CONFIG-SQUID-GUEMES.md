
# Configuración exitosa de Squid 6.8 en Debian 12/13

> Última actualización: 2025-04-29 02:07:05

Este repositorio documenta los pasos que llevaron a una **instalación funcional de Squid 6.8** como proxy HTTP(S) interceptado sobre Debian.

## 🛠️ Pasos realizados

### 1. Configurar IPs

- LAN: `10.10.10.5/24`
- WAN: DHCP automático

### 2. Squid compilado e instalado en `/opt/squid-6.8`

Con soporte completo para:

- SSL Bump
- Intercept

### 3. Certificados para interceptación SSL

Ruta: `/opt/squid-6.8/ssl/cassl/cert-and-key.pem`

```bash
# Generar certificado raíz y firmar
openssl req -new -x509 -days 3650 -keyout private.key -out ca.crt
openssl x509 -in ca.crt -out proxyca.pem

# Crear certificado combinado
cat proxyca.pem private.key > cert-and-key.pem
```

**Nota:** Se debe instalar el certificado raíz en los dispositivos clientes para evitar advertencias HTTPS.

### 4. Configuración de `squid.conf` principal

```bash
http_port 10.10.10.5:4555
https_port 10.10.10.5:4556 intercept ssl-bump cert=/opt/squid-6.8/ssl/cassl/cert-and-key.pem generate-host-certificates=on dynamic_cert_mem_cache_size=4MB

sslcrtd_program /opt/squid-6.8/libexec/security_file_certgen -s /opt/squid-6.8/var/lib/ssl_db -M 4MB

acl host-infra src 10.10.10.0/24
acl net-vms src 10.10.100.0/25

http_access allow host-infra
http_access allow net-vms
http_access deny all

ssl_bump peek step1
ssl_bump bump step2
ssl_bump splice step3

tcp_outgoing_address 10.10.10.5
```

### 5. Configuración de servicio systemd (`/etc/systemd/system/squid.service`)

```bash
[Unit]
Description=Squid Web Proxy Server
After=network.target

[Service]
Type=forking
ExecStartPre=/bin/sleep 1
ExecStart=/opt/squid-6.8/sbin/squid -sYC
ExecReload=/opt/squid-6.8/sbin/squid -k reconfigure
ExecStop=/opt/squid-6.8/sbin/squid -k shutdown
PIDFile=/opt/squid-6.8/var/run/squid.pid
User=nobody
Group=nogroup
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```

### 6. Arreglos adicionales

- Permisos en `/opt/squid-6.8/var/run` y `/opt/squid-6.8/var/logs` para el usuario `nobody`.
- Inicialización del directorio de certificados SSL dinámicos:
  
  ```bash
  /opt/squid-6.8/libexec/security_file_certgen -c -s /opt/squid-6.8/var/lib/ssl_db -M 4MB
  chown -R nobody:nogroup /opt/squid-6.8/var/lib/ssl_db
  ```

### 7. Resultado final

✅ Squid funcionando en:
- HTTP intercept en `10.10.10.5:4555`
- HTTPS intercept en `10.10.10.5:4556`

Verificación de puertos:

```bash
ss -lntp | grep squid
```

---

## 🎯 Créditos

Trabajo en conjunto con **ChatGPT**  🚀 para lograr un Squid ninja listo para producción.

---

> ¡Que viva Guemes, el proxy y la libertad de navegar seguros! 🇦🇷
