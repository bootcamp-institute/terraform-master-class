variable "region" {}
variable "app" {}
variable "env" {}
variable "tags" {
  type = map(string)
}

# Networking
variable "vpc_cidr_block" {}
variable "num_subnets" {}

# Application
variable "instance_type" {}
variable "asg_max_size" {}
variable "asg_min_size" {}
variable "asg_desired_capacity" {}
variable "key_name" {}
variable "amzn_linux_2_ami" {
  description = "Provide an AMI id or use latest word to use data source"
}
