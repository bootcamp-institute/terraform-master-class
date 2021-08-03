# Creando configuraciones de recursos dependientes

Todos los recursos definidos en archivos de configuración dentro del mismo directorio son evaluados por Terraform sin importar su ubicación, nombre de archivo u orden de aparición. Esto facilita la definición de infraestructura ya que podemos adoptar cualquier tipo de organización para describir nuestros recursos.

Terraform optimiza la creación de recursos en paralelo o secuencialmente tomando en cuenta si un recurso tiene dependencias o no.

En este taller aprenderemos a:

- Crear recursos con dependencias implícitas
- Crear recursos con dependencias explícitas
- Utilizar comandos secundarios

### Crear recursos con dependencias implícitas

Creamos un nuevo directorio con archivos iniciales para trabajar en archivos de configuración para AWS:

```sh
mkdir 03-dependencies
cd 03-dependencies
touch main.tf resources.tf
```

En `main.tf` ponemos la configuración de Terraform y AWS:

```tf
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

En el archivo `resources.tf` definimos los siguientes recursos:

```tf
resource "aws_default_vpc" "default" {}

resource "aws_instance" "server" {
  ami                    = "ami-0dc2d3e4c0f9ebd18"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id]
}

resource "aws_security_group" "allow_http" {
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description      = "HTTP traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
```

Creamos la infraestructura en AWS:

```sh
terraform init
terraform plan -out=out.tfplan
terraform apply "out.tfplan"
```

<details>
  <summary>Salida</summary>
  
  ```
    aws_default_vpc.default: Creating...
    aws_default_vpc.default: Still creating... [10s elapsed]
    aws_default_vpc.default: Creation complete after 11s [id=vpc-0eb22b73]
    aws_security_group.allow_http: Creating...
    aws_security_group.allow_http: Creation complete after 1s [id=sg-0739355d046a7d49f]
    aws_instance.server: Creating...
    aws_instance.server: Still creating... [10s elapsed]
    aws_instance.server: Creation complete after 13s [id=i-0b787386f31a9c5f8]
    
    Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
  ```
</details>

Explicación:

1. El recurso [aws_default_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_vpc) es de un tipo especial y sirve para hacer referencia a la VPC por default de la región _us-east-1_ de nuestra cuenta de AWS.
2. Creamos un servidor de EC2 ocupando el recurso [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#vpc_security_group_ids) definiendo la AMI (Amazon Machine Image), tipo de instancia y Security Group que va a utilizar
  - En el atributo `vpc_security_group_ids` utilizamos la sintaxis para hacer referencia a otro recurso creado en esta configuración. Esto se conoce como _resource address_: `aws_security_group.allow_http.id`
  - Esta referencia crea una dependencia implícita, por lo cual Terraform va a crear primero el Security Group y después la instancia
3. El recurso [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#attributes-reference) crea un Security Group con una regla para permitir el acceso a través del puerto 80 desde todo el internet


#### Ejercicio

Utiliza la documentación de Terraform para la instancia de EC2 y Security Group y modifica los recursos de la siguiente forma:

1. Agrega el _tag_ `Name` al servidor EC2 con el valor `Terraform MC`
2. Agrega una regla al security group para permitir el tráfico en el puerto `22`
3. Aplica los cambios

<details>
  <summary>Respuesta</summary>
  
  ```tf
resource "aws_default_vpc" "default" {}

resource "aws_instance" "server" {
  ami                    = "ami-0dc2d3e4c0f9ebd18"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id]

  tags = {
    Name = "Terraform MC"
  }
}

resource "aws_security_group" "allow_http" {
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
}
  ```
  
Para actualizar los recursos, ejecuta el comando:

```sh
terraform apply -auto-approve
```
</details>

### Crear recursos con dependencias explícitas

En ocasiones, las dependencias entre recursos no son a través propiedades y atributos. En los casos en que tenemos que indicar a Terraform que un recurso debe ser creado primero antes de continuar con la creación de otro recurso, podemos ocupar el meta-argumento `depends_on`. Esto se conoce como una dependencia explícita.

Supongamos que tenemos un servidor de EC2 que ejecutará una aplicación que requiere de un bucket de S3 para guardar archivos. Empezamos definiendo un nuevo par de recursos en nuestro archivo `resources.tf`:

```tf
resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "explicit-dependency"
  acl           = "private"
}

