FROM httpd

RUN apt-get update && apt-get install -y ruby && gem install tiller

ADD data/tiller /etc/tiller

CMD ["/usr/local/bin/tiller" , "-v"]
