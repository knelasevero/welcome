#!/bin/bash

export TAG="${1}"

export NS="${$2}"

if ! type "kubectl" > /dev/null; then
    # Install Kubectl
    echo "kubectl not found. Installing it."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
else
    echo "already installed kubectl"
fi

if ! type "helm" > /dev/null; then
    # Install Helm
    echo "helm not found. Installing it."
    curl https://get.helm.sh/helm-v3.8.0-linux-amd64.tar.gz -o helm-v3.8.0-linux-amd64.tar.gz
    tar -zxvf helm-v3.8.0-linux-amd64.tar.gz
    chmod +x linux-amd64/helm
    sudo cp linux-amd64/helm /usr/local/bin/
else
    echo "already installed helm"
fi

if [[ -z "${NS}" ]]; then
  NS="devops-challenge"
fi

# Creates namespace if it does not exist
kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -

# Bumb chart version
sed -i "s|version: [^ ]*|version: \"${TAG}\"|g" deploy/charts/welcome/Chart.yaml
sed -i "s|appVersion: [^ ]*|appVersion: \"v${TAG}\"|g" deploy/charts/welcome/Chart.yaml

# Helm install for this tag/chart version
helm upgrade --install welcome ./deploy/charts/welcome/ --set image.repository=knelasevero/wecolme --set image.tag=${TAG} -n "${NS}"

# Undo bump locally (so there is no risk of pushing it)
sed -i "s|version: [^ ]*|version: \"x.x.x\"|g" deploy/charts/welcome/Chart.yaml
sed -i "s|appVersion: [^ ]*|appVersion: \"vx.x.x\"|g" deploy/charts/welcome/Chart.yaml