resource "aws_instance" "bucket_server" {
  ami           = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t3.micro"

  depends_on = [aws_s3_bucket.bucket]
}
```

Ejecutamos estos cambios:

```sh
terraform plan -out=out.tfplan
terraform apply "out.tfplan"
```

<details>
  <summary>Salida</summary>
  
  ```
  aws_s3_bucket.bucket: Creating...
  aws_s3_bucket.bucket: Creation complete after 0s [id=explicit-dependency20210718033610555700000001]
  aws_instance.bucket_server: Creating...
  aws_instance.bucket_server: Still creating... [10s elapsed]
  aws_instance.bucket_server: Creation complete after 13s [id=i-046bba6fef3e0af49]
  
  Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
  ```
</details>

Explicación:

1. Creamos dos recursos de tipo [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) y [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance). Normalmente estos recursos se podrían crear en paralelo ya que no tienen ninguna dependencia
2. Agregamos el meta-argumento [depends_on](https://www.terraform.io/docs/language/meta-arguments/depends_on.html) al servidor EC2 para indicar a Terraform que existe una dependencia y debe crear primero el bucket S3. De lo contrario nuestra aplicación fallaría al ejecutarse
3. La ejecución de Terraform nos informa que la creación del servidor EC2 espera que primero se complete la creación del bucket de S3

### Utilizar comandos secundarios

Exploraremos otros comandos que no son centrales al flujo de trabajo principal de Terraform.

#### Validate

Con este comando podemos validar si una configuración es correcta en sintaxis y en algunas otras comprobaciones como nombres de atributos y tipos de datos. Este comando no accesa a ningún servicio externo para comprobar la validez de la configuración.

```sh
terraform validate
```

<details>
  <summary>Salida</summary>
  
  ```
    Success! The configuration is valid.
  ```
</details>


Si queremos obtener una salida en formato JSON que podría ser analizado por otro sistema automatizado, ocupamos la opción `-json`:

```sh
terraform validate -json
```

<details>
  <summary>Salida</summary>
  
  ```
    {
      "format_version": "0.1",
      "valid": true,
      "error_count": 0,
      "warning_count": 0,
      "diagnostics": []
    }
