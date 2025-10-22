#!/bin/bash
echo "###### STARTING USER DATA RUN $(date)..."
set -euo pipefail
dnf -y update

KARCH=arm64
VER="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"

curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${VER}/bin/linux/${KARCH}/kubectl"
chmod +x /usr/local/bin/kubectl

# Enable kubectl bash completion
echo 'complete -C /usr/local/bin/kubectl kubectl' >> /etc/profile.d/kubectl.sh

# --- Install Helm ---
HELM_VERSION="$(curl -fsSL https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d '"' -f4)"
curl -fsSL -o /tmp/helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-${KARCH}.tar.gz"

tar -zxvf /tmp/helm.tar.gz -C /tmp
mv "/tmp/linux-${KARCH}/helm" /usr/local/bin/helm
chmod +x /usr/local/bin/helm

# Clean up
rm -rf /tmp/helm.tar.gz "/tmp/linux-${KARCH}"

echo "###### ENDED USER DATA RUN $(date)"