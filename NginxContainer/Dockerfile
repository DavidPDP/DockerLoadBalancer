############################################################
# Dockerfile para construir un balanceador de cargas con Nginx
# Basado en la imagen nginx
############################################################

# Se pasa la imagen base
FROM nginx

# Autor y mantenedor
MAINTAINER Johan David Ballesteros

# Elminar el archivo de configuración por defecto de Nginx
RUN rm -v /etc/nginx/nginx.conf

# Copiar el archivo de configuración desde el directorio actual
ADD nginx.conf /etc/nginx/

# Agregar "daemon off;" en el comienzo de la configuración
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Setear el comando de defecto para ejecutar
# cuando se crea un nuevo contenedor
CMD service nginx start
