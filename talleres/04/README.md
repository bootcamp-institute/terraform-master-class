# Usando variables y data sources para hacer configuraciones dinámicas

Normalmente queremos crear archivos de configuración que se puedan adaptar a distintos escenarios. Esta flexibilidad la podemos obtener a través de parametrizar nuestros recursos y proveer los valores en tiempo de ejecución. Esto es posible con las _variables de entrada_.

En ocasiones queremos desacoplar la creación de recursos entre distintas configuraciones de Terraform. O quizá queremos hacer consultas sobre recursos existentes en nuestro proveedor para utilizar esos valores en nuestras propias configuraciones. Esto es posible con los _data sources_.

En este taller aprenderemos a:

- Ocupar variables en nuestros archivos de configuración
- Usar data sources para obtener datos
- Obtener atributos de recursos a través de outputs

### Ocupar variables en nuestros archivos de configuración

Es posible escribir archivos de configuración con atributos cuyos valores serán definidos en tiempo de planeación y/o ejecución. Para esto aprenderemos a usar el bloque de tipo [variable](https://www.terraform.io/docs/language/values/variables.html) y todas las formas en que podemos pasar valores a nuestros atributos.

Empieza creando un nuevo directorio y estructura básica para nuestros recursos:

```sh
mkdir 04-variables
cd 04-variables
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

En el archivo `resources.tf` escribimos lo siguiente:

```tf
resource "aws_instance" "server" {
  ami           = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t3.micro"

  tags = {
    Name = "Workshop 4"
  }
}
```

Este bloque crea un servidor con 3 atributos con valores fijos: `ami`, `instance_type` y el tag `Name`. Vamos a hacer más flexible esta configuración a través de variables.

Iniciamos creando un nuevo archivo llamado `variables.tf`:

```sh
touch variables.tf
```

Y colocamos los siguientes bloques para nuestras variables:

```tf
variable "ami_id" {
  type        = string
  description = "The ID of the Amazon Machine Image to use"
  default     = "ami-0dc2d3e4c0f9ebd18"
}

variable "instance_type" {
  type = string
}

variable "name" {}

```

A continuación, modificamos nuestro recurso `aws_instance` en el archivo `resources.tf`:

```tf
resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = var.name
  }
}
```

Inicializamos el proyecto con:

```sh
terraform init
```

Y ejecutamos con:

```sh
terraform apply
```

Terraform nos pedirá el valor de un par de variables, contestamos lo siguiente:

```sh
var.instance_type
  Enter a value: t3.micro
```

```sh
var.name
  Enter a value: workshop4