```
</details>

##### Ejercicio

Realiza un cambio en la configuración para provocar un error de validación y comprueba que el comando `validate` arroja un error.

#### Fmt

Con `terraform fmt` podemos validar que nuestros archivos de configuración tienen el formato estándar de Terraform.

Empezamos creando un nuevo bloque en nuestro archivo `resources.tf`:

```tf
resource "aws_instance" "test_server"{
ami = "ami-0dc2d3e4c0f9ebd18"
instance_type = "t3.micro"

tags = {
Name = "format"
Env = "development"
}
}
```

Este bloque es totalmente válido y Terraform puede crear el servidor a partir de esta configuración. Sin embargo no es fácil de leer debido a que no tiene el formato estándar. 

Con el siguiente comando podemos validar si nuestros archivos tienen el formato adecuado pero sin alterar aquellos que no lo estén:

```sh
terraform fmt -check
```

Lo mismo se puede lograr con el siguiente comando:

```sh
terraform fmt -write=false
```

Aparte de validar si los archivos se encuentran con el formato adecuado, podemos formatear las configuraciones:

```sh
terraform fmt
```

#### Show

Con este comando podemos obtener una salida legible para el usuario con los contenidos de un archivo de estado o de plan. Crea un nuevo archivo de plan con:

```sh
terraform plan -out=out.tfplan
```

Ahora inspeccionamos el archivo con:

```sh
terraform show "out.tfplan"
```

<details>
  <summary>Salida</summary>
  
  ```
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
      + create
    
    Terraform will perform the following actions:
    
      # aws_instance.test_server will be created
      + resource "aws_instance" "test_server" {
          + ami                                  = "ami-0dc2d3e4c0f9ebd18"
          + arn                                  = (known after apply)
          + associate_public_ip_address          = (known after apply)
          + availability_zone                    = (known after apply)
          + cpu_core_count                       = (known after apply)
          + cpu_threads_per_core                 = (known after apply)
          + get_password_data                    = false
          + host_id                              = (known after apply)
          + id                                   = (known after apply)
          + instance_initiated_shutdown_behavior = (known after apply)
          + instance_state                       = (known after apply)
          + instance_type                        = "t3.micro"
          + ipv6_address_count                   = (known after apply)
          + ipv6_addresses                       = (known after apply)
          + key_name                             = (known after apply)
          + outpost_arn                          = (known after apply)
          + password_data                        = (known after apply)
          + placement_group                      = (known after apply)
          + primary_network_interface_id         = (known after apply)
          + private_dns                          = (known after apply)
          + private_ip                           = (known after apply)
          + public_dns                           = (known after apply)
          + public_ip                            = (known after apply)
          + secondary_private_ips                = (known after apply)
          + security_groups                      = (known after apply)
          + source_dest_check                    = true
          + subnet_id                            = (known after apply)
          + tags                                 = {
              + "Env"  = "development"
              + "Name" = "format"
            }
          + tags_all                             = {
              + "Env"  = "development"
              + "Name" = "format"
            }
          + tenancy                              = (known after apply)
          + vpc_security_group_ids               = (known after apply)
    
          + capacity_reservation_specification {
              + capacity_reservation_preference = (known after apply)
    
              + capacity_reservation_target {
                  + capacity_reservation_id = (known after apply)
                }
            }
    
          + ebs_block_device {
              + delete_on_termination = (known after apply)
              + device_name           = (known after apply)
              + encrypted             = (known after apply)
              + iops                  = (known after apply)
              + kms_key_id            = (known after apply)
              + snapshot_id           = (known after apply)
              + tags                  = (known after apply)
              + throughput            = (known after apply)
              + volume_id             = (known after apply)
              + volume_size           = (known after apply)
              + volume_type           = (known after apply)
            }
    
          + enclave_options {
              + enabled = (known after apply)
            }
    
          + ephemeral_block_device {
              + device_name  = (known after apply)
              + no_device    = (known after apply)
              + virtual_name = (known after apply)
            }
    
          + metadata_options {
              + http_endpoint               = (known after apply)
              + http_put_response_hop_limit = (known after apply)
              + http_tokens                 = (known after apply)
            }
    
          + network_interface {
              + delete_on_termination = (known after apply)
              + device_index          = (known after apply)
              + network_interface_id  = (known after apply)
            }
    
          + root_block_device {
              + delete_on_termination = (known after apply)
              + device_name           = (known after apply)
              + encrypted             = (known after apply)
              + iops                  = (known after apply)
              + kms_key_id            = (known after apply)
              + tags                  = (known after apply)
              + throughput            = (known after apply)
              + volume_id             = (known after apply)
              + volume_size           = (known after apply)
              + volume_type           = (known after apply)
            }
        }
    
    Plan: 1 to add, 0 to change, 0 to destroy.
  ```
</details>

Si no se pasa un parámetro, se muestra el contenido del archivo de estado:

```sh
terraform show
```

<details>
  <summary>Salida</summary>
  
  ```
    # aws_default_vpc.default:
    resource "aws_default_vpc" "default" {
        arn                              = "arn:aws:ec2:us-east-1:188556757614:vpc/vpc-0eb22b73"
        assign_generated_ipv6_cidr_block = false
        cidr_block                       = "172.31.0.0/16"
        default_network_acl_id           = "acl-6030f01c"
        default_route_table_id           = "rtb-b912f6c8"
        default_security_group_id        = "sg-10429a08"
        dhcp_options_id                  = "dopt-2d8db757"
        enable_classiclink               = false
        enable_classiclink_dns_support   = false
        enable_dns_hostnames             = true
        enable_dns_support               = true
        id                               = "vpc-0eb22b73"
        instance_tenancy                 = "default"
        main_route_table_id              = "rtb-b912f6c8"
        owner_id                         = "188556757614"
        tags                             = {}
        tags_all                         = {}
    }
    
    # aws_instance.bucket_server:
    resource "aws_instance" "bucket_server" {
        ami                                  = "ami-0dc2d3e4c0f9ebd18"
        arn                                  = "arn:aws:ec2:us-east-1:188556757614:instance/i-046bba6fef3e0af49"
        associate_public_ip_address          = true
        availability_zone                    = "us-east-1f"
        cpu_core_count                       = 1
        cpu_threads_per_core                 = 2
        disable_api_termination              = false
        ebs_optimized                        = false
        get_password_data                    = false
        hibernation                          = false
        id                                   = "i-046bba6fef3e0af49"
        instance_initiated_shutdown_behavior = "stop"
        instance_state                       = "running"
        instance_type                        = "t3.micro"
        ipv6_address_count                   = 0
        ipv6_addresses                       = []
        monitoring                           = false
        primary_network_interface_id         = "eni-01cd6f124f0e2f3f3"
        private_dns                          = "ip-172-31-64-109.ec2.internal"
        private_ip                           = "172.31.64.109"
        public_dns                           = "ec2-3-235-224-238.compute-1.amazonaws.com"
        public_ip                            = "3.235.224.238"
        secondary_private_ips                = []
        security_groups                      = [
            "default",
        ]
        source_dest_check                    = true
        subnet_id                            = "subnet-d07573de"
        tags_all                             = {}
        tenancy                              = "default"
        vpc_security_group_ids               = [
            "sg-10429a08",
        ]
    
        capacity_reservation_specification {
            capacity_reservation_preference = "open"
        }
    
        credit_specification {
            cpu_credits = "unlimited"
        }
    
        enclave_options {
            enabled = false
        }
    
        metadata_options {
            http_endpoint               = "enabled"
            http_put_response_hop_limit = 1
            http_tokens                 = "optional"
        }
    
        root_block_device {
            delete_on_termination = true
            device_name           = "/dev/xvda"
            encrypted             = false
            iops                  = 100
            tags                  = {}
            throughput            = 0
            volume_id             = "vol-0b78643efeb5995c6"
            volume_size           = 8
            volume_type           = "gp2"
        }
    }
    
    # aws_instance.server:
    resource "aws_instance" "server" {
        ami                                  = "ami-0dc2d3e4c0f9ebd18"
        arn                                  = "arn:aws:ec2:us-east-1:188556757614:instance/i-0b787386f31a9c5f8"
        associate_public_ip_address          = true
        availability_zone                    = "us-east-1c"
        cpu_core_count                       = 1
        cpu_threads_per_core                 = 2
        disable_api_termination              = false
        ebs_optimized                        = false
        get_password_data                    = false
        hibernation                          = false
        id                                   = "i-0b787386f31a9c5f8"
        instance_initiated_shutdown_behavior = "stop"
        instance_state                       = "running"
        instance_type                        = "t3.micro"
        ipv6_address_count                   = 0
        ipv6_addresses                       = []
        monitoring                           = false
        primary_network_interface_id         = "eni-0c71c216ad45c7f94"
        private_dns                          = "ip-172-31-93-3.ec2.internal"
        private_ip                           = "172.31.93.3"
        public_dns                           = "ec2-54-88-69-47.compute-1.amazonaws.com"
        public_ip                            = "54.88.69.47"
        secondary_private_ips                = []
        security_groups                      = [
            "terraform-20210717223826807600000001",
        ]
        source_dest_check                    = true
        subnet_id                            = "subnet-5bcf847a"
        tags                                 = {
            "Name" = "Terraform MC"
        }
        tags_all                             = {
            "Name" = "Terraform MC"
        }
        tenancy                              = "default"
        vpc_security_group_ids               = [
            "sg-0739355d046a7d49f",
        ]
    
        capacity_reservation_specification {
            capacity_reservation_preference = "open"
        }
    
        credit_specification {
            cpu_credits = "unlimited"
        }
    
        enclave_options {
            enabled = false
        }
    
        metadata_options {
            http_endpoint               = "enabled"
            http_put_response_hop_limit = 1
            http_tokens                 = "optional"
        }
    
        root_block_device {
            delete_on_termination = true
            device_name           = "/dev/xvda"
            encrypted             = false
            iops                  = 100
            tags                  = {}
            throughput            = 0
            volume_id             = "vol-0860658ecbe7f9eb1"
            volume_size           = 8
            volume_type           = "gp2"
        }
    }
    
    # aws_s3_bucket.bucket:
    resource "aws_s3_bucket" "bucket" {
        acl                         = "private"
        arn                         = "arn:aws:s3:::explicit-dependency20210718033610555700000001"
        bucket                      = "explicit-dependency20210718033610555700000001"
        bucket_domain_name          = "explicit-dependency20210718033610555700000001.s3.amazonaws.com"
        bucket_prefix               = "explicit-dependency"
        bucket_regional_domain_name = "explicit-dependency20210718033610555700000001.s3.amazonaws.com"
        force_destroy               = false
        hosted_zone_id              = "Z3AQBSTGFYJSTF"
        id                          = "explicit-dependency20210718033610555700000001"
        region                      = "us-east-1"
        request_payer               = "BucketOwner"
        tags_all                    = {}
    
        versioning {
            enabled    = false
            mfa_delete = false
        }
    }
    
    # aws_security_group.allow_http:
    resource "aws_security_group" "allow_http" {
        arn                    = "arn:aws:ec2:us-east-1:188556757614:security-group/sg-0739355d046a7d49f"
        description            = "Managed by Terraform"
        egress                 = []
        id                     = "sg-0739355d046a7d49f"
        ingress                = [
            {
                cidr_blocks      = [
                    "0.0.0.0/0",
                ]
                description      = "HTTP traffic"
                from_port        = 80
                ipv6_cidr_blocks = []
                prefix_list_ids  = []
                protocol         = "tcp"
                security_groups  = []
                self             = false
                to_port          = 80
            },
            {
                cidr_blocks      = [
                    "0.0.0.0/0",
                ]
                description      = "SSH traffic"
                from_port        = 22
                ipv6_cidr_blocks = []
                prefix_list_ids  = []
                protocol         = "tcp"
                security_groups  = []
                self             = false
                to_port          = 22
            },
        ]
        name                   = "terraform-20210717223826807600000001"
        name_prefix            = "terraform-"
        owner_id               = "188556757614"
        revoke_rules_on_delete = false
        tags                   = {}
        tags_all               = {}
        vpc_id                 = "vpc-0eb22b73"
    }
  ```
</details>

En cualquier caso se puede ocupar la opción `-json` para obtener una salida en formato JSON que puede ser procesado por otro sistema automatizado.

```sh
terraform show -json
```

<details>
  <summary>Salida</summary>
  
  ```
{"format_version":"0.2","terraform_version":"1.0.2","values":{"root_module":{"resources":[{"address":"aws_default_vpc.default","mode":"managed","type":"aws_default_vpc","name":"default","provider_name":"registry.terraform.io/hashicorp/aws","schema_version":1,"values":{"arn":"arn:aws:ec2:us-east-1:188556757614:vpc/vpc-0eb22b73","assign_generated_ipv6_cidr_block":false,"cidr_block":"172.31.0.0/16","default_network_acl_id":"acl-6030f01c","default_route_table_id":"rtb-b912f6c8","default_security_group_id":"sg-10429a08","dhcp_options_id":"dopt-2d8db757","enable_classiclink":false,"enable_classiclink_dns_support":false,"enable_dns_hostnames":true,"enable_dns_support":true,"id":"vpc-0eb22b73","instance_tenancy":"default","ipv6_association_id":"","ipv6_cidr_block":"","main_route_table_id":"rtb-b912f6c8","owner_id":"188556757614","tags":{},"tags_all":{}},"sensitive_values":{"tags":{},"tags_all":{}}},{"address":"aws_instance.bucket_server","mode":"managed","type":"aws_instance","name":"bucket_server","provider_name":"registry.terraform.io/hashicorp/aws","schema_version":1,"values":{"ami":"ami-0dc2d3e4c0f9ebd18","arn":"arn:aws:ec2:us-east-1:188556757614:instance/i-046bba6fef3e0af49","associate_public_ip_address":true,"availability_zone":"us-east-1f","capacity_reservation_specification":[{"capacity_reservation_preference":"open","capacity_reservation_target":[]}],"cpu_core_count":1,"cpu_threads_per_core":2,"credit_specification":[{"cpu_credits":"unlimited"}],"disable_api_termination":false,"ebs_block_device":[],"ebs_optimized":false,"enclave_options":[{"enabled":false}],"ephemeral_block_device":[],"get_password_data":false,"hibernation":false,"host_id":null,"iam_instance_profile":"","id":"i-046bba6fef3e0af49","instance_initiated_shutdown_behavior":"stop","instance_state":"running","instance_type":"t3.micro","ipv6_address_count":0,"ipv6_addresses":[],"key_name":"","metadata_options":[{"http_endpoint":"enabled","http_put_response_hop_limit":1,"http_tokens":"optional"}],"monitoring":false,"network_interface":[],"outpost_arn":"","password_data":"","placement_group":"","primary_network_interface_id":"eni-01cd6f124f0e2f3f3","private_dns":"ip-172-31-64-109.ec2.internal","private_ip":"172.31.64.109","public_dns":"ec2-3-235-224-238.compute-1.amazonaws.com","public_ip":"3.235.224.238","root_block_device":[{"delete_on_termination":true,"device_name":"/dev/xvda","encrypted":false,"iops":100,"kms_key_id":"","tags":{},"throughput":0,"volume_id":"vol-0b78643efeb5995c6","volume_size":8,"volume_type":"gp2"}],"secondary_private_ips":[],"security_groups":["default"],"source_dest_check":true,"subnet_id":"subnet-d07573de","tags":null,"tags_all":{},"tenancy":"default","timeouts":null,"user_data":null,"user_data_base64":null,"volume_tags":null,"vpc_security_group_ids":["sg-10429a08"]},"sensitive_values":{"capacity_reservation_specification":[{"capacity_reservation_target":[]}],"credit_specification":[{}],"ebs_block_device":[],"enclave_options":[{}],"ephemeral_block_device":[],"ipv6_addresses":[],"metadata_options":[{}],"network_interface":[],"root_block_device":[{"tags":{}}],"secondary_private_ips":[],"security_groups":[false],"tags_all":{},"vpc_security_group_ids":[false]},"depends_on":["aws_s3_bucket.bucket"]},{"address":"aws_instance.server","mode":"managed","type":"aws_instance","name":"server","provider_name":"registry.terraform.io/hashicorp/aws","schema_version":1,"values":{"ami":"ami-0dc2d3e4c0f9ebd18","arn":"arn:aws:ec2:us-east-1:188556757614:instance/i-0b787386f31a9c5f8","associate_public_ip_address":true,"availability_zone":"us-east-1c","capacity_reservation_specification":[{"capacity_reservation_preference":"open","capacity_reservation_target":[]}],"cpu_core_count":1,"cpu_threads_per_core":2,"credit_specification":[{"cpu_credits":"unlimited"}],"disable_api_termination":false,"ebs_block_device":[],"ebs_optimized":false,"enclave_options":[{"enabled":false}],"ephemeral_block_device":[],"get_password_data":false,"hibernation":false,"host_id":null,"iam_instance_profile":"","id":"i-0b787386f31a9c5f8","instance_initiated_shutdown_behavior":"stop","instance_state":"running","instance_type":"t3.micro","ipv6_address_count":0,"ipv6_addresses":[],"key_name":"","metadata_options":[{"http_endpoint":"enabled","http_put_response_hop_limit":1,"http_tokens":"optional"}],"monitoring":false,"network_interface":[],"outpost_arn":"","password_data":"","placement_group":"","primary_network_interface_id":"eni-0c71c216ad45c7f94","private_dns":"ip-172-31-93-3.ec2.internal","private_ip":"172.31.93.3","public_dns":"ec2-54-88-69-47.compute-1.amazonaws.com","public_ip":"54.88.69.47","root_block_device":[{"delete_on_termination":true,"device_name":"/dev/xvda","encrypted":false,"iops":100,"kms_key_id":"","tags":{},"throughput":0,"volume_id":"vol-0860658ecbe7f9eb1","volume_size":8,"volume_type":"gp2"}],"secondary_private_ips":[],"security_groups":["terraform-20210717223826807600000001"],"source_dest_check":true,"subnet_id":"subnet-5bcf847a","tags":{"Name":"Terraform MC"},"tags_all":{"Name":"Terraform MC"},"tenancy":"default","timeouts":null,"user_data":null,"user_data_base64":null,"volume_tags":null,"vpc_security_group_ids":["sg-0739355d046a7d49f"]},"sensitive_values":{"capacity_reservation_specification":[{"capacity_reservation_target":[]}],"credit_specification":[{}],"ebs_block_device":[],"enclave_options":[{}],"ephemeral_block_device":[],"ipv6_addresses":[],"metadata_options":[{}],"network_interface":[],"root_block_device":[{"tags":{}}],"secondary_private_ips":[],"security_groups":[false],"tags":{},"tags_all":{},"vpc_security_group_ids":[false]},"depends_on":["aws_default_vpc.default","aws_security_group.allow_http"]},{"address":"aws_s3_bucket.bucket","mode":"managed","type":"aws_s3_bucket","name":"bucket","provider_name":"registry.terraform.io/hashicorp/aws","schema_version":0,"values":{"acceleration_status":"","acl":"private","arn":"arn:aws:s3:::explicit-dependency20210718033610555700000001","bucket":"explicit-dependency20210718033610555700000001","bucket_domain_name":"explicit-dependency20210718033610555700000001.s3.amazonaws.com","bucket_prefix":"explicit-dependency","bucket_regional_domain_name":"explicit-dependency20210718033610555700000001.s3.amazonaws.com","cors_rule":[],"force_destroy":false,"grant":[],"hosted_zone_id":"Z3AQBSTGFYJSTF","id":"explicit-dependency20210718033610555700000001","lifecycle_rule":[],"logging":[],"object_lock_configuration":[],"policy":null,"region":"us-east-1","replication_configuration":[],"request_payer":"BucketOwner","server_side_encryption_configuration":[],"tags":null,"tags_all":{},"versioning":[{"enabled":false,"mfa_delete":false}],"website":[],"website_domain":null,"website_endpoint":null},"sensitive_values":{"cors_rule":[],"grant":[],"lifecycle_rule":[],"logging":[],"object_lock_configuration":[],"replication_configuration":[],"server_side_encryption_configuration":[],"tags_all":{},"versioning":[{}],"website":[]}},{"address":"aws_security_group.allow_http","mode":"managed","type":"aws_security_group","name":"allow_http","provider_name":"registry.terraform.io/hashicorp/aws","schema_version":1,"values":{"arn":"arn:aws:ec2:us-east-1:188556757614:security-group/sg-0739355d046a7d49f","description":"Managed by Terraform","egress":[],"id":"sg-0739355d046a7d49f","ingress":[{"cidr_blocks":["0.0.0.0/0"],"description":"HTTP traffic","from_port":80,"ipv6_cidr_blocks":[],"prefix_list_ids":[],"protocol":"tcp","security_groups":[],"self":false,"to_port":80},{"cidr_blocks":["0.0.0.0/0"],"description":"SSH traffic","from_port":22,"ipv6_cidr_blocks":[],"prefix_list_ids":[],"protocol":"tcp","security_groups":[],"self":false,"to_port":22}],"name":"terraform-20210717223826807600000001","name_prefix":"terraform-","owner_id":"188556757614","revoke_rules_on_delete":false,"tags":{},"tags_all":{},"timeouts":null,"vpc_id":"vpc-0eb22b73"},"sensitive_values":{"egress":[],"ingress":[{"cidr_blocks":[false],"ipv6_cidr_blocks":[],"prefix_list_ids":[],"security_groups":[]},{"cidr_blocks":[false],"ipv6_cidr_blocks":[],"prefix_list_ids":[],"security_groups":[]}],"tags":{},"tags_all":{}},"depends_on":["aws_default_vpc.default"]}]}}}  
  ```
</details>

#### Graph

Con `terraform graph` podemos generar una representación visual de un archivo de estado o de plan. La salida está en formato DOT, que puede ser usado por GraphViz para generar gráficas.

Ejecuta el siguiente comando:

```sh
terraform graph
```

<details>
  <summary>Salida</summary>
  
  ```
    digraph {
            compound = "true"
            newrank = "true"
            subgraph "root" {
                    "[root] aws_default_vpc.default (expand)" [label = "aws_default_vpc.default", shape = "box"]
                    "[root] aws_instance.bucket_server (expand)" [label = "aws_instance.bucket_server", shape = "box"]
                    "[root] aws_instance.server (expand)" [label = "aws_instance.server", shape = "box"]
                    "[root] aws_instance.test_server (expand)" [label = "aws_instance.test_server", shape = "box"]
                    "[root] aws_s3_bucket.bucket (expand)" [label = "aws_s3_bucket.bucket", shape = "box"]
                    "[root] aws_security_group.allow_http (expand)" [label = "aws_security_group.allow_http", shape = "box"]
                    "[root] provider[\"registry.terraform.io/hashicorp/aws\"]" [label = "provider[\"registry.terraform.io/hashicorp/aws\"]", shape = "diamond"]
                    "[root] aws_default_vpc.default (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
                    "[root] aws_instance.bucket_server (expand)" -> "[root] aws_s3_bucket.bucket (expand)"
                    "[root] aws_instance.server (expand)" -> "[root] aws_security_group.allow_http (expand)"
                    "[root] aws_instance.test_server (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
                    "[root] aws_s3_bucket.bucket (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
                    "[root] aws_security_group.allow_http (expand)" -> "[root] aws_default_vpc.default (expand)"
                    "[root] meta.count-boundary (EachMode fixup)" -> "[root] aws_instance.bucket_server (expand)"
                    "[root] meta.count-boundary (EachMode fixup)" -> "[root] aws_instance.server (expand)"
                    "[root] meta.count-boundary (EachMode fixup)" -> "[root] aws_instance.test_server (expand)"
                    "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)" -> "[root] aws_instance.bucket_server (expand)"
                    "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)" -> "[root] aws_instance.server (expand)"
                    "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)" -> "[root] aws_instance.test_server (expand)"
                    "[root] root" -> "[root] meta.count-boundary (EachMode fixup)"
                    "[root] root" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)"
            }
    }
  ```
</details>

Para obtener el gráfico de un archivo de plan ocupamos el siguiente comando:

```sh
terraform graph -plan=out.tfplan
```

<details>
  <summary>Salida</summary>
  
  ```
    digraph {
            compound = "true"
            newrank = "true"
            subgraph "root" {
                    "[root] aws_instance.test_server" [label = "aws_instance.test_server", shape = "box"]
                    "[root] aws_instance.test_server (expand)" [label = "aws_instance.test_server", shape = "box"]
                    "[root] provider[\"registry.terraform.io/hashicorp/aws\"]" [label = "provider[\"registry.terraform.io/hashicorp/aws\"]", shape = "diamond"]
                    "[root] aws_instance.test_server (expand)" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"]"
                    "[root] aws_instance.test_server" -> "[root] aws_instance.test_server (expand)"
                    "[root] meta.count-boundary (EachMode fixup)" -> "[root] aws_instance.test_server"
                    "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)" -> "[root] aws_instance.test_server"
                    "[root] root" -> "[root] meta.count-boundary (EachMode fixup)"
                    "[root] root" -> "[root] provider[\"registry.terraform.io/hashicorp/aws\"] (close)"
            }
    }
  ```
</details>

Ve a [Graphviz Online](https://dreampuf.github.io/GraphvizOnline) y pega la salida para visualizar el gráfico.

## Limpieza

Elimina todos los recursos de este taller con el comando:

```sh
terraform destroy -auto-approve
```

## Conclusión

En este taller aprendimos sobre dependencias implícitas y explícitas. También experimentamos con algunos comandos fuera del flujo de trabajo principal.

### Comandos

- terraform validate
  - json
- terraform fmt
  - check
  - write
- terraform show
  - "out.tfplan"
  - json
- terraform graph
  - plan