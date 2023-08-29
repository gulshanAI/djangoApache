#!bin/bash

echo "Enter the username name"
read username
echo "Enter the project name"
read project
echo "Enter Domain name"
read domain
echo "Enter Root Path"
read rootPath
echo "Enter Main Project Name"
read projectMainName
echo "Enter Env Path"
read envPath


socket="$(cat <<-EOF
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/$project.sock

[Install]
WantedBy=sockets.target
EOF
)"

echo "Creating Socket file"
echo "$socket" > /etc/systemd/system/$project.socket

services="$(cat <<-EOF
[Unit]
Description=gunicorn daemon
Requires=$project.socket
After=network.target

[Service]
User=$username
Group=www-data
WorkingDirectory=$rootPath
ExecStart=$rootPath/$envPath/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/$project.sock \
          $projectMainName.wsgi:application

[Install]
WantedBy=multi-user.target
EOF
)"

echo "Creating Service file"
echo "$services" > /etc/systemd/system/$project.service

sudo systemctl start $project.socket
sudo systemctl enable $project.socket

nginxFile="$(cat <<-EOF
server {
    listen 80;
    server_name $domain;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root $rootPath;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/run/$project.sock;
    }
}
EOF
)"

echo "Creating Nginx File file"
echo "$nginxFile" > /etc/nginx/sites-available/$project

sudo ln -s /etc/nginx/sites-available/$project /etc/nginx/sites-enabled/
sudo nginx -t

sudo systemctl restart nginx
echo "Completed"