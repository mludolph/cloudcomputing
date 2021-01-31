FROM nginx:latest
# Start from the nginx latest image

# Add the frontend.nginx.conf file
COPY frontend.nginx.conf /etc/nginx/conf.d/default.conf
