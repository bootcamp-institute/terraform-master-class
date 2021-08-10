resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.http.id]
  user_data              = templatefile("${path.module}/init.tpl", {})

  tags = {
    Name = var.server_name
  }
}

output "public_ip" {
  value = aws_instance.web_server.public_ip
}