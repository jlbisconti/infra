## Introduccion

En esta oportunidad vamos a realizar la copilacion y configuracion de el proxy Squid en la version 6.8. Tambien conforme avancen los dias se van a realizar diversar pruebas y customizaciones. Fundamentalmente voy a  a compilar y configurar Squid para funcionar en modo intercept de ssl a la par  de utilizarlo como nuevo servidor proxy de mi red.

## Escenario planteado

Vamos a comenzar a montar nuestro servidor proxy en nuestro equipo baremetal  con el siguiente detalle:

- 8 cores
- 8 GB de RAM
- 1 TB de disco NVME

En cuanto al Software utilizado el detalle es el siguiente:

- SO Debian 12 bookworm
- iptables v1.8.9
- Squid 6.8

## Descarga y compilacion de Squid 6.8

Comenzamos por descargar Squid 6.8 con el siguiente comando:

```
wget <https://www.squid-cache.org/Versions/v6/squid-6.8.tar.gz>
```

Una vez descargado lo descomprimimos en la carpeta destino elegida. En mi caso opte por usar /opt:

```
tar -zxvf squid-6.8.tar.gz
```

Ahora ingresamos en la carpeta generada por la  descompresion:

```
cd squid-6.8
```

## Compilacion de Squid 6.8

Para realizar la compilacion de Squid 6.8 con los features que necesitamos vamos correr primero el comando ./configure con los flags nevesarios:

```
 ./configure --with-openssl --enable-ssl-crtd --prefix=/opt/squid-6.8 --enable-ssl-bump --enable-transparent
```

En este comando vamos a configurar la instalacion con las opciones especificas que necesitamos, este es el detalle:

- --with-openssl: Incluir soporte para OpenSSL, necesario para manejar conexiones HTTPS.
- --enable-ssl-crtd: Habilita el daemon SSL certificate generator (ssl_crtd) para la generación de certificados SSL dinámicos.
- --prefix=/opt/squid-6.8: Especifica el directorio de instalación para Squid, en este caso, /opt/squid-6.8.
- --enable-ssl-bump: Activa la capacidad de inspección y modificación del tráfico HTTPS (SSL Bump).
- --enable-transparent: Permite a Squid operar en modo proxy transparente, interceptando el tráfico sin necesidad de configuración explícita del cliente.

Luego de que el comando ./configure con los flags necesarios corremos los comandos:

```
 make && make install
```

> Nota: Podemos correr los comandos por separado como forma de asegurarnos que ambos terminen sin errores. 


Al finalizar el proceso de compilacion vamos a poder verficar como quedaron los distintas carpetas:

Aquí tienes una explicación de los directorios en /opt/squid-6.8:

- bin: Contiene los ejecutables principales de Squid, como squid y otros comandos asociados.
- cassl: Almacena los certificados SSL utilizados por Squid para la interceptación y generación de certificados dinámicos.
- etc: Contiene los archivos de configuración de Squid, como squid.conf.
- libexec: Almacena módulos adicionales y scripts ejecutables que extienden las funcionalidades de Squid.
- sbin: Contiene ejecutables de administración de Squid.
- share: Almacena archivos de datos compartidos, como documentación y archivos de soporte.
- ssl: Contiene certificados SSL y claves privadas necesarias para la funcionalidad SSL.
- var: Almacena datos variables como logs, cachés y otros archivos temporales generados durante la operación de Squid.

## Armado de archivo squid.conf

Voy a comenza el armado del archivo squid.conf. Para ello me voy a posicionar en el path /opt/squid-6.8/etc. En esta oportunidad voy a crear un archivo squid.conf cusotmizado:

