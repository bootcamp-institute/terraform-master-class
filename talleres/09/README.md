# Importando recursos de AWS

Terraform es capaz de importar infraestrutura existente. Esto permite tomar recursos que has creado por otros medios y ponerlos bajo la administración de Terraform. Esta es una excelente manera de realizar una transición lenta de la infraestructura hacia Terraform.

En este taller aprenderemos a:

- Importar recursos existentes a Terraform

### Importar recursos existentes a Terraform

Para importar recursos a Terraform seguimos 5 pasos:

1. Identificar el recurso que se va a importar
2. Importar la infraestructura al estado de Terraform
3. Escribir configuración de Terraform para emparejar con la infraestructura
4. Revisar el plan de Terraform para asegurar que la configuración concuerda con el estado deseado y la infraestructura
5. Aplicar la configuración para actualizar el estado de Terraform

#### Instrucciones

1. Instala la herramienta `jq` con el siguiente comando:

```sh
sudo yum update -y && sudo yum install -y jq
```

2. Ejecuta el siguiente comando para crear una instancia de EC2, el ID de la instancia será guardado en la variable `INSTANCE_ID`:

```sh
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "ami-0dc2d3e4c0f9ebd18" \
    --instance-type "t3.micro" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Created_Manually}]" \
    | jq -r '.Instances[0].InstanceId')
```

3. Valida que el servidor fue creado en la consola de EC2

4. Crea la carpeta `09-import` con los archivos `main.tf` y `resources.tf` para almacenar la configuración de Terraform

5. En el archivo `main.tf` coloca la configuración de `terraform` y `provider` que hemos ocupado hasta ahora. Configura el _backend_ de tipo S3 con el argumento `key` igual a `09/import/terraform.tfstate`

6. En el archivo `resources.tf` escribe un bloque vacío para el servidor:

```tf
resource "aws_instance" "server" {}
```

7. Inicializa la configuración de Terraform

8. Ejecuta el siguiente comando para importar la definición del servidor al archivo de estado de Terraform:

```sh
terraform import aws_instance.server $INSTANCE_ID
```

9. Valida que el servidor se encuentra en el archivo de estado con el comando

```sh
terraform state list
```

10. Ejecuta el siguiente comando:

```sh
terraform state show aws_instance.server
```

y copia los siguientes atributos al recurso definido en `resources.tf`:

- ami
- instance_type
- tags

11. Ejecuta el comando `plan` para validar que el recurso ya se encuentra correctamente configurado

12. Cambia el valor del argumento `tags.Name` a `"Managed by Terraform"` y aplica los cambios

13. Valida que el servidor ya se encuentra administrado por Terraform y el nombre del servidor cambió en la consola de EC2

## Ejercicio

Crea un bucket de S3 manualmente y sigue el proceso para importarlo a la configuración de Terraform

## Conclusión

En este taller aprendimos a importar a Terraform recursos creados a través de otros medios. Terraform aún no es capaz de escribir la configuración del recurso, solo puede importar hacia el archivo de estado y nosotros somos responsables de terminar de escribir la configuración.

### Comandos

- import
