#!/bin/bash

# https://dev.to/danielcristho/k3d-getting-started-with-argocd-5c6l

k3d cluster create bonus2 --agents 1

kubectl create namespace argocd
kubectl create namespace gitlab
kubectl create namespace dev

echo $'\nInstalling ArgoCD...'
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait -n argocd --for=condition=available deployment --all --timeout=3m

# To print the initial password generated for admin user
echo $'\nArgoCD admin password:'
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

echo $'\nStarting ArgoCD port-forward on localhost:8080...'
nohup kubectl port-forward -n argocd svc/argocd-server 8080:443 > argocd.log 2>&1 &

echo $'\nAdding GitLab Helm repository...'
helm repo add gitlab https://charts.gitlab.io/
helm repo update

echo $'\nInstalling GitLab...'
helm install gitlab gitlab/gitlab --namespace gitlab -f ./confs/gitlab_values.yaml

echo $'\nWaiting for GitLab webservice to be ready...'
kubectl wait -n gitlab --for=condition=available deployment/gitlab-webservice-default --timeout=15m

echo $'\nApplying GitLab ingress configuration...'
kubectl apply -f ./confs/gitlab_ingress.yaml

echo $'\nGetting GitLab root password...'
echo "GitLab root password:"
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 -d
echo ""

echo $'\nStarting GitLab port-forward on localhost:8082...'
nohup kubectl port-forward -n gitlab svc/gitlab-webservice-default 8082:8181 > gitlab.log 2>&1 &

echo $'\n=== Setup Complete ==='
echo "ArgoCD UI: https://localhost:8080 (admin / see password above)"
echo "GitLab UI: http://localhost:8082 (root / see password above)"
echo ""
echo "To add gitlab.local to /etc/hosts for internal cluster access:"
echo "echo '127.0.0.1 gitlab.local' | sudo tee -a /etc/hosts"