```yaml
# Redes Permitidas
acl host-infra src 10.10.10.0/24  # ACL para LAN equipos físicos
acl net-vms src 10.10.100.0/25    # ACL salida entorno virtualizado
acl step1 at_step SslBump1
acl step2 at_step SslBump2
acl step3 at_step SslBump3

# Puertos permitidos
acl SSL_ports port 443            # https
acl SSL_ports port 4556           # https a través de proxy
acl Safe_ports port 80            # http
acl Safe_ports port 4556          # https para intercept
acl Safe_ports port 4555          # Puerto en el que escucha el proxy
acl Safe_ports port 443           # https
acl Safe_ports port 1025-65535    # Puertos dinámicos
acl CONNECT method CONNECT

### ACLS filtros web
# Permitir ACLs
http_access allow host-infra
http_access allow net-vms
http_access allow localhost manager
http_access deny manager
http_access allow localhost

# Reglas SSL Bump
http_access allow step1
http_access allow step2
http_access allow step3

# Denegación de acceso por defecto
http_access deny all

# Configuración de Squid
error_directory /home/jlb/squid-6.8/errors/en/
workers 8
visible_hostname guemes

# Puertos HTTP y HTTPS
http_port 10.10.10.5:4555
https_port 10.10.10.5:4556 intercept ssl-bump cert=/opt/squid-6.8/cassl/proxyca.pem key=/opt/squid-6.8/cassl/private.key generate-host-certificates=on dynamic_cert_mem_cache_size=16MB

# Reglas SSL Bump
ssl_bump peek step1
ssl_bump bump step2
ssl_bump splice step3

# Cache y Logs
cache_log /opt/squid-6.8/var/logs/cache.log
access_log /opt/squid-6.8/var/logs/access.log
sslcrtd_program /opt/squid-6.8/libexec/security_file_certgen -s /opt/squid-6.8/ssl -M 128MB

### Optimizaciones
memory_cache_mode always
maximum_object_size_in_memory 1 MB
half_closed_clients off
max_filedescriptors 100000
maximum_object_size 4096 MB
## Seguridad
reply_body_max_size 4096 MB


refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern (cgi-bin|\?)    0       0%      0
refresh_pattern .               0       20%     4320

```

Este es el detalle de lso campos de mi archivo squid.conf:

- `acl host-infra src 10.10.10.0/24`: Define una lista de control de acceso (ACL) llamada `host-infra` que permite el tráfico desde la subred `10.10.10.0/24`, correspondiente a los equipos físicos en la LAN.
- `acl net-vms src 10.10.100.0/25`: Define una ACL llamada `net-vms` que permite el tráfico desde la subred `10.10.100.0/25`, correspondiente al entorno virtualizado.

- `acl SSL_ports port 443`: Define una ACL para el puerto 443, utilizado para HTTPS.
- `acl Safe_ports port 80`: Define una ACL para el puerto 80, utilizado para HTTP.
- `acl Safe_ports port 4556`: Define una ACL para el puerto 4556, utilizado para la interceptación HTTPS.
- `acl Safe_ports port 4555`: Define una ACL para el puerto 4555, en el que escucha el proxy.
- `acl directo method CONNECT`: Define una ACL para el método HTTP CONNECT, necesario para túneles SSL.

- `http_access allow host-infra`: Permite el acceso HTTP para la ACL `host-infra`.
- `http_access allow net-vms`: Permite el acceso HTTP para la ACL `net-vms`.
- `http_access allow localhost manager`: Permite el acceso al administrador desde localhost.
- `http_access deny manager`: Niega el acceso al administrador desde cualquier otra fuente.
- `http_access allow localhost`: Permite el acceso HTTP desde localhost.

- `http_access deny all`: Niega todo el acceso HTTP.
- `http_access deny CONNECT !SSL_ports`: Niega el método CONNECT para puertos no SSL.
- `http_access deny !Safe_ports`: Niega el acceso a puertos no seguros.

- `error_directory /home/jlb/squid-6.8/errors/en/`: Define el directorio de errores personalizados.
- `workers 8`: Define el número de trabajadores para el procesamiento de solicitudes.
- `visible_hostname guemes`: Define el nombre visible del proxy.
- `http_port 10.10.10.5:4555`: Configura Squid para escuchar en el puerto 4555 para HTTP.
- `https_port 10.10.10.5:4556 intercept ssl-bump cert=/opt/squid-6.8/cassl/proxyca.pem generate-host-certificates=on dynamic_cert_mem_cache_size=16MB`: Configura Squid para interceptar HTTPS en el puerto 4556, utilizando el certificado especificado y generando certificados dinámicamente.
- `acl step1 at_step SslBump1`: Define una ACL para el primer paso de SSL Bumping.
- `ssl_bump peek step1`: Inspecciona el tráfico SSL en el primer paso.
- `ssl_bump bump all`: Intercepta y desencripta todo el tráfico SSL.

