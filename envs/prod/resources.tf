locals {
  name             = "${var.app}-${var.env}"
  amzn_linux_2_ami = var.amzn_linux_2_ami == "latest" ? data.aws_ami.amazon_linux_2.id : var.amzn_linux_2_ami
}

module "networking" {
  source = "../../modules/networking"

  name           = local.name
  vpc_cidr_block = var.vpc_cidr_block
  num_subnets    = var.num_subnets
}

module "application" {
  source = "../../modules/application"

  name                 = local.name
  amzn_linux_2_ami     = local.amzn_linux_2_ami
  instance_type        = var.instance_type
  subnets              = module.networking.vpc_info.public_subnets
  target_group_arn     = module.networking.lb_info.challenge_tg
  asg_max_size         = var.asg_max_size
  asg_min_size         = var.asg_min_size
  asg_desired_capacity = var.asg_desired_capacity
  key_name             = var.key_name
  security_groups = [
    module.networking.security_groups.http_internal,
    module.networking.security_groups.outbound_external,
  ]
  tags = merge(var.tags, { Name = local.name })
}
