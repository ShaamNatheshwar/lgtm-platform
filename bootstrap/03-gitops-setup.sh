#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deploy/argocd-server -n argocd --timeout=300s
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'

kubectl apply -f argocd/monitoring-app.yaml
kubectl apply -f argocd/extras-app.yaml

SG=$(aws eks describe-cluster --name lgtm-eks --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
ARGO_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
for P in 32000 $ARGO_PORT; do
  aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port "$P" --cidr 0.0.0.0/0 || true
done

echo "Node IPs:"
aws ec2 describe-instances --filters Name=tag:Name,Values=lgtm-node-* Name=instance-state-name,Values=running \
  --query 'Reservations[*].Instances[*].PublicIpAddress' --output text
echo "Grafana : http://<node-ip>:32000   (user admin)"
echo "Argo CD : https://<node-ip>:$ARGO_PORT   (user admin)"
echo "Argo password:"; kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "Grafana password:"; kubectl get secret kps-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d; echo
