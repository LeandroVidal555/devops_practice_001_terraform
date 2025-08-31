#!/bin/bash
set -euo pipefail
dnf -y update

# kubectl
curl -L -o /usr/local/bin/kubectl https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl

# Quality of life
echo 'complete -C /usr/local/bin/kubectl kubectl' >> /etc/profile.d/kubectl.sh