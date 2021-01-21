FROM nginx:latest
# Start from the nginx latest image

# Add the backend.nginx.conf file
COPY backend.nginx.conf /etc/nginx/conf.d/default.conf
