#!/bin/bash

echo "🛡️ Desactivando suspensión e hibernación en systemd-logind..."

cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak

sed -i '/^HandleSuspendKey/d' /etc/systemd/logind.conf
sed -i '/^HandleHibernateKey/d' /etc/systemd/logind.conf
sed -i '/^HandleLidSwitch/d' /etc/systemd/logind.conf
sed -i '/^HandleLidSwitchExternalPower/d' /etc/systemd/logind.conf
sed -i '/^HandleLidSwitchDocked/d' /etc/systemd/logind.conf

cat <<EOF >> /etc/systemd/logind.conf
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF

systemctl restart systemd-logind
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

echo "🎉 ¡Listo! El sistema ya no puede suspenderse ni hibernar."
