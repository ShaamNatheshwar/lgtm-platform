#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export AWS_DEFAULT_REGION=us-east-1

make_role() {  # name, service, policies...
  local name=$1 svc=$2; shift 2
  aws iam get-role --role-name "$name" >/dev/null 2>&1 || aws iam create-role --role-name "$name" \
    --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"$svc\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null
  for p in "$@"; do aws iam attach-role-policy --role-name "$name" --policy-arn "arn:aws:iam::aws:policy/$p"; done
}
make_role eksClusterRole eks.amazonaws.com AmazonEKSClusterPolicy
make_role AmazonEKSNodeRole ec2.amazonaws.com AmazonEKSWorkerNodePolicy AmazonEKS_CNI_Policy AmazonEC2ContainerRegistryReadOnly

if ! aws iam get-instance-profile --instance-profile-name ecsInstanceRole >/dev/null 2>&1; then
  aws iam create-instance-profile --instance-profile-name ecsInstanceRole >/dev/null
  aws iam add-role-to-instance-profile --instance-profile-name ecsInstanceRole --role-name AmazonEKSNodeRole
fi
sleep 15   # IAM needs a moment to propagate

# EKS control plane and ECR (the slow part)
cd terraform
terraform init -input=false
terraform apply -auto-approve
cd ..

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws eks create-access-entry --cluster-name lgtm-eks \
  --principal-arn "arn:aws:iam::$ACCOUNT:role/AmazonEKSNodeRole" --type EC2_LINUX || true

# Node bootstrap config, built from the new cluster
CLUSTER=lgtm-eks
K8S_VERSION=$(aws eks describe-cluster --name $CLUSTER --query cluster.version --output text)
ENDPOINT=$(aws eks describe-cluster --name $CLUSTER --query cluster.endpoint --output text)
CA=$(aws eks describe-cluster --name $CLUSTER --query cluster.certificateAuthority.data --output text)
CIDR=$(aws eks describe-cluster --name $CLUSTER --query cluster.kubernetesNetworkConfig.serviceIpv4Cidr --output text)
CLUSTER_SG=$(aws eks describe-cluster --name $CLUSTER --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
AMI_ID=$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/$K8S_VERSION/amazon-linux-2023/x86_64/standard/recommended/image_id --query Parameter.Value --output text)

cat > /tmp/userdata.txt <<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${CLUSTER}
    apiServerEndpoint: ${ENDPOINT}
    certificateAuthority: ${CA}
    cidr: ${CIDR}

--BOUNDARY--
EOF

# One node in each of 3 zones (subnets looked up, not hardcoded)
i=1
for SUBNET in $(aws ec2 describe-subnets --filters Name=default-for-az,Values=true \
    Name=availability-zone,Values=us-east-1a,us-east-1b,us-east-1c --query 'Subnets[].SubnetId' --output text); do
  aws ec2 run-instances --count 1 --image-id "$AMI_ID" --instance-type t2.medium \
    --iam-instance-profile Name=ecsInstanceRole --security-group-ids "$CLUSTER_SG" \
    --subnet-id "$SUBNET" --user-data file:///tmp/userdata.txt \
    --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=20,VolumeType=gp2}' \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=lgtm-node-$i},{Key=kubernetes.io/cluster/lgtm-eks,Value=owned}]" \
    --query 'Instances[0].InstanceId' --output text
  i=$((i+1))
done

aws eks update-kubeconfig --name $CLUSTER
echo "Waiting for 3 Ready nodes..."
for n in $(seq 1 40); do
  READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready' || true)
  [ "$READY" -ge 3 ] && break; sleep 15
done
kubectl get nodes
