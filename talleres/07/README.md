# Creando configuraciones reutilizables con módulos

Los módulos en Terraform sirven para encapsular y reutilizar configuraciones de forma sencilla. Los módulos pueden ser locales o remotos y utilizamos bloques de tipo [module](https://www.terraform.io/docs/language/modules/syntax.html) para crear diferentes instancias de una definición.

En este taller aprenderemos:

- Crear un módulo local
- Pasar y obtener información de un módulo

### Crear un módulo local

Creamos la siguiente estructura de directorios y archivos:

```
.
└── infra
    ├── main.tf
    ├── resources.tf
    └── modules
        └── server
            ├── outputs.tf
            ├── security-group.tf
            ├── server.tf
            └── variables.tf
```

```sh
mkdir -p infra/modules/server
cd infra
touch main.tf resources.tf
cd modules/server
touch outputs.tf security-group.tf server.tf variables.tf
cd ../../
```

#### Instrucciones

1. En el archivo `main.tf` coloca la configuración de `terraform` y `provider` que hemos ocupado hasta ahora. Configura el _backend_ de tipo S3 con el argumento `key` igual a `infra/terraform.tfstate`

2. En el archivo `modules/server/server.tf` crea un bloque de tipo [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) para crear un servidor EC2 con los siguientes argumentos:

| Argumento     | Valor                 |
| ------------- | --------------------- |
| ami           | ami-0dc2d3e4c0f9ebd18 |
| instance_type | t3.micro              |
| tags.Name     | Modules lab           |

3. En el archivo `modules/server/outputs.tf` crea un bloque de tipo `output` con nombre local `ip_address` que exponga el atributo `public_ip` del servidor EC2

4. En el archivo `resources.tf` crea un bloque `module` de la siguiente forma:

```tf
module "web_server" {
  source = "./modules/server"
}
```

5. Da formato a los archivos de forma recursiva con `terraform fmt -recursive`

6. Inicializa la configuración de Terraform, planea y aplica los cambios

### Pasar y obtener información de un módulo

Para que un módulo sea completamente reutilizable, debemos parametrizar los argumentos que permiten que nuestros recursos se adapten a diferentes casos de uso. Esto lo hacemos a través de bloques `variable` cuyos valores son enviados por el módulo padre a través de argumentos.

#### Instrucciones

1. En el archivo `resources.tf` crea un bloque de tipo [aws_default_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_vpc) sin ningún argumento

2. En el archivo `modules/server/variables.tf` crea un bloque de tipo `variable` con nombre local `vpc_id` con los siguientes argumentos:

| Argumento   | Valor                         |
| ----------- | ----------------------------- |
| type        | string                        |
| description | VPC id for the security group |

2. En el archivo `modules/server/security-group.tf` crea un recurso de tipo [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)

| Argumento      | Valor                                     |
| -------------- | ----------------------------------------- |
| vpc_id         | _Valor de variable vpc_id_                |
| Bloque ingress | _Permitir tráfico a través del puerto 80_ |

3. En el archivo `modules/server/server.tf` modifica el recurso `aws_instance` para hacer uso del ID del security group en el argumento [vpc_security_group_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#vpc_security_group_ids)

4. En el archivo `resources.tf` Crea un bloque `output` cuyo valor sea `module.<nombre_local>.ip_address`

5. Planea y aplica los cambios con Terraform.

6. Valida en la consola de EC2 la creación del servidor y security group

7. Valida que obtienes la IP pública del servidor en la salida de la CLI

##### Ejercicio

1. En el archivo `modules/server/variables.tf` crea variables para parametrizar los siguientes argumentos del servidor EC2. Coloca los valores actuales como valores por _default_ de las variables:

- ami
- instance_type
- name

2. Actualiza el archivo `modules/server/server.tf` para hacer uso de estas nuevas variables

3. En el archivo `resources.tf`, actualiza el bloque `module` existente para pasar valores a las nuevas variables

4. Crea un nuevo bloque `module` con valores diferentes al primer bloque

5. Aplica los cambios con Terraform y valida que existan 2 servidores con diferentes características

## Limpieza

Ejecuta el comando `destroy` para eliminar la infraestructura creada por nuestros módulos.

## Conclusión

En este taller aprendimos a crear un módulo de forma local y cómo parametrizarlo para levantar diferentes instancias con valores diferentes.

### Comandos

- fmt
  - recursive
