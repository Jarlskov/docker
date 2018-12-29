FROM nginx
RUN rm /etc/nginx/conf.d/default.conf
RUN sed -i -e "s/worker_processes  1;/worker_processes auto;/" /etc/nginx/nginx.conf
RUN sed -i -e "s/worker_connections  1024;/worker_connections 2048;/" /etc/nginx/nginx.conf

RUN echo "worker_rlimit_nofile 20000;" >> /etc/nginx/nginx.conf

# copy content
COPY ./ /var/www/html/
COPY ./docker/nginx/conf.d/ /etc/nginx/conf.d/

