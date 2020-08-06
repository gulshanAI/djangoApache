#!bin/bash

#sudo apt-get update
echo "Do you have python3-pip apache2 libapache2-mod-wsgi-py3 install [Y,n]"
read input
if [[ $input == "Y" || $input == "y" ]]; then
    sudo apt-get install python3-pip apache2 libapache2-mod-wsgi-py3
fi

echo "Enter the config name"
read confName
echo "Enter Domain name"
read domain
echo "Enter Root Path"
read rootPath
echo "Enter Static Path"
read staticPath
echo "Enter Media Path"
read mediaPath
echo "Enter Project Path"
read projectPath
echo "Enter Env Path"
read envPath

v="$(cat <<-EOF
<VirtualHost *:80>
	ServerAdmin admin@$domain
	ServerName $domain
	ServerAlias www.$domain
	DocumentRoot $rootPath
	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined

	Alias /static $rootPath/$staticPath
	<Directory $rootPath/$staticPath>
		Require all granted
	</Directory>

	Alias /static $rootPath/$mediaPath
	<Directory $rootPath/$mediaPath>
		Require all granted
	</Directory>

	<Directory $rootPath/$projectPath>
		<Files wsgi.py>
			Require all granted
		</Files>
	</Directory>

	WSGIDaemonProcess $projectPath python-path=$rootPath python-home=$rootPath/$envPath
	WSGIProcessGroup $projectPath

	WSGIScriptAlias / $rootPath/$projectPath/wsgi.py
</VirtualHost>
EOF
)"
echo "Creating conf file"
echo "$v" > /etc/apache2/sites-available/$confName.conf

echo "Adding Domain"
printf "\n127.0.0.1       $domain" >> /etc/hosts

echo "Changing File permission"
sudo chmod 664 $rootPath/db.sqlite3
sudo chown :www-data $rootPath/db.sqlite3
sudo chown :www-data $rootPath

echo "Enabling Site"
cd /etc/apache2/sites-available/
sudo a2ensite $confName.conf
sudo ufw allow 'Apache Full'
sudo apache2ctl configtest 

echo "Apache Restarting"
sudo service apache2 restart