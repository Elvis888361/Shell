# Shell
Automatic Creation of frappe and erpnext using shell
Software Requirements
Updated Ubuntu 22.04
Start by updating and upgrading your system
sudo apt-get update -y 
sudo apt-get upgrade -y
Create a new user dont forget to name your frappe-user
sudo adduser [frappe-user] 
Sudo usermod -aG sudo [frappe-user] 
Sudo su [frappe-user] 
cd /home/[frappe-user]

Install git
sudo apt-get install git

Install Python
sudo apt-get install python3-dev python3.10-dev python3-setuptools python3-pip python3-distutils

Install Python Virtual Environment
sudo apt-get install python3.10-venv

Install Software Properties Common
sudo apt-get install software-properties-common

Install MariaDB
sudo apt install mariadb-server mariadb-client

Install Redis Server
sudo apt-get install redis-server

Install other packages
sudo apt-get install xvfb libfontconfig wkhtmltopdf 
sudo apt-get install libmysqlclient-dev

Setup the server
sudo mysql_secure_installation
When you run the above code youll needbe displayed the following queries youll answer as per below:
Enter current password for root: (Enter your user password the one you use in your root sudo)
Switch to unix_socket authentication [Y/n]: Y
Change the root password? [Y/n]: Y
Remove anonymous users? [Y/n] Y
Disallow root login remotely? [Y/n]: N
Remove test database and access to it? [Y/n]: Y
Reload privilege tables now? [Y/n]: Y

Edit MYSQL default config file
sudo nano /etc/mysql/my.cnf

youll scroll down the nano that has appeared then add the following youll copy paste it 

[mysqld] 
character-set-client-handshake = FALSE 
character-set-server = utf8mb4 
collation-server = utf8mb4_unicode_ci 
[mysql] 
default-character-set = utf8mb4

Restart the MYSQL Server
sudo service mysql restart
Install CURL
sudo apt install curl

Install Node copy one by one hear
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 
source ~/.profile 
nvm install 16.15.0

Install NPM
sudo apt-get install npm

Install Yarn
sudo npm install -g yarn

Install Frappe Bench
sudo pip3 install frappe-bench

Initialize Frappe Bench hear change the version according to what you need if version 14 change it from 13 to 14 hearit will work
bench init --frappe-branch version-13 frappe-bench-name
Switch directories into the Frappe Bench directory
cd frappe-bench-name
Change user directory permissions
Sudo chmod -R o+rx /home/[frappe-user]
Create a New Site
bench new-site [site-name]
Create a New App
bench new-app [app-name]


Install ERPNext hear change the version according to what you need if version 14 change it from 13 to 14 hearit will work
bench get-app --branch version-13 erpnext

Install all the apps on our site
bench --site [site-name] install-app erpnext
Running the bench 
bench start

Setting ERPNext for Production
Enable Scheduler
bench --site [site-name] enable-scheduler
Disable maintenance mode
bench --site [site-name] set-maintenance-mode off
Setup production config
sudo bench setup production [frappe-user]
Setup NGINX to apply the changes
bench setup nginx
Restart Supervisor and Launch Production Mode
sudo supervisorctl restart all
sudo bench setup production [frappe-user]
