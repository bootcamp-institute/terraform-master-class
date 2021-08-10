# Creando una VPC con el registro público de módulos

En [registry.terraform.io](https://registry.terraform.io/browse/modules) se encuentra el registro público de módulos, donde podemos encontrar diferentes soluciones para varios proveedores con los casos de uso más comunes.

En este taller aprenderemos a:

- Utilizar el módulo de VPC de AWS

### Utilizar el módulo de VPC de AWS

Utilizamos el directorio `infra` para continuar con este ejercicio.

#### Instrucciones

1. Elimina el contenido del archivo `resources.tf`

2. Utiliza el _data source_ [aws_availability_zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) para obtener las Zonas de Disponibilidad de la región que estamos ocupando

3. Ocupamos el módulo [VPC](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) para definir una nueva VPC:

```tf
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "MyVPC"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available[*].name
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}
```

4. Crea un nuevo bloque `variable` en `modules/server/variables.tf` para recibir el parámetro `subnet_id`

5. Actualiza el bloque de servidor en `modules/server/server.tf` con el argumento `subnet_id` para utilizar el valor de la variable declarada en el paso anterior

6. En el archivo `resources.tf` crea un nuevo bloque ocupando nuestro módulo `./modules/server` y pasando los valores necesarios

7. Inicializa, planea y crea la infraestructura con Terraform

8. Valida la creación de la VPC, Security Group y servidor en EC2

## Limpieza

Ejecuta el comando `destroy` para eliminar la infraestructura

## Conclusión

En este taller aprendimos a ocupar un recurso del registro público de módulos de Terraform y cómo unir diferentes módulos a través de sus datos
