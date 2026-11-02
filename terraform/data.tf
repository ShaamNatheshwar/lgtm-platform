# Roles created in Steps 13 and 14
data "aws_iam_role" "cluster" {
  name = "eksClusterRole"
}

data "aws_iam_role" "node" {
  name = "AmazonEKSNodeRole"
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Subnets for EKS. us-east-1e is left out because EKS can't put its
# control plane there.
data "aws_subnets" "eks" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  }
}
