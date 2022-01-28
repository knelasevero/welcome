#!/bin/bash

export server=$(echo "${KUBECONFIGCONTENT}" | grep server)

mkdir -p ~/.kube 
touch ~/.kube/config
chmod 600 ~/.kube/config

if grep -q "$server" "$HOME/.kube/config"; then
    echo "server already configured."
else
    echo "writing kubeconfig."
    echo "${KUBECONFIGCONTENT}" > ~/.kube/config
fi

