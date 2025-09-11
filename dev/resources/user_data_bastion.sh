#!/bin/bash
echo "###### STARTING USER DATA RUN $(date)"
set -euo pipefail
dnf -y update

KARCH=arm64
VER="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"

curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${VER}/bin/linux/${KARCH}/kubectl"
chmod +x /usr/local/bin/kubectl

# Quality of life
echo 'complete -C /usr/local/bin/kubectl kubectl' >> /etc/profile.d/kubectl.sh
echo "###### ENDED USER DATA RUN $(date)"