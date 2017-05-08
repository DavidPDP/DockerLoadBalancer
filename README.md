# DockerLoadBalancer
<b>Autor:</b> Johan David Ballesteros <br>
<b>Código:</b>A00309824 <br>
<b>Repositorio:</b> https://github.com/DavidPDP/DockerLoadBalancer

## Problema 
Se debe automatizar el despliegue de una infraestructura que posea unos contenedores web y un contenedor que se encargue del balanceo de cargas. Esto se puede observar en el siguiente diagrama de deployment:

![alt text](Images/diagrama_despliegue.png)

## Objetivos 
* Realizar de forma autónoma el aprovisionamiento automático de infraestructura.
* Diagnosticar y ejecutar de forma autónoma las acciones necesarias para lograr infraestructuras estables.
* Integrar servicios ejecutandose en nodos distintos.

## Prerrequisitos
* Docker

## Pasos Para Automatizar
Para el despliegue de la infraestructura se necesita automatizar las siguientes acciones:

### Servidores Web
Para desplegar un servidor web de apache se necesita instalar apache:

```bash
sudo apt-get update
sudo apt-get install apache2
```
Después de instalarlo se inicia el servicio

```bash
sudo service apache2 start
```
### Balanceador De Carga
Para desplegar el balanceador de carga se necesita instalar nginx:

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

![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/tree)

### Servidor Web
Para crear los 3 servidores web se procedió a elegir httpd para esto se descargó desde DockerHub la imagen con el siguiente comando:

```bash
docker pull httpd
```
<p align=justify> Surge un problema con Docker y es la parametrización de los archivos en el tiempo de ejecución del contenedor. Esto se debe a que en tiempo de construcción se invierte un tiempo considerable para crear la imagen, si este tiempo es empleado para paremetrizar los contenedores, pues habrá un desperdicio de recursos debido a que cada vez que se quiera cambiar la parametrización se deberá construir la imagen (teniendo en cuenta que en la construcción de la imagen se instala los sistemas robustos del contenedor). Un ejemplo de esto se puede observar si queremos que los contenedores desplegados accedan a una base de datos o a diferentes servicios REST. <br>
Es por lo anterior que el momento óptimo para realizar la parametrización es cuando se va a ejecutar un contenedor (Docker run time), además sería lo más conveniente puesto que si se quiere ejecutar múltiples contenedores cada uno tiene la posibilidad de llevar una parametrización diferente. A este problema se le añade que Docker no ofrece esta funcionalidad por lo que se tiene que recurrir a herramientas externas que permitan realizarlo. En este caso se seleccionó Confd, la cual es una herramienta de gestión de la configuración de peso ligero. (Más adelante se explicará los problemas por los que se seleccionó esta herramienta y no otra).

</p>

### Condiguración de Confd
<p align=justify> Para realizar la configuración de Confd se debe proceder primero a realizar su instalación. Para esto se utilizará la imagen base (httpd) descargada con el comando mencionado anteriormente. A continuación se muestra el Dockerfile empleado para configurar Confd.</p>

<a href="https://github.com/DavidPDP/DockerLoadBalancer/blob/master/ApacheContainer/Confd/Dockerfile"><b>DockerFile servidor web con Confd</b></a>

<p align=justify> En el Dockerfile podemos observar cuatro instrucciones fundamentales. La primera la instalación de Confd y ubicación en la carpeta /usr/local/bin/confd. La segunda es el copiado que se realiza sobre un archivo .sh, que se encarga de mostrar todas las variables del entorno, de definir las variables a parametrizar, de probarlas y finalmente de iniciar el servicio del servidor web. La tercera la de asignación de permisos y finalmente el comando de ejecución del contenedor el cual se encarga de ejecutar el archivo sh. A continuación se puede ver en más detalle este archivo</p>

<a href="https://github.com/DavidPDP/DockerLoadBalancer/blob/master/ApacheContainer/Confd/files/start.sh"><b>start.sh</b></a>

Por último se procede a definir en los archivos que se quieren parametrizar la siguiente estructura.
1) Los archivos que vayan a contener las variables deben tener extensión .tmpl, por organización se almacenan en una carpeta llamada templates.
2) Para definir una variable dentro del archivo se debe definir con el siguiente formato.
```bash
{{ getenv "[NameVariable]" }} // Nota los corchetes solo son delimitadores para el ejemplo se deben obviar al momento de establecer la variable.
```
3) Finalmente se debe crear un archivo con la extensión .toml donde se le especifica a la herramienta donde se encuentra el archivo templates y donde se almacenarán dentro del contenedor.

Con lo anterior se finaliza la configuración y preparación de la herramienta Confd y de los archivos con las variables definidas para la parametrización que se realizará en Docker run time.

### Balanceador De Cargas
Para el balanceador de cargas se hizo uso de Nginx, un servidor HTTP el cual puede ser configurado para realizar esta funcionalidad. Para esto se descargó la imagen de nginx con el siguiente comando:

```bash
docker pull nginx
```
<p align=justify> Debido a que la imagen ya contiene el nginx previamente instalado entonces los únicos pasos a realizar sería la configuración del mismo como balanceador de cargas. A continuación se muestra la el archivo de configuración del nginx:</p>

<a href="https://github.com/DavidPDP/DockerLoadBalancer/blob/master/NginxContainer/nginx.conf"><b>nginx.conf</b></a>

