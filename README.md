# LGTM Platform Lab (KodeKloud AWS Playground)

Self-managed-node EKS cluster with kube-prometheus-stack, built from this repo.

## Rebuild order
1. `iam/`: create `eksClusterRole` and `AmazonEKSNodeRole` (trust policies + managed policies), then instance profile `ecsInstanceRole` containing the node role
2. `terraform/`: `terraform init && terraform apply` creates the EKS control plane
3. `aws eks create-access-entry --cluster-name lgtm-eks --principal-arn <node-role-arn> --type EC2_LINUX`
4. `nodes/`: `source vars.sh && ./launch-nodes.sh`, then `kubectl get nodes`
5. `monitoring/`: `helm install kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f values.yaml`

## Notes
- Playground blocks managed node groups and Fargate, so worker nodes are plain EC2 instances.
- Worker nodes are t2.medium because t2 runs in Standard CPU credit mode.
