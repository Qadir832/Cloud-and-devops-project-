FROM nginx:alpine

LABEL maintainer="Bilal"
LABEL project="Cloud DevOps Dashboard"

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]