# Ambientes con workspaces

Es posible mantener diferentes archivos de estado para una misma configuración, esto lo hacemos a través de [workspaces](https://www.terraform.io/docs/language/state/workspaces.html). Comúnmente los ocuparemos para crear diferentes "ambientes" con los mismos recursos.

En este laboratorio aprenderemos a:

- Crear y administrar workspaces
- Interpolación con terraform.workspace
- Forzar recreación de recursos

### Crear y administrar workspaces

Obtenemos el nombre del bucket que utilizamos en talleres anteriores para almacenar nuestros archivos de estado:

```sh
BUCKET_NAME=$(aws s3api list-buckets --query 'Buckets[*].[Name]' --output text | grep terraform-masterclass-*)
echo $BUCKET_NAME
```

Y creamos la estructura para empezar una nueva configuración:

```sh
mkdir 06-workspaces
cd 06-workspaces
touch main.tf resources.tf
```

Ahora ejecutamos el siguiente comando para llenar el archivo `main.tf`:

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
    key    = "06/workspaces/terraform.tfstate"
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

Siempre que ocupamos un backend que lo soporte, estamos haciendo uso de un _workspace_ llamado _default_. Puedes validarlo con el siguiente comando:

```sh
terraform workspace show
```

<details>
  <summary>Salida</summary>
  
  ```
    develop
  ```
</details>

Creamos un nuevo _workspace_ de la siguiente forma:

```sh
terraform workspace new develop
```

<details>
  <summary>Salida</summary>
  
  ```
    You're now on a new, empty workspace. Workspaces isolate their state,
    so if you run "terraform plan" Terraform will not see any existing state
    for this configuration.
  ```
</details>

Y obtenemos los _workspaces_ con el comando _list_ que nos muestra con `*` el actual:

```sh
terraform workspace list
```

<details>
  <summary>Salida</summary>
  
  ```
      default
    * develop
  ```
</details>

En el archivo de `resources.tf` creamos un servidor:

```tf
resource "aws_instance" "server" {
  ami           = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t3.micro"

  tags = {
    Name = "Workspace server"
  }
}
```

Planeamos y creamos la infraestructura:

```sh
terraform plan -out=out.tfplan
terraform apply "out.tfplan"
```

<details>
  <summary>Salida</summary>
  
  ```
    aws_instance.server: Creating...
    aws_instance.server: Still creating... [10s elapsed]
    aws_instance.server: Creation complete after 13s [id=i-02a0ef104c311d138]
    
    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
  ```
</details>

Ahora creamos un nuevo _workspace_ y planeamos la infraestructura:

```sh
terraform workspace new prod
terraform plan -out=out.tfplan
```

Por la salida, sabemos que un nuevo servidor será creado porque ahora nos encontramos en nuevo _workspace_. Aplicamos los cambios:

```sh
terraform apply "out.tfplan"
```

Ahora tenemos 2 servidores, uno en _develop_ y otro en _prod_. Si queremos movernos entre workspaces ocupamos el siguiente comando:

```sh
terraform workspace select develop
```

Y si queremos borrar un _workspace_ ocupamos:

```sh
terraform workspace delete prod
```

<details>
  <summary>Error</summary>
  
  ```
    Workspace "prod" is not empty.
    
    Deleting "prod" can result in dangling resources: resources that
    exist but are no longer manageable by Terraform. Please destroy
    these resources first.  If you want to delete this workspace
    anyway and risk dangling resources, use the '-force' flag.
  ```
</details>

No es posible borrar un _workspace_ cuyo archivo de estado contiene recursos.

##### Ejercicio

Elimina los recursos del _workspace_ prod y luego elimina el _workspace_.

<details>
  <summary>Respuesta</summary>
  
  ```
terraform workspace select prod
terraform destroy -auto-approve
terraform workspace select develop
terraform workspace delete prod
  ```
</details>

### Interpolación con terraform.workspace

Podemos ocupar el nombre del _workspace_ actual para ocuparlo dentro de nuestros recursos. En el archivo `resources.tf` modifica el bloque de servidor:

```tf
resource "aws_instance" "server" {
  ami           = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t3.micro"

  tags = {
    Name = "Workspace server - ${terraform.workspace}"
  }
}
```

Y aplica los cambios:

```sh
terraform apply -auto-approve
```

<details>
  <summary>Salida</summary>
  
  ```
    aws_instance.server: Refreshing state... [id=i-02a0ef104c311d138]
    
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
      ~ update in-place
    
    Terraform will perform the following actions:
    
      # aws_instance.server will be updated in-place
      ~ resource "aws_instance" "server" {
            id                                   = "i-02a0ef104c311d138"
          ~ tags                                 = {
              ~ "Name" = "Workspace server" -> "Workspace server - develop"
            }
          ~ tags_all                             = {
              ~ "Name" = "Workspace server" -> "Workspace server - develop"
            }
            # (27 unchanged attributes hidden)
    
    
    
    
    
            # (5 unchanged blocks hidden)
        }
    
    Plan: 0 to add, 1 to change, 0 to destroy.
    aws_instance.server: Modifying... [id=i-02a0ef104c311d138]
    aws_instance.server: Modifications complete after 2s [id=i-02a0ef104c311d138]
  ```
</details>

Valida en la consola de EC2 que el servidor ahora se llama `Workspace server - develop`

### Forzar recreación de recursos

En ocasiones queremos forzar la recreación de un recurso en la nube, sin necesidad de cambiar la configuración o eliminar y escribir nuevamente el bloque del recurso. Esto lo podemos lograr de dos formas

- Comando taint
- Apply -replace

Con el comando `taint`, indicamos en el archivo de estado que en la próxima ejecución queremos recrear un recurso:

```sh
terraform taint aws_instance.server
```

El comando `plan` nos muestra que el recurso va a ser eliminado y creado nuevamente:

```sh
terraform plan
```

<details>
  <summary>Salida</summary>
  
  ```
      # aws_instance.server is tainted, so must be replaced
    -/+ resource "aws_instance" "server" {
          ~ arn                                  = "arn:aws:ec2:us-east-1:188556757614:instance/i-02a0ef104c311d138" -> (known after apply)
          ~ associate_public_ip_address          = true -> (known after apply)
          ~ availability_zone                    = "us-east-1b" -> (known after apply)
          ~ cpu_core_count                       = 1 -> (known after apply)
          ~ cpu_threads_per_core                 = 2 -> (known after apply)
          ~ disable_api_termination              = false -> (known after apply)
          ~ ebs_optimized                        = false -> (known after apply)
          - hibernation                          = false -> null
          + host_id                              = (known after apply)
          ~ id                                   = "i-02a0ef104c311d138" -> (known after apply)
          ~ instance_initiated_shutdown_behavior = "stop" -> (known after apply)
          ~ instance_state                       = "running" -> (known after apply)
          ~ ipv6_address_count                   = 0 -> (known after apply)
          ~ ipv6_addresses                       = [] -> (known after apply)
          + key_name                             = (known after apply)
          ~ monitoring                           = false -> (known after apply)
          + outpost_arn                          = (known after apply)
          + password_data                        = (known after apply)
          + placement_group                      = (known after apply)
          ~ primary_network_interface_id         = "eni-08b852f340c554ece" -> (known after apply)
          ~ private_dns                          = "ip-172-31-12-49.ec2.internal" -> (known after apply)
          ~ private_ip                           = "172.31.12.49" -> (known after apply)
          ~ public_dns                           = "ec2-3-231-25-171.compute-1.amazonaws.com" -> (known after apply)
          ~ public_ip                            = "3.231.25.171" -> (known after apply)
          ~ secondary_private_ips                = [] -> (known after apply)
          ~ security_groups                      = [
              - "default",
            ] -> (known after apply)
          ~ subnet_id                            = "subnet-97713df1" -> (known after apply)
            tags                                 = {
                "Name" = "Workspace server - develop"
            }
          ~ tenancy                              = "default" -> (known after apply)
          + user_data                            = (known after apply)
          + user_data_base64                     = (known after apply)
          ~ vpc_security_group_ids               = [
              - "sg-10429a08",
            ] -> (known after apply)
            # (5 unchanged attributes hidden)
    
          ~ capacity_reservation_specification {
              ~ capacity_reservation_preference = "open" -> (known after apply)
    
              + capacity_reservation_target {
                  + capacity_reservation_id = (known after apply)
                }
            }
    
          - credit_specification {
              - cpu_credits = "unlimited" -> null
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
    
          ~ enclave_options {
              ~ enabled = false -> (known after apply)
            }
    
          + ephemeral_block_device {
              + device_name  = (known after apply)
              + no_device    = (known after apply)
              + virtual_name = (known after apply)
            }
    
          ~ metadata_options {
              ~ http_endpoint               = "enabled" -> (known after apply)
              ~ http_put_response_hop_limit = 1 -> (known after apply)
              ~ http_tokens                 = "optional" -> (known after apply)
            }
    
          + network_interface {
              + delete_on_termination = (known after apply)
              + device_index          = (known after apply)
              + network_interface_id  = (known after apply)
            }
    
          ~ root_block_device {
              ~ delete_on_termination = true -> (known after apply)
              ~ device_name           = "/dev/xvda" -> (known after apply)
              ~ encrypted             = false -> (known after apply)
              ~ iops                  = 100 -> (known after apply)
              + kms_key_id            = (known after apply)
              ~ tags                  = {} -> (known after apply)
              ~ throughput            = 0 -> (known after apply)
              ~ volume_id             = "vol-0868d6d5461d4b126" -> (known after apply)
              ~ volume_size           = 8 -> (known after apply)
              ~ volume_type           = "gp2" -> (known after apply)
            }
        }
    
    Plan: 1 to add, 0 to change, 1 to destroy.
  ```
</details>

Si aplicamos la infraestructura, Terraform creará un nuevo servidor:

```sh
terraform apply -auto-approve
```

<details>
  <summary>Salida</summary>
  
  ```
    aws_instance.server: Destroying... [id=i-02a0ef104c311d138]
    aws_instance.server: Still destroying... [id=i-02a0ef104c311d138, 10s elapsed]
    aws_instance.server: Still destroying... [id=i-02a0ef104c311d138, 20s elapsed]
    aws_instance.server: Still destroying... [id=i-02a0ef104c311d138, 30s elapsed]
    aws_instance.server: Still destroying... [id=i-02a0ef104c311d138, 40s elapsed]
    aws_instance.server: Still destroying... [id=i-02a0ef104c311d138, 50s elapsed]
    aws_instance.server: Still destroying... [id=i-02a0ef104c311d138, 1m0s elapsed]
    aws_instance.server: Still destroying... [id=i-02a0ef104c311d138, 1m10s elapsed]
    aws_instance.server: Destruction complete after 1m10s
    aws_instance.server: Creating...
    aws_instance.server: Still creating... [10s elapsed]
    aws_instance.server: Creation complete after 13s [id=i-022aa04944597c419]
    
    Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
  ```
</details>

Lo mismo se puede lograr con el siguiente comando:

```sh
terraform apply -replace="aws_instance.server"
```

<details>
  <summary>Salida</summary>
  
  ```
    # aws_instance.server will be replaced, as requested
    -/+ resource "aws_instance" "server" {
          ~ arn                                  = "arn:aws:ec2:us-east-1:188556757614:instance/i-022aa04944597c419" -> (known after apply)
          ~ associate_public_ip_address          = true -> (known after apply)
          ~ availability_zone                    = "us-east-1b" -> (known after apply)
          ~ cpu_core_count                       = 1 -> (known after apply)
          ~ cpu_threads_per_core                 = 2 -> (known after apply)
          ~ disable_api_termination              = false -> (known after apply)
          ~ ebs_optimized                        = false -> (known after apply)
          - hibernation                          = false -> null
          + host_id                              = (known after apply)
          ~ id                                   = "i-022aa04944597c419" -> (known after apply)
          ~ instance_initiated_shutdown_behavior = "stop" -> (known after apply)
          ~ instance_state                       = "running" -> (known after apply)
          ~ ipv6_address_count                   = 0 -> (known after apply)
          ~ ipv6_addresses                       = [] -> (known after apply)
          + key_name                             = (known after apply)
          ~ monitoring                           = false -> (known after apply)
          + outpost_arn                          = (known after apply)
          + password_data                        = (known after apply)
          + placement_group                      = (known after apply)
          ~ primary_network_interface_id         = "eni-0af92f6ba254df04e" -> (known after apply)
          ~ private_dns                          = "ip-172-31-3-207.ec2.internal" -> (known after apply)
          ~ private_ip                           = "172.31.3.207" -> (known after apply)
          ~ public_dns                           = "ec2-3-227-8-1.compute-1.amazonaws.com" -> (known after apply)
          ~ public_ip                            = "3.227.8.1" -> (known after apply)
          ~ secondary_private_ips                = [] -> (known after apply)
          ~ security_groups                      = [
              - "default",
            ] -> (known after apply)
          ~ subnet_id                            = "subnet-97713df1" -> (known after apply)
            tags                                 = {
                "Name" = "Workspace server - develop"
            }
          ~ tenancy                              = "default" -> (known after apply)
          + user_data                            = (known after apply)
          + user_data_base64                     = (known after apply)
          ~ vpc_security_group_ids               = [
              - "sg-10429a08",
            ] -> (known after apply)
            # (5 unchanged attributes hidden)
    
          ~ capacity_reservation_specification {
              ~ capacity_reservation_preference = "open" -> (known after apply)
    
              + capacity_reservation_target {
                  + capacity_reservation_id = (known after apply)
                }
            }
    
          - credit_specification {
              - cpu_credits = "unlimited" -> null
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
    
          ~ enclave_options {
              ~ enabled = false -> (known after apply)
            }
    
          + ephemeral_block_device {
              + device_name  = (known after apply)
              + no_device    = (known after apply)
              + virtual_name = (known after apply)
            }
    
          ~ metadata_options {
              ~ http_endpoint               = "enabled" -> (known after apply)
              ~ http_put_response_hop_limit = 1 -> (known after apply)
              ~ http_tokens                 = "optional" -> (known after apply)
            }
    
          + network_interface {
              + delete_on_termination = (known after apply)
              + device_index          = (known after apply)
              + network_interface_id  = (known after apply)
            }
    
          ~ root_block_device {
              ~ delete_on_termination = true -> (known after apply)
              ~ device_name           = "/dev/xvda" -> (known after apply)
              ~ encrypted             = false -> (known after apply)
              ~ iops                  = 100 -> (known after apply)
              + kms_key_id            = (known after apply)
              ~ tags                  = {} -> (known after apply)
              ~ throughput            = 0 -> (known after apply)
              ~ volume_id             = "vol-0d857c7ce1f2bda8f" -> (known after apply)
              ~ volume_size           = 8 -> (known after apply)
              ~ volume_type           = "gp2" -> (known after apply)
            }
        }
    
    Plan: 1 to add, 0 to change, 1 to destroy.
    
    Do you want to perform these actions in workspace "develop"?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.
    
      Enter a value: 
  ```
</details>

Escribe `yes` y da _Enter_ para confirmar.

##### Ejercicio

Existe el comando [untaint](https://www.terraform.io/docs/cli/commands/untaint.html) para revertir los efectos de marcar un recurso con `taint` en el archivo de estado. Valida su funcionamiento.

## Limpieza

Valida que eliminaste los recursos en el _workspace_ `prod`:

```sh
terraform workspace select prod && terraform destroy -auto-approve
```

Y elimina los recursos en el _workspace_ `develop`

```sh
terraform workspace select develop && terraform destroy -auto-approve
```

## Conclusión

En este taller aprendimos sobre la funcionalidad de _workspaces_ para crear diferentes archivos de estado a partir de una misma configuración. Esto generalmente se puede ocupar para crear "ambientes" similares.

También aprendimos a ocupar el comando `taint` y la opción `-replace` del comando `apply` para forzar la recreación de algún recurso.

### Comandos

- workspace
  - show
  - list
  - new
  - select
  - delete
- taint
- untaint
- apply
  - replace
