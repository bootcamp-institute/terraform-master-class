module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  private_subnets = [for i in range(0, var.num_subnets) : cidrsubnet(var.vpc_cidr_block, 8, i)]
  public_subnets  = [for i in range(var.num_subnets, var.num_subnets * 2) : cidrsubnet(var.vpc_cidr_block, 8, i)]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}

data "aws_availability_zones" "available" {
  state = "available"
}
