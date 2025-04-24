# 🛡️ Cómo deshabilitar la suspensión e hibernación en Debian 12 sin entorno gráfico

Este documento describe todos los pasos necesarios para evitar que el sistema entre en **modo suspensión o hibernación**, incluso por comandos manuales o eventos de hardware.

Ideal para servidores, gateways o firewalls que deben estar siempre activos, como el caso de **Guemes**.

---

## 🔧 Paso 1: Modificar la configuración de `logind`

Editamos el archivo de configuración de `systemd-logind`:

```bash
sudo nano /etc/systemd/logind.conf
```
Asegurate de que contenga las siguientes líneas sin comentar (#):

[Login]
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
 Si esas líneas ya existen pero están comentadas (# al inicio), eliminá el símbolo para activarlas.

Guardá y cerrá (Ctrl+O, Enter, luego Ctrl+X).

🔁 Paso 2: Reiniciar el servicio para aplicar los cambios

```bash
sudo systemctl restart systemd-logind
```
 Paso 3: Enmascarar los targets de suspensión e hibernación
Esto bloquea totalmente cualquier intento de suspender el sistema, incluso con comandos como systemctl suspend:

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```
 Paso 4: Verificar que la protección está activa
Comando para ver qué hace cada tecla/evento:

```bash
loginctl show-logind | grep Handle
```
Deberías ver:

```bash
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```
 Paso 5: Probar manualmente que no puede suspender
Intentá ejecutar:
```bash
sudo systemctl suspend
```
Esperá ver:
```bash
Call to Suspend failed: Access denied
```

(Opcional) Cómo revertir los cambios

Si más adelante querés permitir la suspensión o hibernación nuevamente:
```bash
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
```