- `cache_log /opt/squid-6.8/var/logs/cache.log`: Define el archivo de log de la caché.
- `access_log /opt/squid-6.8/var/logs/access.log`: Define el archivo de log de acceso.
- `sslcrtd_program /opt/squid-6.8/libexec/security_file_certgen -s /opt/squid-6.8/ssl -M 128MB`: Define el programa y los parámetros para la generación de certificados SSL.
- `memory_cache_mode always`: Configura el modo de caché en memoria.
- `maximum_object_size_in_memory 1 MB`: Define el tamaño máximo de objeto en memoria.
- `half_closed_clients off`: Desactiva la gestión de clientes semi-cerrados.
- `max_filedescriptors 4096`: Configura el número máximo de descriptores de archivo.
- `reply_body_max_size 4096 MB`: Define el tamaño máximo de respuesta permitido.

# Creacion de servicio systemd parab Squid

## Paso 1: Crear el archivo de servicio

Crear el archivo correspondiente en la ruta `/etc/systemd/system/squid.service` con el siguiente contenido:

```ini
[Unit]
Description=Squid Web Proxy Server
After=network-online.target

[Service]
Type=forking
ExecStart=/opt/squid-6.8/sbin/squid -sYC
ExecReload=/opt/squid-6.8/sbin/squid -k reconfigure
ExecStop=/opt/squid-6.8/sbin/squid -k shutdown
PIDFile=/opt/squid-6.8/var/run/squid.pid
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
```

## Descripción del servicio.
### After: Indica que el servicio debe iniciarse después de que el objetivo network-online.target esté activo.
[Service]

- `Type=forking`: Indica que el servicio se inicia con un proceso padre que se bifurca (fork).
- `ExecStart`: Comando para iniciar Squid con las opciones -sYC.
- `ExecReload`: Comando para recargar la configuración de Squid.
- `ExecStop`: Comando para detener Squid.
- `PIDFile`: Ruta del archivo que contiene el ID del proceso de Squid.
- `User y Group`: Usuario y grupo bajo los cuales se ejecuta el servicio.
[Install]

- `WantedBy:` Define el objetivo multi-user.target para que el servicio se inicie en el modo multiusuario.

Ejecutar el siguiente comando para recargar los archivos de configuración de systemd:

```
systemctl daemon-reload

```

## Generacion de certificados y keys

Antes de iniciar el nuevo servicio Squid necesitamos crear certificados y keys. Los comandos son los siguientes:

```
/opt/squid-6.8/libexec/security_file_certgen -c -s /opt/squid-6.8/ssl -M 128MB
 mkdir cassl
 openssl genrsa -out private.key 4096
 openssl req -new -x509 -days 10000 -key private.key  -subj '/C=AR/ST=BSAS/L=isidro/CN=GSVE' -out ca.crt
 mv ca.crt cassl/
 mv private.key cassl/
 cd cassl/
 cp ca.crt proxyca.pem
 cat private.key >>proxyca.pem
```


## Habilitar el servicio
Ejecutar el siguiente comando para habilitar el servicio de Squid para que se inicie automáticamente al arrancar el sistema:

```
systemctl enable squid --now
```
## Comprobar la persistencia
Para comprobar que el servicio se inicia correctamente después de un reinicio, reiniciar el sistema con:

```
reboot
```

# Comandos para gestionar Squid

## Reconfigurar Squid después de realizar cambios en squid.conf

Ejecutar el siguiente comando para recargar la configuración de Squid sin detener el servicio:

```sh
/opt/squid-6.8/sbin/squid -f /opt/squid-6.8/etc/squid.conf -k reconfigure

```



