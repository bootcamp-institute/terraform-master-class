# Administración de estado en AWS

Hasta ahora hemos ocupado nuestro directorio de trabajo para almacenar el archivo de estado que contiene la información sobre la infraestructura que administra Terraform. Almacenar este archivo de forma local tiene desventajas, como:

- No permite trabajar de forma colaborativa en una misma base de código
- Si se borra el archivo por error, la información no se puede recuperar y Terraform no puede modificar o eliminar los recursos que administraba

Configurando un [backend](https://www.terraform.io/docs/language/settings/backends/index.html) podemos almacenar el archivo de estado en un lugar remoto y, en algunos casos, también ejecutar acciones de forma remota.

En este taller aprenderemos a:

- Usar S3 como backend para almacenar el estado
- Utilizar configuraciones parciales de backends
- Acceder a valores en el estado de otra configuración
- Administrar estado a través de la línea de comandos

### Usar S3 como backend para almacenar el estado

Primero creamos un bucket de S3:

```sh
BUCKET_NAME=terraform-masterclass-$(tr -dc a-z0-9 </dev/urandom | head -c 8)
aws --region us-east-1 s3 mb s3://$BUCKET_NAME
```

Y una carpeta para los archivos de configuración:

```sh
mkdir 05-networking
cd 05-networking
touch main.tf resources.tf
```

En el archivo `main.tf` colocamos lo siguiente:

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

Creamos un [security group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) dentro del archivo `resources.tf`:

```sh
resource "aws_default_vpc" "default" {}

resource "aws_security_group" "server_ssh" {
  name   = "tf_server_ssh"
  vpc_id = aws_default_vpc.default.id

  ingress {
    description = "SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

Inicializamos el proyecto y creamos la infraestructura:

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
    aws_security_group.server_ssh: Creating...
    aws_security_group.server_ssh: Creation complete after 2s [id=sg-0b8f2c4489da25acb]
    
    Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
  ```
</details>

Ahora ejecutamos el siguiente comando para sobreescribir el archivo `main.tf` con una configuración de backend:

```sh
cat << EOF > main.tf
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "$BUCKET_NAME"
    key    = "05/networking/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}
EOF
```

Y ejecutamos el comando `init`:

```sh
terraform init
```

```
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: 
```

Responde `yes` y da _Enter_

Explicación:

1. Creamos una configuración sin definición de _backend_ y aplicamos los cambios. Por default, estamos ocupando el _backend_ local con el archivo `terraform.tfstate`
2. Incluimos la configuración de _backend_ en el bloque `terraform` y ejecutamos el comando `init`:
  - Terraform detecta que tenímos un archivo local y nos pregunta si queremos migrarlo
  - Al contestar que sí, Terraform sube el archivo al bucket de S3 y a partir de ahora guardará los cambios en esta locación remota
3. Validamos que el archivo de estado se encuentra en el bucket de S3

Ahora veremos que sucede si revertimos la configuración:

1. Comenta la configuración de _backend_ en el archivo `main.tf`
2. Ejecuta el comando `init`

<details>
  <summary>Error</summary>
  
  ```
    Initializing the backend...
    ╷
    │ Error: Backend configuration changed
    │ 
    │ A change in the backend configuration has been detected, which may require migrating existing state.
    │ 
    │ If you wish to attempt automatic migration of the state, use "terraform init -migrate-state".
    │ If you wish to store the current configuration with no changes to the state, use "terraform init -reconfigure".
  ```
</details>

3. Intenta el comando `terraform init -migrate-state`

```
Initializing the backend...
Terraform has detected you're unconfiguring your previously set "s3" backend.
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "s3" backend to the
  newly configured "local" backend. No existing state was found in the newly
  configured "local" backend. Do you want to copy this state to the new "local"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: 
```

Responde `yes` y da _Enter_

4. Regresa la configuración de _backend_ de S3 y ejecuta el comando `init` para dejar lista nuestra configuración para los siguientes ejercicios
5. Valida con el comando `plan`: `No changes. Your infrastructure matches the configuration.`

### Utilizar configuraciones parciales de backends

Es posible declarar la configuración de `backend` sin describir todos sus atributos en el archivo de configuración. Cuando uno de estos atributos es definido en tiempo de ejecución decimos que es una _configuración parcial de backend_. Estos atributos pueden ser pasados:

- De forma dinámica
- Con opciones dentro de la CLI
- Con un archivo de variables

Experimentaremos con el atributo `key` de la configuración de _backend_, para eso lo borramos de nuestro archivo `main.tf`:

```tf
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "terraform-masterclass-7nr7mnz6"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}
```

Si intentamos hacer un `init` recibimos un error

```sh
terraform init
```

```
Initializing the backend...
╷
│ Error: Backend configuration changed
│ 
│ A change in the backend configuration has been detected, which may require migrating existing state.
│ 
│ If you wish to attempt automatic migration of the state, use "terraform init -migrate-state".
│ If you wish to store the current configuration with no changes to the state, use "terraform init -reconfigure".
```

Para corregirlo ejecutamos el siguiente comando:

```sh
terraform init -reconfigure
```

Terraform nos permite introducir el valor del atributo _key_ de forma **dinámica**:

```
Initializing the backend...
key
  The path to the state file inside the bucket

  Enter a value: 
```

Contestamos con el valor: `05/networking/terraform.tfstate`. Ejecuta el comando `plan` para validar que sigue accediendo al archivo de estado correcto.

Podemos ocupar la **opción del comando** init `-backend-config="KEY=VALUE"` para configurar un atributo parcial de _backend_:

```sh
tf init -reconfigure -backend-config="key=05/networking-test/terraform.tfstate"
```

Si ejecutamos un comando `plan`, recibimos como salida: `Plan: 2 to add, 0 to change, 0 to destroy.`. Esto es porque ahora apuntamos a una ruta diferente para el archivo de estado donde no existe nada.

Por último, es posible ocupar un **archivo de variables** para definir los valores parciales de configuración de _backend_:

```sh
touch backend.tfvars
```

Con el siguiente contenido:

```tfvars
key = "05/networking/terraform.tfstate"
```

Y ejecutamos el comando `init` con la opción `-backend-config` para apuntar a la ruta de nuestro archivo:

```sh
terraform init -reconfigure -backend-config=backend.tfvars
```

Ejecutamos un comando `plan` para validar que la configuración vuelve a apuntar a nuestro archivo de estado original.

### Acceder a valores en el estado de otra configuración

Al mantener el archivo de estado en una locación remota, diferentes configuraciones pueden acceder a sus atributos definidos en _outputs_ usando el _data source_ [terraform_remote_state](https://www.terraform.io/docs/language/state/remote-state-data.html).

Primero creamos un nuevo archivo para crear un nuevo bloque _output_:

```sh
touch outputs.tf
```

llenamos con el bloque:

```tf
output "sg_id" {
  value = aws_security_group.server_ssh.id
}
```

y aplicamos los cambios:

```sh
terraform apply -auto-approve
```

Ahora creamos una nueva carpeta para un almacenar otros archivos de configuración:

```sh
mkdir 05-server
cd 05-server
touch main.tf data.tf resources.tf
```

Ejecutamos el siguiente comando para llenar el archivo `main.tf`:

```sh
cat << EOF > main.tf
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "$BUCKET_NAME"
    key    = "05/server/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}
EOF
```

Y el siguiente comando para llenar el archivo `data.tf`:

```sh
cat << EOF > data.tf
data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "$BUCKET_NAME"
    key    = "05/networking/terraform.tfstate"
    region = "us-east-1"
  }
}
EOF
```

Y en el archivo `resources.tf`:

```tf
resource "aws_instance" "server" {
  ami                    = "ami-0dc2d3e4c0f9ebd18"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.sg_id]

  tags = {
    Name = "Remote state"
  }
}
```

```sh
terraform init
terraform plan -out=out.tfplan
terraform apply "out.tfplan"
```

Explicación:

1. Empezamos creando un bloque _output_ en la configuración de _networking_. Esta variable de salida guarda el ID del Security Group y podremos acceder a ella a través de un _data source_
2. Creamos una configuración nueva para un servidor que usará el Security Group de la configuración de _networking_
3. Utilizamos el _data source_ `terraform_remote_state` para obtener datos de un estado remoto. La configuración es similar a la realizada en el _backend_ de _networking_
4. En el recurso del servidor ocupamos la dirección de recurso `data.terraform_remote_state.networking.outputs.sg_id` para acceder al ID del Security Group.
5. Validamos que el servidor fue creado con el Security Group esperado


### Administrar estado a través de la línea de comandos

El archivo de estado no debe modificarse manualmente, sin emabargo el comando `terraform state` cuenta con algunos subcomandos que nos ayudan a administrar los contenidos del archivo.

Para listar los recursos de nuestro archivo de estado (en formato de dirección de recurso):

```sh
terraform state list
```

<details>
  <summary>Salida</summary>
  
  ```
    data.terraform_remote_state.networking
    aws_instance.server
  ```
</details>

Para obtener la configuración de un recurso en específico:

```sh
terraform state show aws_instance.server
```

<details>
  <summary>Salida</summary>
  
  ```
    # aws_instance.server:
    resource "aws_instance" "server" {
        ami                                  = "ami-0dc2d3e4c0f9ebd18"
        arn                                  = "arn:aws:ec2:us-east-1:188556757614:instance/i-0540eddbec7e101f1"
        associate_public_ip_address          = true
        availability_zone                    = "us-east-1b"
        cpu_core_count                       = 1
        cpu_threads_per_core                 = 2
        disable_api_termination              = false
        ebs_optimized                        = false
        get_password_data                    = false
        hibernation                          = false
        id                                   = "i-0540eddbec7e101f1"
        instance_initiated_shutdown_behavior = "stop"
        instance_state                       = "running"
        instance_type                        = "t3.micro"
        ipv6_address_count                   = 0
        ipv6_addresses                       = []
        monitoring                           = false
        primary_network_interface_id         = "eni-0762e79795bd811a2"
        private_dns                          = "ip-172-31-5-55.ec2.internal"
        private_ip                           = "172.31.5.55"
        public_dns                           = "ec2-3-228-11-161.compute-1.amazonaws.com"
        public_ip                            = "3.228.11.161"
        secondary_private_ips                = []
        security_groups                      = [
            "tf_server_ssh",
        ]
        source_dest_check                    = true
        subnet_id                            = "subnet-97713df1"
        tags                                 = {
            "Name" = "Terraform MC"
        }
        tags_all                             = {
            "Name" = "Terraform MC"
        }
        tenancy                              = "default"
        vpc_security_group_ids               = [
            "sg-045677ebe76997ac3",
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
            volume_id             = "vol-076c3af97cf03e166"
            volume_size           = 8
            volume_type           = "gp2"
        }
    }
  ```
</details>

En ocasiones, queremos obtener el archivo de estado remoto o subirlo nuevamente, para esto ocupamos los subcomandos `pull` y `push`. Normalmente se ocupa como respaldo y recuperación de errores:

```sh
terraform state pull > terraform.tfstate
```

```sh
terraform state push terraform.tfstate
```

Terraform es capaz de hacer un seguimiento de nuestros recursos a través del nombre local de recurso, si decidimos cambiar este nombre después de la creación, Terraform planea la destrucción y creación de un nuevo recurso.

Cambiamos el archivo `resources.tf`:

```tf
resource "aws_instance" "web_server" {
  ami                    = "ami-0dc2d3e4c0f9ebd18"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.sg_id]

  tags = {
    Name = "Remote state"
  }
}
```

Y ejecutamos un comando `plan`:

```sh
terraform plan
```

<details>
  <summary>Salida</summary>
  
  ```
    Terraform will perform the following actions:
    
      # aws_instance.server will be destroyed
      - resource "aws_instance" "server" {
          - ami                                  = "ami-0dc2d3e4c0f9ebd18" -> null
          - arn                                  = "arn:aws:ec2:us-east-1:188556757614:instance/i-0540eddbec7e101f1" -> null
          - associate_public_ip_address          = true -> null
          - availability_zone                    = "us-east-1b" -> null
          - cpu_core_count                       = 1 -> null
          - cpu_threads_per_core                 = 2 -> null
          - disable_api_termination              = false -> null
          - ebs_optimized                        = false -> null
          - get_password_data                    = false -> null
          - hibernation                          = false -> null
          - id                                   = "i-0540eddbec7e101f1" -> null
          - instance_initiated_shutdown_behavior = "stop" -> null
          - instance_state                       = "running" -> null
          - instance_type                        = "t3.micro" -> null
          - ipv6_address_count                   = 0 -> null
          - ipv6_addresses                       = [] -> null
          - monitoring                           = false -> null
          - primary_network_interface_id         = "eni-0762e79795bd811a2" -> null
          - private_dns                          = "ip-172-31-5-55.ec2.internal" -> null
          - private_ip                           = "172.31.5.55" -> null
          - public_dns                           = "ec2-3-228-11-161.compute-1.amazonaws.com" -> null
          - public_ip                            = "3.228.11.161" -> null
          - secondary_private_ips                = [] -> null
          - security_groups                      = [
              - "tf_server_ssh",
            ] -> null
          - source_dest_check                    = true -> null
          - subnet_id                            = "subnet-97713df1" -> null
          - tags                                 = {
              - "Name" = "Remote state"
            } -> null
          - tags_all                             = {
              - "Name" = "Remote state"
            } -> null
          - tenancy                              = "default" -> null
          - vpc_security_group_ids               = [
              - "sg-045677ebe76997ac3",
            ] -> null
    
          - capacity_reservation_specification {
              - capacity_reservation_preference = "open" -> null
            }
    
          - credit_specification {
              - cpu_credits = "unlimited" -> null
            }
    
          - enclave_options {
              - enabled = false -> null
            }
    
          - metadata_options {
              - http_endpoint               = "enabled" -> null
              - http_put_response_hop_limit = 1 -> null
              - http_tokens                 = "optional" -> null
            }
    
          - root_block_device {
              - delete_on_termination = true -> null
              - device_name           = "/dev/xvda" -> null
              - encrypted             = false -> null
              - iops                  = 100 -> null
              - tags                  = {} -> null
              - throughput            = 0 -> null
              - volume_id             = "vol-076c3af97cf03e166" -> null
              - volume_size           = 8 -> null
              - volume_type           = "gp2" -> null
            }
        }
    
      # aws_instance.web_server will be created
      + resource "aws_instance" "web_server" {
          + ami                                  = "ami-0dc2d3e4c0f9ebd18"
          + arn                                  = (known after apply)
          + associate_public_ip_address          = (known after apply)
          + availability_zone                    = (known after apply)
          + cpu_core_count                       = (known after apply)
          + cpu_threads_per_core                 = (known after apply)
          + disable_api_termination              = (known after apply)
          + ebs_optimized                        = (known after apply)
          + get_password_data                    = false
          + host_id                              = (known after apply)
          + id                                   = (known after apply)
          + instance_initiated_shutdown_behavior = (known after apply)
          + instance_state                       = (known after apply)
          + instance_type                        = "t3.micro"
          + ipv6_address_count                   = (known after apply)
          + ipv6_addresses                       = (known after apply)
          + key_name                             = (known after apply)
          + monitoring                           = (known after apply)
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
              + "Name" = "Remote state"
            }
          + tags_all                             = {
              + "Name" = "Remote state"
            }
          + tenancy                              = (known after apply)
          + user_data                            = (known after apply)
          + user_data_base64                     = (known after apply)
          + vpc_security_group_ids               = [
              + "sg-045677ebe76997ac3",
            ]
    
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
    
    Plan: 1 to add, 0 to change, 1 to destroy.
  ```
</details>

Si queremos evitar la eliminación del recurso:

```sh
terraform state mv aws_instance.server aws_instance.web_server
```

Y validamos con:

```sh
terraform plan
```

<details>
  <summary>Salida</summary>
  
  ```
    aws_instance.web_server: Refreshing state... [id=i-0540eddbec7e101f1]
    
    No changes. Your infrastructure matches the configuration.
  ```
</details>

Si queremos elimiar un recurso del archivo para que Terraform deje de administrarlo:

```sh
terraform state pull > terraform.tfstate
terraform state rm aws_instance.web_server
```

Si ejecutamos un `plan` nos damos cuenta que Terraform ya no hace seguimiento del servidor creado anteriormente

```sh
terraform plan`
```

<details>
  <summary>Salida</summary>
  
  ```
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
      + create
    
    Terraform will perform the following actions:
    
      # aws_instance.web_server will be created
      + resource "aws_instance" "web_server" {
          + ami                                  = "ami-0dc2d3e4c0f9ebd18"
          + arn                                  = (known after apply)
          + associate_public_ip_address          = (known after apply)
          + availability_zone                    = (known after apply)
          + cpu_core_count                       = (known after apply)
          + cpu_threads_per_core                 = (known after apply)
          + disable_api_termination              = (known after apply)
          + ebs_optimized                        = (known after apply)
          + get_password_data                    = false
          + host_id                              = (known after apply)
          + id                                   = (known after apply)
          + instance_initiated_shutdown_behavior = (known after apply)
          + instance_state                       = (known after apply)
          + instance_type                        = "t3.micro"
          + ipv6_address_count                   = (known after apply)
          + ipv6_addresses                       = (known after apply)
          + key_name                             = (known after apply)
          + monitoring                           = (known after apply)
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
              + "Name" = "Remote state"
            }
          + tags_all                             = {
              + "Name" = "Remote state"
            }
          + tenancy                              = (known after apply)
          + user_data                            = (known after apply)
          + user_data_base64                     = (known after apply)
          + vpc_security_group_ids               = [
              + "sg-045677ebe76997ac3",
            ]
    
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

Regresamos el archivo de estado a su estado original:

```sh
terraform state push -force terraform.tfstate
```

## Limpieza

En las carpetas `05-server` y `05-networking` ejecutamos el siguiente comando:

```sh
terraform destroy -auto-approve
```

## Conclusión

En este taller aprendimos a administrar el archivo de estado de forma remota a través de _backends_ y a manipular el archivo a través de los subcomandos de `terraform state`.

### Comandos

- init
  - migrate-state
  - reconfigure
  - backend-config
- state
  - list
  - show
  - pull
  - push
  - mv
  - rm
