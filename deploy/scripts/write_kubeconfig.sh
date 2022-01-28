#!/bin/bash

mkdir -p ~/.kube 
touch ~/.kube/config
echo "${KUBECONFIGCONTENT}" > ~/.kube/config
chmod 600 ~/.kube/config
