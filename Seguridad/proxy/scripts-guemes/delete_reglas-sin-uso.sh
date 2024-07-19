#!/bin/bash

# List all iptables rules with counters
sudo iptables -L -v -n --line-numbers > /tmp/iptables-rules.txt

# Display and delete rules with 0 packets and 0 bytes
echo "Deleting unused iptables rules (0 packets and 0 bytes):"

delete_unused_rules() {
    chain=$1
    # List rules in reverse order to avoid changing line numbers while deleting
    for line_number in $(awk '$1 ~ /^[0-9]+$/ && $2 == 0 && $3 == 0 {print $1}' chain="$chain" /tmp/iptables-rules.txt | sort -rn); do
        echo "Deleting rule $line_number in chain $chain"
        sudo iptables -D $chain $line_number
    done
}

delete_unused_rules INPUT
delete_unused_rules FORWARD
delete_unused_rules OUTPUT

# Clean up
rm /tmp/iptables-rules.txt

# Guardar cambios en archivo rules.v4

iptables-save > /etc/iptables/rules.v4
