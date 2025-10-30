#!/bin/bash

# https://dev.to/danielcristho/k3d-getting-started-with-argocd-5c6l

k3d cluster create bonus --agents 1
kubectl create namespace argocd
kubectl create namespace dev
kubectl create namespace gitlab

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait -n argocd --for=condition=available deployment --all --timeout=3m

# To print the initial password generated for admin user

echo $'ArgoCD username: admin\n'
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

# To access the ArgoCD UI ; 'nohup' unlinks the process from terminal ; '&' runs it in background
nohup kubectl port-forward -n argocd svc/argocd-server 8080:443 > will_argocd.log 2>&1 &

echo $'\nInstalling GitLab...\n'
helm repo add gitlab http://charts.gitlab.io/
helm install gitlab gitlab/gitlab --namespace gitlab -f ./confs/gitlab_values.yaml

kubectl wait -n gitlab --for=condition=available deployment/gitlab-webservice-default --timeout=15m 2>/dev/null

kubectl apply -f ./confs/gitlab_ingress.yaml

echo $'GitLab username: root\n'
echo "Password: $(kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 -d)"

# kubectl apply -f ./confs/app_wil_argoCD.yaml

# while ! kubectl get svc playground-service -n dev >/dev/null 2>&1; do
#     echo "Waiting for service playground-service..."
#     sleep 5
# done

# kubectl wait -n dev --for=condition=available deployment/playground --timeout=2m 2>/dev/null
# nohup kubectl port-forward -n dev svc/playground-service 8081:8888 > will_playground.log 2>&1 &