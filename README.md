# Terraform Master Class

Este repositorio contiene los talleres para el Master Class de Terraform de Bootcamp Institute.

Los talleres crean recursos en AWS, en su mayoría dentro de la capa gratuita. Pero es importante **borrar todos los recursos** al terminar cada taller para no incurrir en gastos innecesarios.


## Instrucciones

Empieza creando un ambiente de Cloud9:

1. Ingresa a tu cuenta de AWS y verifica que te encuentras en la región **N. Virginia** (us-east-1).
2. Ve al servicio [Cloud9](https://console.aws.amazon.com/cloud9/home/product)
3. Click en el botón `Create environment` para empezar la creación de un nuevo IDE
4. En `Name` llenar con `Terraform Master Class`. Click en `Next step`
5. En la página de configuración de ambiente, dejar todas las opciones con sus valores por default. Click en `Next step`
6. En la página de revisión, click en `Create environment`.

Una vez creado el IDE Cloud9, clonar este repositorio:

```sh
git clone https://github.com/eloyvega/bootcamp-terraform-masterclass.git
```

Sigue las instrucciones de cada taller

## Talleres

1. [Instalación y configuración de Terraform](./talleres/01)
2. [AWS y Terraform: Ciclo de vida de un recurso en la nube](./talleres/02)
3. [Creando configuraciones de recursos dependientes](./talleres/03)
4. [Usando variables y data sources para hacer configuraciones dinámicas](./talleres/04)
5. [Administración de estado en AWS](./talleres/05)
6. [Ambientes con workspaces](./talleres/06)
7. [Creando configuraciones reutilizables con módulos](./talleres/07)
8. [Creando una VPC con el registro público de módulos](./talleres/08)
9. [Importando recursos de AWS](./talleres/09)
10. [Bootstrap de instancias con información dinámica](./talleres/10)
11. [Creación repetida de recursos](./talleres/11)
12. [Introducción a Terraform Cloud](./talleres/12)
