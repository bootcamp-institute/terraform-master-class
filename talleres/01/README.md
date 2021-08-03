# Instalación y configuración de Terraform

Antes de empezar a escribir archivos de configuración, es necesario instalar y configurar un ambiente local. En este taller aprenderemos a:

- Descargar e instalar Terraform manualmente
- Instalar Terraform ocupando tfenv
- Crear alias para el comando `terraform`

Terraform se distribuye como un archivo binario para varias plataformas (MacOS, FreeBSD, Linux, OpenBSD, Solaris y Windows). Instalar Terraform consiste en descargar el binario, descomprimir y colocarlo en un directorio incluido en el PATH del sistema.

### Descargar e instalar Terraform manualmente

[En esta página](https://www.terraform.io/downloads.html) puedes consultar las plataformas y descargar Terraform para tu sistema operativo. En este manual ocuparemos la terminal para obtener el archivo ZIP.

Primero decidimos la versión que deseamos instalar, en [esta página](https://releases.hashicorp.com/terraform/) puedes revisar las versiones disponibles. Al escribir este taller, la versión más reciente es `1.0.2`, por lo que empezamos estableciendo este valor en una variable de entorno:

```sh
TF_VERSION=1.0.2
```

Y descargamos e instalamos Terraform de la siguiente forma:

```sh
wget -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_$(uname -s)_amd64.zip \
  && unzip /tmp/terraform.zip \
  && sudo mv /tmp/terraform /usr/local/bin
```

Valida que Terraform se encuentra correctamente instalado con el siguiente comando:

```sh
terraform version
```

### Instalar Terraform ocupando tfenv

Instalar Terraform manualmente es útil en ambientes que normalmente no requieren actualizaciones, por ejemplo servidores de CI o imágenes de Docker. Sin embargo, en un ambiente local de desarrollo nos encontramos en situaciones que necesitamos actualizar nuestra versión de Terraform continuamente o incluso necesitamos ocupar diferentes versiones para distintos proyectos.

[tfenv](https://github.com/tfutils/tfenv) es una herramienta que ayuda a instalar y administrar diferentes versiones de Terraform en una sola estación de trabajo y para diferentes proyectos. Instalamos `tfenv` con:

```sh
git clone https://github.com/tfutils/tfenv.git ~/.tfenv \
  && echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc \
  && source ~/.bashrc
```

Si validas la instalación de Terraform con:

```sh
terraform version
```

recibirás el siguiente error: `No versions of terraform installed. Please install one with: tfenv install`. Esto es porque `tfenv` está instalado pero aún no instalamos ninguna versión de Terraform. Ejecuta los siguientes comandos para instalar la última versión y establecerla como nuestra versión por default en nuestra estación de trabajo:

```sh
tfenv install latest \
  && tfenv use latest
```

Valida nuevamente la versión de Terraform, esta vez no deberías recibir error:

```sh
terraform version
```

Con `tfenv` podemos instalar varias versiones de Terraform, empieza listando todas las versiones disponibles con:

```sh
tfenv list-remote
```

Filtremos las versiones `0.15` con el siguiente comando:

```sh
tfenv list-remote | grep 0.15
```

Puedes instalar alguna de estas versiones ocupando el comando `tfenv install ` y pasando la versión exacta en formato `x.x.x`, o puedes instalar la última versión disponible de `0.15` con:

```sh
tfenv install latest:0.15
```

`tfenv` nos permite establecer diferentes versiones por cada proyecto, para probar esta funcionalidad crearemos un directorio de prueba:

```sh
mkdir tfenv-version
cd tfenv-version
```

Si queremos ocupar la última versión disponible de `0.12`, debemos crear un archivo `.terraform-version` con el contenido `latest:^0.12`

```sh
echo "latest:^0.12" > .terraform-version \
  && tfenv install
```

Cada vez que ejecutes un comando de Terraform dentro de este directorio o alguno de sus subdirectorios, utilizará la versión indicada en el archivo `.terraform-version`.

```sh
terraform version
```

Si colaboras en un equipo de trabajo con diferentes bases de código de Terraform y distintas versiones, es buena idea definir la versión en el archivo `.terraform-version` y agregarlo al repositorio de control de versiones.

Puedes listar las versiones instaladas con el siguiente comando:

```sh
tfenv list
```

Recuerda dejar la última versión configurada para el resto de los talleres:


```sh
tfenv use latest
```

Para más información sobre `tfenv` visita su [repositorio en GitHub](https://github.com/tfutils/tfenv).

### Crear alias para el comando terraform

Escribir múltiples veces el comando `terraform` es cansado y propenso a errores. Se recomienda crear un _alias_ para este comando de la siguiente forma:

```sh
echo 'alias tf=terraform' >> ~/.bashrc && source ~/.bashrc
```

De ahora en adelante, en lugar de escribir `terraform`, puedes ocupar el comando `tf`:

```sh
tf version
tf -help
```

El comando `terraform -help` nos muestra los subcomandos disponibles. Si quieres más información sobre un subcomando, puedes ocupar la bandera `-help` después del comando. Por ejemplo:

```sh
terraform init -help
```

## Conclusión

En este laboratorio aprendimos a instalar Terraform de forma manual descargando y descomprimiendo el archivo binario y cómo ocupar `tfenv` para administrar diferentes versiones en un mismo equipo.

### Comandos

- terraform version
- terraform -help
