#!/bin/bash

mkdir -p ~/.kube 
touch ~/.kube/config

echo "${1}" > ~/.kube/config

export TAG="${2}"

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
    cp linux-amd64/helm /usr/local/bin/
else
    echo "already installed helm"
fi

helm upgrade --install welcome ./deploy/charts/welcome/ --set image.repository=knelasevero/wecolme --set image.tag=${TAG}
