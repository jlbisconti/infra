#!/bin/bash

# List all iptables rules with counters
sudo iptables -L -v -n --line-numbers > /tmp/iptables-rules.txt

# Display rules with 0 packets and bytes
echo "Unused iptables rules (0 packets and 0 bytes):"
awk '$1 ~ /^[0-9]+$/ && $2 == 0 && $3 == 0 {print "Rule " $1 " in chain " chain ": " $0}' chain="INPUT" /tmp/iptables-rules.txt
awk '$1 ~ /^[0-9]+$/ && $2 == 0 && $3 == 0 {print "Rule " $1 " in chain " chain ": " $0}' chain="FORWARD" /tmp/iptables-rules.txt
awk '$1 ~ /^[0-9]+$/ && $2 == 0 && $3 == 0 {print "Rule " $1 " in chain " chain ": " $0}' chain="OUTPUT" /tmp/iptables-rules.txt

# Clean up
rm /tmp/iptables-rules.txt
