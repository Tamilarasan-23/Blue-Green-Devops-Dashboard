FROM nginx:latest

ARG BUILD_TIME

COPY . /usr/share/nginx/html/

RUN sed -i "s/BUILD_TIME/$BUILD_TIME/g" /usr/share/nginx/html/*.html
