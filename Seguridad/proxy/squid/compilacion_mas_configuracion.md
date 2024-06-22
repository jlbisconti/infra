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

### Descarga y compilacion de Squid 6.8

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

### Compilacion de Squid 6.8

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