```

<details>
  <summary>Salida</summary>
  
  ```
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
      + create
    
    Terraform will perform the following actions:
    
      # aws_instance.server will be created
      + resource "aws_instance" "server" {
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
              + "Name" = "workshop4"
            }
          + tags_all                             = {
              + "Name" = "workshop4"
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

Cuando pide la confirmación:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Escribe la palabra `yes` y da _Enter_ para confirmar la creación del recurso.

Explicación:

1. Creamos tres bloques de tipo `variable` para el `ami_id`, `instance_type` y `name` en el archivo `variales.tf` (no importa el nombre del archivo donde viven)
2. Ya que `ami_id` tiene un valor por default, no es necesario pasar un valor en tiempo de planeación o ejecución
3. Al correr el comando `apply`, Terraform nos pide los valores para las variables `instance_type` y `name`. Esto también es cierto si corremos el comando `plan`
4. Validamos que la infraestructura se crea con los valores que le pasamos en tiempo de creación

##### Ejercicio

Ejecuta un `terraform plan` y escribe valores diferentes para las variables. Valida que el plan agenda una actualización.

#### Asignando valores a través de variales de entorno

Ejecuta el siguiente comando:

```sh
terraform plan -input=false
```

<details>
  <summary>Error</summary>
  
  ```
    │ Error: No value for required variable
    │ 
    │   on variables.tf line 7:
    │    7: variable "instance_type" {
    │ 
    │ The root module input variable "instance_type" is not set, and has no default value. Use a -var or -var-file command line argument to provide a value for this variable.
    ╵
    ╷
    │ Error: No value for required variable
    │ 
    │   on variables.tf line 11:
    │   11: variable "name" {}
    │ 
    │ The root module input variable "name" is not set, and has no default value. Use a -var or -var-file command line argument to provide a value for this variable.
  ```
</details>

Cuando ocupamos la opción `input=false` en los comandos `plan` o `apply`, no es posible introducir valores en tiempo de ejecución. Debido a que tenemos valores no definidos para nuestras variables `instance_type` y `name`, el comando falla. Esto es útil en ambientes de integración continua (CI).

Es posible asignar valores a nuestras variables a través de [variables de entorno](https://www.terraform.io/docs/language/values/variables.html#environment-variables):

```sh
export TF_VAR_instance_type=t3.micro
export TF_VAR_name=workshop4-env-vars
```

Crear la infraestructura con:

```sh
terraform plan -input=false -out=out.tfplan
terraform apply "out.tfplan"
```

<details>
  <summary>Salida</summary>
  
  ```
    aws_instance.server: Modifying... [id=i-0c75b53b142826de4]
    aws_instance.server: Modifications complete after 1s [id=i-0c75b53b142826de4]
    
    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
  ```
</details>

Explicación:

1. Establecimos variables de ambiente con el prefijo `TF_VAR` seguido de un `_` y el nombre de la variable a la que queremos establecer el valor (`instance_type` y `name`)
2. Ejecutamos un comando `plan` y con la bandera `input=false` para asegurarnos de que falle en caso de que hayamos olvidado establecer el valor de una variable. Y guardamos el plan en el archivo `out.tfplan`
3. Aplicamos los cambios guardados en el archivo de plan
4. Validamos los cambios en la consola de EC2


##### Ejercicio

Investiga el valor del AMI de Ubuntu para la región _us-east-1_ y establece el valor de la variable `ami_id` a través de una variable de entorno. Luego ejecuta el comando `plan` y comprueba si Terraform ocupa el valor por default o el de la variable de ambiente.

<details>
  <summary>Respuesta</summary>
  
  ```sh
    export TF_VAR_ami_id=ami-09e67e426f25ce0d7
    terraform plan
  ```
  Las variables de entorno toman precedencia sobre los valores por default.
</details>


##### Limpieza

Borra la variables de ambiente:

```sh
unset TF_VAR_ami_id
unset TF_VAR_instance_type
unset TF_VAR_name
```

#### Asignando valores a través de archivos de variables

Terraform puede leer archivos que contienen los valores de variables y aplicarlos a los recursos. Esto es conveniente cuando tenemos valores _no sensibles_ que pueden ser guardados junto con el código de la infraestructura.

Estos archivos son conocidos como [tfvars](https://www.terraform.io/docs/language/values/variables.html#variable-definitions-tfvars-files) y pueden tener la extensión `.tfvars` o `tfvars.json`. Terraform carga automáticamente:

- Archivos llamados `terraform.tfvars` o `terraform.tfvars.json`
- Cualquier archivo que tenga la extensión ``.auto.tfvars` o `.auto.tfvars.json`

Si deseamos ocupar otro nombre de archivo, por ejemplo `mis-variables-de-desarrollo.tfvars`, ocuparemos la opción `-var-file` de los comandos `plan` y `apply`

Empezamos creando un archivo de variables:

```sh
touch terraform.tfvars
```

y escribimos lo siguiente:

```tfvars
instance_type = "t3.micro"
```

Ejecuta el comando:

```sh
terraform apply -input=false
```

<details>
  <summary>Error</summary>
  
  ```
    │ Error: No value for required variable
    │ 
    │   on variables.tf line 11:
    │   11: variable "name" {}
    │ 
    │ The root module input variable "name" is not set, and has no default value. Use a -var or -var-file command line argument to provide a value for this variable.
  ```
</details>

Obtenemos un error porque aún nos falta definir el valor de nuestra variable `name`. Creamos un nuevo archivo:

```sh
touch myvars.tfvars
```

con el siguiente contenido:

```tfvars
name = "workshop4-tfvars"
```

Planeamos y ejecutamos:

```sh
terraform plan -input=false -var-file=myvars.tfvars -out=out.tfplan
terraform apply "out.tfplan"
```

<details>
  <summary>Salida</summary>
  
  ```
    aws_instance.server: Modifying... [id=i-0c75b53b142826de4]
    aws_instance.server: Modifications complete after 2s [id=i-0c75b53b142826de4]
    
    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
  ```
</details>

Explicación:

1. Creamos un archivo `terraform.tfvars` con el valor de la variable `instance_type`. Este archivo es cargado automáticamente por Terraform
2. Ejecutamos el comando `apply` con la opción `-input=false` para forzar un error en caso de que falte una variable
3. Creamos un archivo `myvars.tfvars` y ponemos el valor de la variable `name`. Este archivo no es cargado automáticamente por Terraform, así que debemos ocupar la opción `-var-file` para pasar la ubicación del archivo. Esta opción es soportada por el comando `plan` y `apply`
4. Ejecutamos el resultado de la planeación
5. Validamos que el recurso se modificó correctamente en AWS

##### Ejercicio

Crea un archivo con extensión `.auto.tfvars` y coloca los valores de todas las variables. Ejecuta un `plan` y valida el orden de precedencia.

#### Asignando valores a través de la línea de comandos

Es posible pasar valores a las variables a través de una opción de los comandos `plan` y `apply`. Estos valores sobreescriben cualquier otro valor definido en archivos de variables o variables de entorno.

Ejecutamos el siguiente comando:

```sh
terraform plan -var name="workshop4-cli" -var instance_type="t3.micro" -out=out.tfplan

terraform apply "out.tfplan"
```

<details>
  <summary>Salida</summary>
  
  ```
    aws_instance.server: Modifying... [id=i-0c75b53b142826de4]
    aws_instance.server: Modifications complete after 1s [id=i-0c75b53b142826de4]
    
    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
  ```
</details>

Explicación:

1. Los comandos `plan` y `apply` soportan la opción `-var` para recibir los valores de variables. El formato es: `-var nombre_de_variable="valor_de_variable`
2. Ejecutamos los cambios
3. Validamos los cambios en la consola de EC2

### Usar data sources para obtener datos

Es posible que tus configuraciones requieran de datos sobre recursos que ya existen en tu proveedor y ocuparlos en tus propios recursos. Ya sea que fueron creados con Terraform, otra herramienta de IaC o de forma manual.

Hasta ahora, ocupamos un AMI ID fijo de Amazon Linux 2 para levantar nuestro servidor. Sin embargo, ¿qué sucede si queremos que nuestras configuraciones siempre ocupen el AMI más reciente de este sistema operativo? Para este fin, podemos ocupar los [data sources](https://www.terraform.io/docs/language/data-sources/index.html) de Terraform.

Creamos un nuevo archivo `data.tf`:

```sh
touch data.tf
```

Y colocamos el siguiente bloque de tipo `data`:

```tf
data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}
```

Actualizamos el archivo `resources.tf` para hacer uso del AMI ID obtenido por el
_data source_:

```tf
resource "aws_instance" "server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  tags = {
    Name = var.name
  }
}
```

Aplicamos los cambios:

```sh
terraform plan -var name="workshop4-data" -out=out.tfplan
terraform apply "out.tfplan"
```

Explicación:

1. Creamos un archivo `data.tf` (el nombre no es importante) para alojar nuestras configuraciones de _data sources_
2. Los _data sources_ ocupan un bloque llamado `data`, la primer etiqueta `"aws_ami"` indica el tipo de consulta que vamos a hacer al recurso del proveedor, y la segunda etiqueta `"amazon_linux_2"` es un nombre local que ocuparemos para hacer referencia a los datos del recurso
3. Para ocupar el resultado del _data source_, hacemos referencia a su dirección de recurso iniciando con la palabra `data`:
  - Para nuestro _data source_ la dirección es `data.aws_ami.amazon_linux_2` y ocupamos su atributo id de la siguiente forma: `data.aws_ami.amazon_linux_2.id`

### Obtener atributos de recursos a través de outputs

Existen datos de un recurso que son conocidos hasta después de su creación y que quisieramos ocupar después de ejecutar el comando `apply`. Para esto podemos ocupar los bloques de tipo [output](https://www.terraform.io/docs/language/values/outputs.html).

Crea un archivo:

```sh
touch outputs.tf
```

y coloca el siguiente bloque:

```tf
output "server_public_ip" {
  value = aws_instance.server.public_ip
}
```

Y ejecuta el comando:

```sh
terraform apply -var-file=myvars.tfvars -auto-approve
```

Aparte del resumen de creación, al final devuelve algo parecido a:

```
Outputs:

server_public_ip = "x.x.x.x"
```

También podemos utilizar el comando [output](https://www.terraform.io/docs/cli/commands/output.html) para obtener la información:

```sh
terraform output
```

<details>
  <summary>Salida</summary>
  
  ```
    server_public_ip = "3.85.86.197"
  ```
</details>

O solo consultar el valor que nos interesa:

```sh
terraform output server_public_ip
```

<details>
  <summary>Salida</summary>
  
  ```
    "3.85.86.197"
  ```
</details>

Si deseamos obtener el valor sin comillas:

```sh
terraform output -raw server_public_ip
```

<details>
  <summary>Salida</summary>
  
  ```
    3.85.86.197
  ```
</details>

Explicación:

1. Los bloques `output` en el módulo raíz, sirven para exponer información de nuestros recursos a través del archivo de estado y podemos consultarlo con la CLI de Terraform.
2. Es necesario aplicar los cambios para obtener los resultados del bloque `output`
3. Podemos consultar los valores de salida con el comando `terraform output`

## Limpieza

Destruye toda la infraestructura con el comando:

```sh
tf destroy -var-file=myvars.tfvars -auto-approve
```

## Ejercicio

1. Crea una variable para definir la región de AWS
2. Establece el valor a través del archivo `terraform.tfvars`
3. Ocupa un _data source_ para obtener el security group `default` de la VPC `default` y ocupa el ID en el servidor
4. Crea los recursos y valida que el servidor se crea en la región y con el security group elegidos
5. Destruye los recursos con el comando `destroy`


## Conclusión

En este taller aprendimos a ocupar bloques de tipo `variable`, `output` y `data` para hacer configuraciones dinámicas y flexibles. De forma práctica, entendimos la [precedencia de asignación de valores](https://www.terraform.io/docs/language/values/variables.html#variable-definition-precedence) a las variables.

### Comandos

- plan
  - input
  - var
  - var-file
- apply
  - input
  - var
  - var-file
- destroy
  - var
  - var-file
- output
  - "nombre"
  - raw