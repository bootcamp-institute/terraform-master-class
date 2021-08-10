# Provisioners

Los [provisioners](https://www.terraform.io/docs/language/resources/provisioners/syntax.html) son usados para ejecutar scripts en una máquina local o remota como parte de la creación o destrucción de un recurso. Los _provisioners_ pueden ser usados para configurar de inicio un recurso, hacer limpieza antes de destruir, o ejecutar herramientas de _Configuration Management_, etc. **Deben ser utilizados como un última opción.**

Por default, los _provisioners_ se ejecutan cuando el recurso donde están definidos es creado, pero también pueden correr en tiempo de destrucción. _Provisioners_ en tiempo de creación solo son ejecutados durante la creación del recurso, no durante la actualización o cualquier otra etapa del ciclo de vida.

En este taller aprenderemos:

- Provisioners remotos
- Provisioners locales
- Provisioners de archivos
- Provisioners en tiempo de destrucción
- Recursos nulos

#### Instrucciones iniciales

1. Crea un nuevo directorio y archivos para nuestra configuración:

```sh
mkdir 10-provisioners
cd 10-provisioners
touch main.tf resources.tf server.tf
```

2. En el archivo `main.tf` coloca la configuración de `terraform` y `provider` que hemos ocupado hasta ahora. Configura el _backend_ de tipo S3 con el argumento `key` igual a `10/provisioners/terraform.tfstate`

3. En el archivo `resources.tf` escribimos lo siguiente:

```tf
resource "aws_default_vpc" "default" {}

resource "aws_security_group" "http_ssh" {
  vpc_id = aws_default_vpc.default.id

  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
```

4. En el archivo `server.tf` escribimos lo siguiente:

```tf
resource "aws_instance" "server" {
  ami                    = "ami-0dc2d3e4c0f9ebd18"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.http_ssh.id]
  key_name               = "TerraformMasterClass"

  tags = {
    Name = "Provisioners Lab"
  }
}
```

5. Ejecuta el comando `init`

6. Crea la llave `TerraformMasterClass` de la siguiente forma:

```sh
aws ec2 create-key-pair --key-name TerraformMasterClass --query 'KeyMaterial' --output text > TerraformMasterClass.pem
chmod 400 TerraformMasterClass.pem
```

### Provisioners remotos

Con [provisioners remotos](https://www.terraform.io/docs/language/resources/provisioners/remote-exec.html) podemos ejecutar comandos en una máquina remota.

#### Instrucciones

1. Primero necesitamos un bloque de tipo [connection](https://www.terraform.io/docs/language/resources/provisioners/connection.html) dentro de nuestro recurso para indicar los detalles de conexión a la máquina remota. Modificamos el servidor para que sea igual a lo siguiente:

```tf
resource "aws_instance" "server" {
  ami                    = "ami-0dc2d3e4c0f9ebd18"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.http_ssh.id]
  key_name               = "TerraformMasterClass"

  tags = {
    Name = "Provisioners Lab"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("TerraformMasterClass.pem")
  }
}
```

2. A continuación agregamos un bloque anidado de tipo `provisioner` después del bloque `connection` para instalar el servidor Apache en nuestro servidor:

```tf
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
    ]
  }
```

3. Ejecuta un comando `apply` y visita la dirección IP pública del servidor para validar la instalación

### Provisioners locales

Con [provisioners locales](https://www.terraform.io/docs/language/resources/provisioners/local-exec.html) podemos correr comandos en la máquina donde se está ejecutando Terraform.

#### Instrucciones

1. Agrega el siguiente bloque anidado en el recurso de servidor en `server.tf`:

```tf
  provisioner "local-exec" {
    command = "echo 'My IP is ${self.public_ip}' > index.html"
  }
```

2. Ejecuta el comando `apply`

3. Debido a que los provisioners solo se ejecutan en la creación del recurso, debemos recrear el servidor para ejecutar nuestro _provisioner_. Utiliza el comando `taint` para recrear el servidor.

4. Valida que el archivo `index.html` contiene los cambios con la IP del servidor

### Provisioners de archivos

Con [provisioners de archivos](https://www.terraform.io/docs/language/resources/provisioners/file.html) podemos copiar archivos locales a ubicaciones remotas.

#### Instrucciones

1. Agrega los siguientes bloques anidados en el recurso de servidor en `server.tf`:

```tf
  provisioner "file" {
    source      = "index.html"
    destination = "/home/ec2-user/index.html"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/ec2-user/index.html /var/www/html/",
    ]
  }
```

2. Recrea el servidor y valida que la página de inicio fue remplazada por nuestro archivo `index.html`

### Provisioners en tiempo de destrucción

Por default, los provisioners se ejecutan en tiempo de creación. Este comportamiento puede ser modificado ocupando el atributo [when](https://www.terraform.io/docs/language/resources/provisioners/syntax.html#destroy-time-provisioners) en un _provider_.

#### Instrucciones

1. Agrega el siguiente bloque anidado en el recurso de servidor en `server.tf`:

```tf
  provisioner "local-exec" {
    when = destroy

    command = "echo 'Machine ${self.id} is being destroyed' > destroy.txt"
  }
```

2. Recrea el servidor y verifica que en la destrucción del recurso, el archivo `destroy.txt` se crea con el ID del servidor.

### Recursos nulos

En ocasiones, no existe un recurso ligado a la acción que queremos ejecutar con un _provisioner_. En estos casos, podemos ocupar el recurso especial [null_resource](https://www.terraform.io/docs/language/resources/provisioners/null_resource.html).

#### Instrucciones

1. Agrega el siguiente bloque en el archivo `server.tf`:

```tf
resource "null_resource" "start_server" {
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.server.id}"
  }
}
```

2. Debido a que estamos usando un nuevo provider, ejecuta un comando `init`

3. Aplica los cambios y valida que el servidor fue detenido

## Limpieza

Ejecuta el siguiente comando para limpiar los recursos en AWS:

```sh
terraform destroy -auto-approve
```

## Conclusión

En este taller aprendimos la forma de ejecutar comandos de forma local o remota cuando estamos creando o destruyendo un recurso. Es importante recordar que Terraform recomienda el uso de _provisioners_ como un último recurso. Siempre debemos priorizar el uso de herramientas de bootstraping de nuestro proveedor de servicio o herramientas de _Configuration Management_ como Ansible.
