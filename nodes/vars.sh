export CLUSTER=lgtm-eks
export K8S_VERSION=$(aws eks describe-cluster --name $CLUSTER --query cluster.version --output text)
export ENDPOINT=$(aws eks describe-cluster --name $CLUSTER --query cluster.endpoint --output text)
export CA=$(aws eks describe-cluster --name $CLUSTER --query cluster.certificateAuthority.data --output text)
export CIDR=$(aws eks describe-cluster --name $CLUSTER --query cluster.kubernetesNetworkConfig.serviceIpv4Cidr --output text)
export CLUSTER_SG=$(aws eks describe-cluster --name $CLUSTER --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
export AMI_ID=$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/$K8S_VERSION/amazon-linux-2023/x86_64/standard/recommended/image_id --query Parameter.Value --output text 2>/dev/null || aws ec2 describe-images --owners amazon --filters "Name=name,Values=amazon-eks-node-al2023-x86_64-standard-${K8S_VERSION}-*" --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text)
