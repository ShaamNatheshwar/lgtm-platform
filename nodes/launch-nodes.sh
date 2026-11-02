#!/bin/bash
# Launches 3 self-managed EKS worker nodes, one per AZ. Run: source vars.sh first.
i=1
for SUBNET in subnet-0132c0be56f27b0c7 subnet-02023357a512f7f67 subnet-070b5f26895037e62; do
  aws ec2 run-instances --count 1 --image-id $AMI_ID --instance-type t2.medium \
    --iam-instance-profile Name=ecsInstanceRole --security-group-ids $CLUSTER_SG \
    --subnet-id $SUBNET --user-data file://userdata.txt \
    --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=20,VolumeType=gp2}' \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=lgtm-node-$i},{Key=kubernetes.io/cluster/lgtm-eks,Value=owned}]" \
    --query 'Instances[0].[InstanceId,Placement.AvailabilityZone]' --output text
  i=$((i+1))
done
