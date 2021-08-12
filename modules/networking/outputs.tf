output "vpc_info" {
  value = module.vpc
}

output "lb_info" {
  value = {
    dns_name     = aws_lb.alb.dns_name
    challenge_tg = aws_lb_target_group.default.arn
  }
}

output "security_groups" {
  value = {
    http_external = aws_security_group.http_external.id
    http_internal = aws_security_group.http_internal.id
    ssh_internal  = aws_security_group.ssh_internal.id
    ssh_external  = aws_security_group.ssh_external.id
  }
}