En este archivo se definen los servidores a los cuales el balanceador puede redireccionar las peticiones y configura el Nginx para que pueda recibir conexiones remotas.Finalmente se crea el Dockerfile teniendo la imagen base (nginx) descargada anteriormente y se procede a cambiar el archivo de configuración por defecto de Nginx por el nuevo que configura al Nginx como balanceador de cargas. También se agrega al archivo de configuración el comando <b>daemon off</b> que permita que el Nginx se ejecute en foreground y no se detenga.

<a href="https://github.com/DavidPDP/DockerLoadBalancer/blob/master/NginxContainer/Dockerfile"><b>Dockerfile Nginx</b></a>

### Automatización Infraestructura
Una vez realizado todos los pasos anteriores ya se puede automatizar el despliegue de la infraestructura deseada. El primer problema que se encuentra aquí es el despliegue por comando de cada contenedor. Como podemos ver a continuación se debería realizar los siguientes comandos cada vez que se quisiera levantar la infraestructura deseada:

```docker
docker run -d -p 5000:80 -e server_number="1" apache_confd
docker run -d -p 5000:80 -e server_number="2" apache_confd
docker run -d -p 5000:80 -e server_number="3" apache_confd
docker run -d -p 8080:80  dockerloadbalancer_proxy
```
A esto añadiéndole la creación de los volúmenes, asignación misma a los comandos y la escalabilidad del sistema.

Para solucionar esto se procede a crear el compose que nos permitirá el despliegue de cada uno de los contenedores, además que permite asignarle las variables del entorno que se setearan dentro de los archivos por medio de la herramienta Confd.

<a href="https://github.com/DavidPDP/DockerLoadBalancer/blob/master/docker-compose.yml"><b>docker-compose.yml</b></a>

Para ejecutar el docker compose se sigue procede a ejecutar los siguientes comandos:

```docker
docker-compose build --no-cache
docker-compose up
```

### Gestión de Volúmenes
<p align=justify> Para la gestión de los volúmenes de los contenedores se procedió a definir que los contenedores web compartirán un mismo volumen para el almacenamiento de datos o de archivos que sean relevantes como los de configuración, mientras que el contenedor del balanceador se le asignó un volumen diferente para agregar un poco de seguridad. La creación de los volúmenes se encuentra en la misma definición del archivo docker-compose.yml y se definen como se sigue:</p>

```docker
volumes:
    [NameVolume]:
//Dentro de la declaración de los contenedores
volumes:
      - [NameVolume]:[Path]
```
### Resultados 
A continuación se muestran los pantallazos del funcionamiento de la solución y de aspectos relevantes:

Docker images:
![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/screen1.png)


Docker volumes:
![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/screen2.png)


Ejecución Docker-compose:
![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/screen3.png)


Redireccionamiento Server 1:
![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/screen4.png)


Redireccionamiento Server 3:
![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/screen5.png)


Redireccionamiento Server 2:
![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/screen6.png)


Peticiones Recibidas Por El Balanceador:
![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/screen7.png)

Comprobación De Asignación De Volúmenes:
![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/screen8.png)

![alt text](https://github.com/DavidPDP/DockerLoadBalancer/blob/master/Images/screen9.png)

## Inconvenientes
A lo largo del desarrollo de esta solución se encontraron diferentes problemas:
* <p align=justify> Docker Run Time Vs Docker Build Time: Este fue el primer problema encontrado debido a que docker no tiene una herramienta o servicio que permita parametrizar fácilmente los archivos dentro de los contenedores que se desplieguen. Para esto se encuentra la decisión de donde realizar la parametrización. Inicialmente se pensó en realizarlo en el Build Time pues es una infraestructura pequeña, pero se comprobó que esta es la etapa más demorada, pues aquí se procede a descargar una cantidad innumerable de sistemas que tendrá el contenedor. Por lo tanto, quedó descargada esta opción pues al momento donde se necesite escalar el sistema haría una pérdida significativa de recursos. Es por lo anterior que se eligió que cuando se va a desplegar el contenedor es el momento más conveniente para parametrizarlo.</p>
* <p align=justify> Tiller vs Confd: Inicialmente se investigó la herramienta Tiller para realizar el acondicionamiento de los archivos para que fueran parametrizables. Pero esta herramienta tiene muy poca documentación y se procedió a realizar tutoriales expuestos en la web los cuales no funcionaron, aun cuando se copió el tutorial. Por lo tanto, para ahorrar tiempo se procedió a una herramienta que ya se había probado su funcionamiento llamada Confd, la cual tiene una documentación decente con tutoriales en la web.</p>
* <p align=justify> Volúmenes: El principal inconveniente con los volúmenes fue la adecuación de esto dentro del docker-compose, debido a que solo se tenía el conocimiento de crearlos individualmente y asignarlos a los contenedores, pero para una automatización de infraestructura esto no es mantenible ni escalable. Por lo cual se tuvo que proceder a investigar cómo se creaban volúmenes y se asignaban dentro del mismo docker-compose. Finalmente se pudo lograr.</p>
* <p align=justify> Binding Puertos Contenedor Con El Host: Este fue uno de los problemas más grandes dentro de la solución debido a que no se tenía el entendimiento suficiente de la opción -p dentro del comando del docker run. Finalmente, se entendió que la opción -p permite realizar el binding de puertos del contenedor con el host.</p>
