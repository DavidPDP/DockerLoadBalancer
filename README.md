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

## Solución
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
