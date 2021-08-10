# Meta-argumentos, expresiones y funciones

Terraform no es un lenguaje de programación de alto nivel, sin emabargo, tiene funciones que nos ayudan con tareas más complicadas de lo que se puede expresar de forma declarativa.

En este taller aprenderemos a:

- Usar meta-argumentos en recursos
- Usar expresiones for
- Usar expresiones condicionales
- Usar bloques dinámicos
- Usar funciones con plantillas dinámicas
- Usar comando console

#### Instrucciones iniciales

1. Crea un nuevo directorio y archivos para nuestra configuración:

```sh
mkdir 11-advanced
cd 11-advanced
touch main.tf server.tf securitygroup.tf bucket.tf locals.tf queue.tf init.tpl
```

2. En el archivo `main.tf` coloca la configuración de `terraform` y `provider` que hemos ocupado hasta ahora. Configura el _backend_ de tipo S3 con el argumento `key` igual a `11/advanced/terraform.tfstate`

3. En el archivo `server.tf` escribimos lo siguiente:

```tf
resource "aws_instance" "servers" {
  ami                    = "ami-0dc2d3e4c0f9ebd18"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.server_sg.id]


  tags = {
    Name = "Advanced lab"
  }
}
```

4. En el archivo `securitygroup.tf` escribimos lo siguiente:

```tf
resource "aws_default_vpc" "default" {}

resource "aws_security_group" "server_sg" {
  name   = "tf_server_sg"
  vpc_id = aws_default_vpc.default.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
```

