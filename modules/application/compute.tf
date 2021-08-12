resource "aws_launch_configuration" "lc" {
  name_prefix     = var.name
  image_id        = var.amzn_linux_2_ami
  instance_type   = var.instance_type
  user_data       = file("${path.module}/init.sh")
  security_groups = var.security_groups
  key_name        = var.key_name == "" ? null : var.key_name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = aws_launch_configuration.lc.name
  launch_configuration = aws_launch_configuration.lc.name
  vpc_zone_identifier  = var.subnets
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  desired_capacity     = var.asg_desired_capacity
  target_group_arns    = [var.target_group_arn]

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}