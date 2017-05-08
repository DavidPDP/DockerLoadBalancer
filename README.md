# DockerLoadBalancer
<b>Autor:</b> Johan David Ballesteros <br>
<b>Código:</b>A00309824 <br>
<b>Repositorio:</b> https://github.com/DavidPDP/DockerLoadBalancer

## Problema 
Se debe automatizar el despliegue de una infraestructura que posea unos contenedores web y un contenedor que se encargue del balanceo de cargas. Esto se puede observar en el siguiente diagrama de deployment:


## Objetivos 
* Realizar de forma autónoma el aprovisionamiento automático de infraestructura.
* Diagnosticar y ejecutar de forma autónoma las acciones necesarias para lograr infraestructuras estables.
* Integrar servicios ejecutandose en nodos distintos.

## Prerrequisitos
* Docker

## Pasos Para Automatizar
Para el despliegue de la infraestrcutura se necesita automatizar las siguientes acciones:

### Servidores Web
Para despliegar un servidor web de apache se necesita instalar apache:

```bash
sudo apt-get update
sudo apt-get install apache2
```
Después de instalarlo se inicia el servicio

```bash
sudo service apache2 start
```
### Balanceador De Carga
Para despliegar el balanceador de carga se necesita instalar nginx:

```bash
sudo apt-get update
sudo apt-get install Nginx
```
Después proceder a configurar Nginx como balanceador desde el archivo nginx.conf que se encuentra en la ruta /etc/nginx/ como el ejemplo que se encuentra a continuación:

```bash
http {
    upstream myapp1 {
        server srv1.example.com;
        server srv2.example.com;
        server srv3.example.com;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://myapp1;
        }
    }
}
```
Finalmente, iniciar el servicio de Nginx

```bash
service nginx start
```
### Levantar Contenedor
Para levantar un solo contenedor se debe proceder a indicarle que se ejecute en modo detached, realizar el mapeo de puertos y asignarle un volumen al contenedor como se puede observar en el siguiente comando:

```bash
docker run -d -p 80:80 -v /webapp my_image
```
## Automatizado
Para automatizar todo el despliegue de la infraestructura propuesta teniendo en cuenta los pasos a automatizar se procedió a las siguientes acciones:

### Vista General De La Estructura Del Proyecto
A continuación se presenta la vista general de la estructura del proyecto:

### Servidor Web
Para crear los 3 servidores web se procedió a eligir httpd para esto se descargó desde DockerHub la imagen con el siguiente comando:

```bash
docker pull httpd
```
<p align=justify> Surge un problema con Docker y es la parametrización de los archivos en el tiempo de ejecución del contenedor. Esto se debe a que en tiempo de construcción se invierte un tiempo considerable para crear la imagen, si este tiempo es empleado para paremetrizar los contenedores, pues habrá un desperdicio de recursos debido a que cada vez que se quiera cambiar la parametrización se deberá construir la imagen (teniendo en cuenta que en la construcción de la imagen se instala los sistemas robustos del contenedor). Un ejemplo de esto se puede observar si queremos que los contenedores desplegados accedan a una base de datos o a diferentes servicios REST. <br> Es por lo anterior que el momento optimo para realizar la parametrización es cuando se va a ejecutar un contenedor (Docker run time), además sería lo más conveniente puesto que si se quiere ejecutar múltiples contenedores cada uno tiene la posibilidad de llevar una parametrización diferente. A este problema se le añade que Docker no ofrece esta funcionalidad por lo que se tiene que recurrir a herramientas externas que permitan realizarlo. En este caso se seleccionó Confd, la cual es una herramienta de gestión de la configuración de peso ligero. (Más adelante se explicará los problemas por los que se seleccionó esta herramienta y no otra).
</p>

### Condiguración de Confd
<p align=justify> Para realizar la configuración de Confd se debe proceder primero a realizar su instalación. Para esto se utilizará la imagen base (httpd) descargada con el comando mencionado anteriormente. A continuación se muestra el Dockerfile empleado para configurar Confd.</p>

<a href="https://github.com/DavidPDP/DockerLoadBalancer/blob/master/ApacheContainer/Confd/Dockerfile"><b>DockerFile servidor web con Confd</b></a>


