variable "name" {}
variable "amzn_linux_2_ami" {}
variable "instance_type" {}
variable "subnets" {}
variable "target_group_arn" {}
variable "asg_max_size" {}
variable "asg_min_size" {}
variable "asg_desired_capacity" {}
variable "key_name" {
  default     = ""
  description = "Empty string if no key"
}
variable "tags" {
  type = map(string)
}
variable "security_groups" {
  type = list(string)
}