5. En el archivo `locals.tf` escribimos lo siguiente (más información sobre [locals](https://www.terraform.io/docs/language/values/locals.html)):

```tf
locals {
  bucket_configs = {
    terraformmcprivate = {
      acl = "private"
      tags = {
        Team = "development"
        App  = "secret"
      }
    }
    terraformmcpublic = {
      acl = "public-read"
      tags = {
        Team = "web"
        App  = "site"

      }
    }
  }

  server_key = ""
  inbound_rules = {
    ssh = {
      description = "SSH access"
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    http = {
      description = "HTTP access"
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    https = {
      description = "HTTPS access"
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

6. Inicializa y aplica los cambios

### Usar meta-argumentos en recursos

Los meta-argumentos son propiedades que podemos utilizar en cualquier bloque de tipo `resource` o `module` para modificar su comportamiento. Los meta-argumentos disponibles son los siguientes:

- depends_on (dependencias explícitas)
- count
- for_each
- provider
- lifecycle (no disponible en bloques `module`)

#### count

Por default, un bloque de recurso o módulo configura un objeto de infraestructura. Sin embargo, a veces queremos administrar varios objetos similares sin la necesidad de escriir bloques separados. Esto lo podemos hacer a través del meta-argumento [count](https://www.terraform.io/docs/language/meta-arguments/count.html).

##### Instrucciones

1. Modifica el bloque en el archivo `server.tf` con lo siguiente:

```tf
resource "aws_instance" "servers" {
  count                  = 2
  ami                    = "ami-0dc2d3e4c0f9ebd18"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.server_sg.id]

  tags = {
    Name = "Advanced lab ${count.index}"
  }
}

output "public_ips" {
  value = aws_instance.servers[*].public_ip
}
```

2. Aplica los cambios y valida los servidores que fueron creados

#### for_each

Similar al meta-argumento _count_. Para crear copias de un mismo recurso pero con diferencias en sus propiedades, ocupamos [for_each](https://www.terraform.io/docs/language/meta-arguments/for_each.html) que recibe como valor un tipo complejo de datos.

##### Instrucciones

1. Escribimos lo siguiente en el archivo `bucket.tf`:

```tf
resource "aws_s3_bucket" "buckets" {
  for_each      = local.bucket_configs
  bucket_prefix = each.key
  acl           = each.value.acl

  tags = each.value.tags
}
```

2. Aplica los cambios y verifica las configuraciones de los buckets creados

#### provider

Con el meta-argumento [provider](https://www.terraform.io/docs/language/meta-arguments/resource-provider.html) es posible indicar un provider previamente configurado para crear un recurso.

##### Instrucciones

1. Agrega el siguiente bloque en el archivo `main.tf`

```tf
provider "aws" {
  region = "us-west-2"
  alias  = "oregon"
}
```

2. Escribimos lo siguiente en el archivo `queue.tf`:

```tf
resource "aws_sqs_queue" "queue" {
  provider = aws.oregon

  name_prefix                = "my-queue"
  visibility_timeout_seconds = 30
}
```

3. Aplica los cambios y valida que el _queue_ fue creado en otra región

#### lifecycle

El meta-argumento [lifecycle](https://www.terraform.io/docs/language/meta-arguments/lifecycle.html#ignore_changes) sirve para modificar el comportamiento de Terraform al aplicar cambios. **Este meta-argumento no está disponible para bloques module**

##### Instrucciones

1. Sobreescribe el contenido del archivo `queue.tf` con lo siguiente:

```tf
resource "aws_sqs_queue" "queue" {
  provider = aws.oregon

  name_prefix                = "my-queue"
  visibility_timeout_seconds = 30

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [visibility_timeout_seconds]
  }
}
```

2. Recrea el queue con el comando `terraform apply -replace="aws_sqs_queue.queue" -auto-approve` y observa el comportamiento

3. Cambia el valor del atributo `visibility_timeout_seconds`, aplica los cambios y observa el comportamiento

### Usar expresiones for

Una [expresión for](https://www.terraform.io/docs/language/expressions/for.html) crea una valor de tipo complejo (lista o mapa) transformando otro valor de tipo complejo.

#### Instrucciones

1. Agrega el siguiente bloque _output_ en el archivo `server.tf`:

```tf
output "private_ips" {
  value = { for server in aws_instance.servers : server.id => server.private_ip }
}
```

2. Agrega el siguiente bloque _output_ en el archivo `bucket.tf`:

```tf
output "bucket_arns" {
  value = [for key, value in local.bucket_configs : aws_s3_bucket.buckets[key].arn]
}
```

3. Aplica los cambios y valida los valores de salida

### Usar expresiones condicionales

Una [expresión condicional](https://www.terraform.io/docs/language/expressions/conditionals.html) usa el valor de una expresión _booleana_ para seleccionar uno de dos valores.

#### Instrucciones

1. Agrega el siguiente atributo en el recurso `servers` en `server.tf`:

```tf
key_name  = local.server_key == "" ? null : local.server_key
```

2. Valida el comportamiento de agregar un valor en el archivo `locals.tf` en la propiedad `server_key` y aplicar los cambios

### Usar bloques dinámicos

Existen recursos que tienen bloques anidados repetidos dentro de su configuración, con Terraform podemos generar estos bloques a partir de tipos de datos complejos usando [bloques dinámicos](https://www.terraform.io/docs/language/expressions/dynamic-blocks.html).

#### Instrucciones

1. Modifica el archivo `securitygroup.tf` sobreescribiendo el recurso `server_sg` con lo siguiente:

```tf
resource "aws_security_group" "server_sg" {
  name   = "tf_server_sg"
  vpc_id = aws_default_vpc.default.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  dynamic "ingress" {
    for_each = local.inbound_rules
    content {
      description = ingress.value["description"]
      from_port   = ingress.value["port"]
      to_port     = ingress.value["port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }
}
```

2. Aplica los cambios y valida las reglas del security group

### Usar funciones con plantillas dinámicas

Podemos ocupar la función [templatefile](https://www.terraform.io/docs/language/functions/templatefile.html) para leer un archivo y pasar un conjunto de variables para remplazar valores de una plantilla.

#### Instrucciones

1. Escribe el siguiente contenido en el archivo `init.tpl`:

```sh
#!/bin/bash

yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "Hello my name is ${name}" > /var/www/html/index.html
```

2. Agrega el siguiente atributo en el recurso `servers` en `server.tf`:

```tf
user_data = templatefile("${path.module}/init.tpl", { name = "Eloy" })
```

3. Aplica los cambios y visita la IP pública del servidor para validar el funcionamiento del script de inicio

### Usar comando console

El comando [terraform console](https://www.terraform.io/docs/cli/commands/console.html) proporciona una consola interactiva para evaluar expresiones. Si se ejecuta en una carpeta con una configuración inicializada y recursos creados, es capaz de evaluar expresiones con objetos guardados en el archivo de estado.

#### Instrucciones

1. Ejecuta el comando:

```sh
terraform console
```

2. Experimenta con algunas [funciones](https://www.terraform.io/docs/language/functions/index.html) de Terraform:

```
max(5, 12, 9)
```

```
join(", ", ["foo", "bar", "baz"])
```

```
upper("terraform master class")
```

```
element(["a", "b", "c"], 1)
```

```
index(["a", "b", "c"], "b")
```

```
length(["bootcamp", "institute", "terraform", "master", "class"])
```

```
jsonencode({"hello"="world", "how"="are you"})
```

```
timestamp()
```

```
cidrsubnet("10.0.0.0/16", 8, 0)
cidrsubnet("10.0.0.0/16", 8, 1)
cidrsubnet("10.0.0.0/16", 8, 2)
cidrsubnet("10.0.0.0/16", 8, 3)
```

3. Experimenta las siguientes expresiones utilizando recursos en el archivo de estado:

```
{for server in aws_instance.servers : upper(server.tags.Name) => server.arn}
```

```
[for bucket_name, bucket_config in aws_s3_bucket.buckets : bucket_config.arn]
```

```
{for bucket_name, bucket_config in aws_s3_bucket.buckets : bucket_name => bucket_config.tags}
```

4. Sal de la sesión interactiva con:

```
exit
```

## Limpieza

Ejecuta el siguiente comando:

```sh
terraform destroy -auto-approve
```

## Conclusión

En este taller aprendimos las funciones avanzadas del lenguaje de terraform que incluyen:

- Meta-argumentos
  - count
  - for_each
  - provider
  - lifecycle
- Expresiones for
- Expresiones condicionales
- Bloques dinámicos
- Funciones

### Comandos

- console
