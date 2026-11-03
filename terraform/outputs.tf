output "cluster_role_arn" {
  value = data.aws_iam_role.cluster.arn
}

output "node_role_arn" {
  value = data.aws_iam_role.node.arn
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_ids" {
  value = data.aws_subnets.eks.ids
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

