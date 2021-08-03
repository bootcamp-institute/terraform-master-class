# AWS y Terraform: Ciclo de vida de un recurso en la nube

Terraform cuenta con un [flujo de trabajo](https://www.terraform.io/guides/core-workflow.html) simple para escribir, crear y destruir infraestructura. En este taller aprenderemos a:

- Iniciar un proyecto de Terraform
- Configurar y descargar el provider para AWS
- Explorar el flujo de trabajo de Terraform

Terraform tiene una sintaxis sencilla basada en _bloques_ y _atributos_ para definir cualquier tipo de infraestructura de varios proveedores.

### Iniciar un proyecto de Terraform

Cualquier carpeta con archivos de configuración (extensiones `.tf` o `.tf.json`) es un proyecto de Terraform. Empezamos creando una carpeta para este proyecto y posicionando la terminal en esa carpeta:

```sh
mkdir 02-intro
cd 02-intro
```

Este directorio es conocido como el **módulo raíz** y es donde colocamos configuraciones de Terraform, proveedores e incluso recursos. No existen nombres de archivos especiales para Terraform pero, por convención, empezamos con un archivo llamado `main.tf`.

```sh
touch main.tf
```

Para configurar la versión de Terraform, utilizamos el bloque [terraform](https://www.terraform.io/docs/language/settings/index.html) de la siguiente forma en `main.tf`:

```tf
terraform {
  required_version = "~> 1.0"
}
```

El atributo `required_version` admite condiciones de tipo [version constraint](https://www.terraform.io/docs/language/expressions/version-constraints.html). Con el valor `~> 1.0`, definimos que esta configuración se puede ejecutar con cualquier versión de Terraform _1.0_ que incremente en el dígito más a la derecha. Es decir, podemos ocupar versiones como _1.0.0_, _1.0.2_ o _1.1.0_, pero no versiones _2.0.0_ o mayor. Las condiciones pueden incluir operadores de tipo `=`, `!=`, `>`, `>=`, `<`, `<=` o `~>` (conocido como _pessimistic constraint operator_).

Con esta configuración mínima, podemos iniciar nuestro proyecto con el comando:

```sh
terraform init
```

<details>
  <summary>Salida</summary>
  
  ```
    Initializing the backend...
    
    Initializing provider plugins...
    
    Terraform has been successfully initialized!
    
    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.
    
    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.
  ```
</details>

Como aún no tenemos _modules_ o _providers_ configurados, la inicialización del proyecto realmente no hace más que la validación de la configuración y la versión de nuestra instalación. No es necesario correr `terraform init` cuando no tenemos configuraciones de módulos, proveedores o recursos.

Existen más atributos que se pueden configurar en el bloque `terraform` que aprenderemos más adelante.

### Configurar y descargar el provider para AWS

Ahora exploraremos los bloques de tipo `provider` para configurar el plugin de AWS. El binario de Terraform no incluye todas las capacidades para comunicarse con las APIs de todos los servicios que soporta (AWS, GCP, Azure, GitHub, etc). En su lugar, ocupa una arquitectura basada en componentes desacoplados y cada configuración descarga los plugins necesarios según necesite.

Agrega el siguiente bloque para configurar el proveedor de AWS en el archivo `main.tf`:

```tf
provider "aws" {
  region = "us-east-1"
}
```

Una vez configurado un bloque `provider`, es necesario ejecutar el comdo de inicialización:

```sh
terraform init
```

<details>
  <summary>Salida</summary>
  
  ```
    Initializing the backend...
    
    Initializing provider plugins...
    - Finding latest version of hashicorp/aws...
    - Installing hashicorp/aws v3.50.0...
    - Installed hashicorp/aws v3.50.0 (signed by HashiCorp)
    
    Terraform has created a lock file .terraform.lock.hcl to record the provider
    selections it made above. Include this file in your version control repository
    so that Terraform can guarantee to make the same selections by default when
    you run "terraform init" in the future.
    
    Terraform has been successfully initialized!
  ```
</details>

Explicación:

1. Agregamos un bloque de tipo `provider` cuya etiqueta es `"aws"`. Esto indica a Terraform que vamos a necesitar que descargue el plugin de AWS
2. Utilizamos el atributo `region` para configurar el proveedor con la región _N. Virginia_. Cada proveedor tiene diferentes atributos, puedes revisar la documentación de cada proveedor en [registry.terraform.io](https://registry.terraform.io/browse/providers).
3. Ejecutamos el comando `terraform init`: 
    - Esto crea el directorio oculto `.terraform`, para almacenar el plugin. Puedes validarlo haciendo un `ls -la`. Este directorio **no** debe ser almacenado en el sistema de control de versiones
    - Crea un archivo oculto `.terraform.lock.hcl` que sirve como [archivo de bloqueo de dependencias](https://www.terraform.io/docs/language/dependency-lock.html). Este archivo **sí** debe ser almacenado en el sistema de control de versiones

#### Administración de versiones de plugins

Terraform nos permite administrar las versiones de los plugins con los que trabajamos, esto nos ayuda a tener mejor control de nuestras configuraciones y evitar errores introducidos por actualizaciones de los plugins. Para establecer la versión del plugin de AWS que queremos ocupar, modificamos el bloque `terraform` en el archivo `main.tf`:

```tf
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.49.0"
    }
  }
}
```

Si intentamos inicializar nuevamente nuestra configuración, obtendremos un error:

```sh
terraform init
```

<details>
  <summary>Error</summary>
  
  ```
    Initializing the backend...
    
    Initializing provider plugins...
    - Reusing previous version of hashicorp/aws from the dependency lock file
    ╷
    │ Error: Failed to query available provider packages
    │ 
    │ Could not retrieve the list of available versions for provider hashicorp/aws: locked provider registry.terraform.io/hashicorp/aws 3.50.0 does not match configured version constraint 3.49.0; must use
    │ terraform init -upgrade to allow selection of new versions
  ```
</details>

Explicación:

1. Usamos el atributo `required_providers` que es un bloque anidado dentro del bloque `terraform`. En este bloque configuramos la versión de `aws` con una cadena como en `required_version`.
2. Al ejecutar `terraform init` obtenemos un error ya que el archivo `.terraform.lock.hcl` guarda información que esta configuración ya fue inicializada con otra versión. Si queremos actualizar la versión del plugin para cumplir con las restricciones impuestas en `required_providers`, debemos hacerlo con:

```sh
terraform init -upgrade
```

##### Ejercicio

Modifica el bloque `terraform` en su atributo `required_providers` para descargar el plugin de AWS en su versión más reciente de `3.x.x` sin actualizar a la versión `4.x.x` (si existiera). Y corre el comando para inicializar y obligar la actualización.

<details>
  <summary>Respuesta</summary>
  
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
```
Y luego ejecutar:
```sh
terraform init -upgrade
```
</details>

#### Utilizar el cache de plugins localmente

Inicializar proyectos puede tomar mucho tiempo ya que Terraform, siempre que lo necesita, descarga el plugin que puede tener un gran tamaño (AWS ~180 MB). Podemos ocupar un directorio local para guardar los plugins y reutilizarlos sin necesidad de descargar constantemente.

Crea un directorio para guardar los plugins y un archivo llamado `.terraformrc` en el directorio HOME para configurar la CLI de Terraform:

```sh
mkdir -p $HOME/.terraform.d/plugin-cache
echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' > ~/.terraformrc
```

En [esta página](https://www.terraform.io/docs/cli/config/config-file.html) puedes consultar todas las configuraciones que se pueden hacer en el archivo `.terraformrc`.

### Explorar el flujo de trabajo de Terraform

#### Escribir, planear y aplicar

Ya que tenemos un directorio y la configuración del _provider_ que vamos a ocupar, podemos empezar a crear recursos en AWS.

Empezamos creando un archivo `resources.tf`:

```sh
touch resources.tf
```

Dentro de ese archivo, escribe un bloque de tipo _resource_ para crear un [bucket de S3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket):

```tf
resource "aws_s3_bucket" "my_bucket" {
  bucket_prefix = "master-class"
  acl           = "private"
}
```

Ahora ejecutamos el siguiente comando:

```sh
terraform plan
```

<details>
  <summary>Salida</summary>
  
  ```
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
      + create
    
    Terraform will perform the following actions:
    
      # aws_s3_bucket.my_bucket will be created
      + resource "aws_s3_bucket" "my_bucket" {
          + acceleration_status         = (known after apply)
          + acl                         = "private"
          + arn                         = (known after apply)
          + bucket                      = (known after apply)
          + bucket_domain_name          = (known after apply)
          + bucket_prefix               = "master-class"
          + bucket_regional_domain_name = (known after apply)
          + force_destroy               = false
          + hosted_zone_id              = (known after apply)
          + id                          = (known after apply)
          + region                      = (known after apply)
          + request_payer               = (known after apply)
          + tags_all                    = (known after apply)
          + website_domain              = (known after apply)
          + website_endpoint            = (known after apply)
    
          + versioning {
              + enabled    = (known after apply)
              + mfa_delete = (known after apply)
            }
        }
    
    Plan: 1 to add, 0 to change, 0 to destroy.
    
    ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    
    Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
  ```
</details>

A continuación creamos nuestro recurso con el comando:

```sh
terraform apply
```

Cuando pide la confirmación:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Escribe la palabra `yes` y da _Enter_ para confirmar la creación del recurso.

<details>
  <summary>Salida</summary>
  
  ```
    aws_s3_bucket.my_bucket: Creating...
    aws_s3_bucket.my_bucket: Creation complete after 1s [id=master-class20210717184348206500000001]
    
    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
  ```
</details>

Explicación:

1. Creamos un archivo de configuración resource.tf con la definición de un recurso S3:
    - El bloque es de tipo `resource`
    - La primera etiqueta `"aws_s3_bucket"` indica que el tipo de recurso es del proveedor "aws"
    - La segunda etiqueta `"my_bucket"` es el **nombre local** del recurso. Este sirve para hacer referencia a este recurso desde otras configuraciones. **No** es el nombre del recurso en la nube de AWS
    - Configuramos los argumentos `bucket_prefix` y `acl` que son propios del tipo de recurso `"aws_s3_bucket"`. Cada recurso tiene sus argumento y atributos. Puedes consultar los recursos del proveedor AWS en [registry.terraform.io](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
2. Utilizamos el comando `terraform plan` para obtener la información de los cambios que Terraform va a hacer en nuestra cuenta de AWS. La salida nos sirve para validar que vamos a crear un nuevo bucket de S3
3. Utilizamos el comando `terraform apply` para aplicar los cambios descritos en nuestros archivos de configuración. Si no pasamos un archivo de plan, este comando corre un `terraform plan` de forma implícita y nos pide nuestra confirmación. Podemos saltar esta confirmación si corremos el comando `terraform apply -auto-approve`
  - Se crea el archivo `terraform.tfstate` del cual hablaremos en otro taller


Valida en tu [consola de S3](https://s3.console.aws.amazon.com/s3/home?region=us-east-1#) que el recurso fue creado correctamente.


#### Modificar y aplicar

Modifica el bloque en el archivo `resources.tf` con lo siguiente:

```tf
resource "aws_s3_bucket" "my_bucket" {
  bucket_prefix = "master-class"
  acl           = "private"

  tags = {
    Team = "Bootcamp"
  }
}
```

Corre el siguiente comando:

```sh
terraform plan -out=out.tfplan
```

<details>
  <summary>Salida</summary>
  
  ```
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
      ~ update in-place
    
    Terraform will perform the following actions:
    
      # aws_s3_bucket.my_bucket will be updated in-place
      ~ resource "aws_s3_bucket" "my_bucket" {
            id                          = "master-class20210717184348206500000001"
          ~ tags                        = {
              + "Team" = "Bootcamp"
            }
          ~ tags_all                    = {
              + "Team" = "Bootcamp"
            }
            # (10 unchanged attributes hidden)
    
            # (1 unchanged block hidden)
        }
    
    Plan: 0 to add, 1 to change, 0 to destroy.
    
    ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    
    Saved the plan to: out.tfplan
    
    To perform exactly these actions, run the following command to apply:
        terraform apply "out.tfplan"
  ```
</details>

Y a continuación aplicamos los cambios:

```sh
terraform apply "out.tfplan"
```

<details>
  <summary>Salida</summary>
  
  ```
    aws_s3_bucket.my_bucket: Modifying... [id=master-class20210717184348206500000001]
    aws_s3_bucket.my_bucket: Modifications complete after 0s [id=master-class20210717184348206500000001]
    
    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
  ```
</details>

Explicación:

1. Modificamos el archivo de configuración para agregar el atributo `tags` a nuestro bucket
2. Ejecutamos el comando `plan` pero en esta ocasión guardamos la salida en un archivo llamado `out.tfplan`
3. Ejecutamos el comando `apply` pasando el nombre del archivo de plan como parámetro. Debido a esto, Terraform no nos pide confirmación para hacer los cambios

#### Destruir

Podemos ocupar Terraform para eliminar recursos de dos formas:

1. Borrar el bloque de configuración y aplicar los cambios
2. Ocupar el comando `destroy` para eliminar todos los recursos manejados por nuestros archivos de configuración

Ocupamos el comando `plan` para hacer una simulación de los recursos que serán eliminados:

```sh
terraform plan -destroy
```

<details>
  <summary>Salida</summary>
  
  ```
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
      - destroy
    
    Terraform will perform the following actions:
    
      # aws_s3_bucket.my_bucket will be destroyed
      - resource "aws_s3_bucket" "my_bucket" {
          - acl                         = "private" -> null
          - arn                         = "arn:aws:s3:::master-class20210717184348206500000001" -> null
          - bucket                      = "master-class20210717184348206500000001" -> null
          - bucket_domain_name          = "master-class20210717184348206500000001.s3.amazonaws.com" -> null
          - bucket_prefix               = "master-class" -> null
          - bucket_regional_domain_name = "master-class20210717184348206500000001.s3.amazonaws.com" -> null
          - force_destroy               = false -> null
          - hosted_zone_id              = "Z3AQBSTGFYJSTF" -> null
          - id                          = "master-class20210717184348206500000001" -> null
          - region                      = "us-east-1" -> null
          - request_payer               = "BucketOwner" -> null
          - tags                        = {
              - "Team" = "Bootcamp"
            } -> null
          - tags_all                    = {
              - "Team" = "Bootcamp"
            } -> null
    
          - versioning {
              - enabled    = false -> null
              - mfa_delete = false -> null
            }
        }
    
    Plan: 0 to add, 0 to change, 1 to destroy.
  ```
</details>

Ejecutamos el siguiente comando:

```sh
terraform destroy
```

Cuando pide la confirmación:

```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: 
```

Escribe la palabra `yes` y da _Enter_ para confirmar la eliminación del recurso.

<details>
  <summary>Salida</summary>
  
  ```
    aws_s3_bucket.my_bucket: Destroying... [id=master-class20210717184348206500000001]
    aws_s3_bucket.my_bucket: Destruction complete after 1s
    
    Destroy complete! Resources: 1 destroyed.
  ```
</details>

Explicación:

1. Utilizamos el comando `plan` para verificar las acciones que realizará el comando `destroy`
2. Ejecutamos el comando `destroy` para eliminar todos los recursos definidos en los archivos de configuración. Este comando es un alias para `terraform apply -destroy`. Nos pide nuestra confirmación pero podemos saltar esta confirmación si corremos con la opción `terraform destroy -auto-approve`. 

Validamos que el recurso se eliminó de nuestra cuenta de AWS.

## Conclusión

En este taller aprendimos a crear un directorio para un proyecto de Terraform con configuraciones para los bloques de `terraform` y `provider`.

También exploramos el ciclo de vida simple para un recurso en AWS: crear, modificar, planear, aplicar y destruir.

### Comandos

- terraform init
  - upgrade
- terraform plan
  - out
  - destroy
- terraform apply
  - "out.tfplan"
  - auto-approve
  - destroy
- destroy
  - auto-approve
