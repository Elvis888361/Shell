##################################################################
# 1 - GET USER SPECIFICS FROM THE USER
##################################################################

FRAPPE_PWD=''
SITE_PWD=''
MYSQL_PASS=''
SITE_URL=''

echo 'Enter Bench User Name'
read FRAPPE_PWD

echo 'Enter your preferred Administrator login password'
read SITE_PWD

echo 'Enter your preferred MySQL root password'
read MYSQL_PASS

echo 'Enter your site URL'
read SITE_URL



##################################################################
# 2 - SETTING UP DEFAULT SETTINGS
##################################################################
TIMEZONE='Africa/Nairobi'
FRAPPE_USR='frappe'
FRAPPE_BRANCH='version-14'
ERPNEXT_BRANCH='version-14'

SRVR_ADDR=`curl -s -4 ifconfig.co`
SITE_ADDR=`dig +short $SITE_URL`
SERVER_OS=`/usr/bin/lsb_release -ds| awk '{print $1}'`
SERVER_VER=`/usr/bin/lsb_release -ds| awk '{print $2}' | cut -d. -f1,2`



##################################################################
# 3 - CHECK NECESSARY CONFIGURATION BEFORE STARTING INSTALL
##################################################################

# Check if user is root. Exit if not.
[[ $EUID -ne 0 ]] && echo -e "\033[0;31m \n>\n> Error: You MUST be root user to run this script! \n>\n\033[0m" && exit 1


# Check if the installed OS is ubuntu 20.14. Exit if not
[[ $SERVER_OS != 'Ubuntu' || $SERVER_VER != '22.04' ]] && echo -e "\033[0;31m \n>\n> Error: This script is made for Ubuntu 22.04 \n>\n\033[0m" && exit 1


# Check if user has defined bench user password. Exit if not
[[ $FRAPPE_PWD == '' ]] && echo -e "\033[0;31m \n>\n> Error: Please provide preferred bench user password \n>\n\033[0m" && exit 1


# Check if frappe administrator password is set. Exit if not
[[ $SITE_PWD == '' ]] && echo -e "\033[0;31m \n>\n> Error: Please provide preferred administrator login password \n>\n\033[0m" && exit 1


# Check if MySQL root password is set. Exit if not
[[ $MYSQL_PASS == '' ]] && echo -e "\033[0;31m \n>\n> Error: Please provide preferred MySQL root password \n>\n\033[0m" && exit 1



##################################################################
# 4 - UPDATE THE SYSTEM
##################################################################
echo -e "\033[0;33m \n>\n> Updating system packages \n>\n\033[0m"
apt -y update
apt -y -o DPkg::options::="--force-confdef" upgrade


##################################################################
# 5 - UPDATE SERVER TIME ZONE
##################################################################
echo -e "\033[0;33m \n>\n> Setting timezone to ${TIMEZONE}... \n>\n\033[0m"
timedatectl set-timezone ${TIMEZONE}
timedatectl


##################################################################
# 6 - INSTALL REQUIRED TOOLS
##################################################################
echo -e "\033[0;33m \n>\n> Installing requirements \n>\n\033[0m"
apt -y install python3-dev python3.10-dev python3-setuptools python3-pip python3-distutils
apt -y install git
apt -y install python3.10-venv
apt -y install software-properties-common
apt -y apt-get install xvfb libfontconfig wkhtmltopdf
apt -y install libmysqlclient-dev

##################################################################
# 7 - MAKE ALIAS FOR PYTHON AND PIP
##################################################################
alias python=python3
alias pip=pip3


##################################################################
# 8 - UPGRADE PIP
##################################################################
echo -e "\033[0;33m \n>\n> Upgrading python packages \n>\n\033[0m"
pip install --upgrade ansible pip


##################################################################
# 9 - INSTALLING NODEJS, REDIS AND YARN
##################################################################
echo -e "\033[0;33m \n>\n> Installing nodejs, redis, yarn \n>\n\033[0m"
curl --silent --location https://deb.nodesource.com/setup_14.x | sudo -E bash -
apt-get remove libnode-dev
apt-get remove libnode72
apt -y install gcc g++ make nodejs redis-server
npm install -g yarn
yarn install

##################################################################
# 10 - START THE REDIS SERVER
##################################################################
echo -e "\033[0;33m \n>\n> Starting redis-server \n>\n\033[0m"
systemctl start redis-server
systemctl enable redis-server


##################################################################
# 11 - INSTALL NGINX AND MARIADB
##################################################################
echo -e "\033[0;33m \n>\n> Installing nginx and mariadb \n>\n\033[0m"
apt -y install nginx
apt -y install mariadb-server mariadb-client libmysqlclient-dev


##################################################################
# 12 - CHANGE DATABASE CONFIGURATIONS TO SUIT ERPNEXT AND FRAPPE
##################################################################
sed -i 's/\[mysqld\]/[mysqld]\ncharacter-set-client-handshake = FALSE/' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i 's/\[mysql\]/[mysql]\ndefault-character-set = utf8mb4/' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i 's/utf8mb4_general_ci/utf8mb4_unicode_ci/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mysqld


##################################################################
# 13 - SECURING OUR DATABASE
##################################################################
echo -e "\033[0;33m \n>\n> Securing database \n>\n\033[0m"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE user = 'root';"
mysql -e "UPDATE mysql.user SET Password=PASSWORD('${MYSQL_PASS}') WHERE User='root';"
mysql -e "FLUSH PRIVILEGES;"
echo -e "Database password = ${MYSQL_PASS} \n"


##################################################################
# 14 - CREATE A FRAPPE USER, ASSIGN THE PROVIDED PASSWORD AND ADD THE USER TO SUDOERS LIST
##################################################################
echo -e "\033[0;33m \n>\n> Creating ${FRAPPE_USR} user \n>\n\033[0m"
useradd -m -s /bin/bash ${FRAPPE_USR}
echo ${FRAPPE_USR}:${FRAPPE_PWD} | chpasswd
usermod -aG sudo ${FRAPPE_USR}
echo "${FRAPPE_USR} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${FRAPPE_USR}
echo -e "Done \n"


##################################################################
# 15 - INSTALL BENCH
##################################################################
echo -e "\033[0;33m \n>\n> Installing bench \n>\n\033[0m"
pip3 install frappe-bench


##################################################################
# 16 - INSTALL FRAPPE
##################################################################
echo -e "\033[0;33m \n>\n> Installing frappe \n>\n\033[0m"
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/; bench init --frappe-branch ${FRAPPE_BRANCH} frappe-bench "
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; bench setup supervisor --yes"
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; bench setup nginx --yes"
ln -s /home/${FRAPPE_USR}/frappe-bench/config/nginx.conf /etc/nginx/conf.d/frappe-bench.conf
ln -s /home/${FRAPPE_USR}/frappe-bench/config/supervisor.conf /etc/supervisor/conf.d/frappe-bench.conf


##################################################################
# 17 - CHANGE SUPERVISORD OWNER
##################################################################
sed -i 's/chmod=0700/chown=frappe:frappe\nchmod=0700/' /etc/supervisor/supervisord.conf
supervisorctl reread
supervisorctl restart all
systemctl restart supervisor
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; bench restart"


##################################################################
# 18 - DOWNLOAD ERPNEXT FROM GITHUB
##################################################################
echo -e "\033[0;33m \n>\n> Downloading erpnext \n>\n\033[0m"
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; bench get-app --branch ${ERPNEXT_BRANCH} erpnext https://github.com/frappe/erpnext"


##################################################################
# 19 - CREATE THE SITE WITH EARLIER PROVIDED NAME
##################################################################
echo -e "\033[0;33m \n>\n> Creating new site ${SITE_URL} \n>\n\033[0m"
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; bench new-site ${SITE_URL} --mariadb-root-password $MYSQL_PASS --admin-password $SITE_PWD"
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; bench --site ${SITE_URL} install-app erpnext"
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; bench setup nginx --yes"
systemctl reload nginx 



##################################################################
# 20 - DEPLOY FOR PRODUCTION
##################################################################
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; sudo bench setup supervisor --yes"
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; sudo ln -s `pwd`/config/supervisor.conf /etc/supervisor/conf.d/frappe-bench.conf"
sudo -H -u ${FRAPPE_USR} bash -c "cd /home/${FRAPPE_USR}/frappe-bench && sudo supervisorctl reread && sudo supervisorctl update && sudo supervisorctl restart all"
sudo -H -u ${FRAPPE_USR} bash -c "cd /home/${FRAPPE_USR}/frappe-bench && sudo bench setup production ${FRAPPE_USR} --yes"
##################################################################
# 21 - RESTART NGINX AND ALL SUPERVISOR SERVICES
##################################################################
systemctl start nginx
systemctl start nginx.service
su ${FRAPPE_USR} -c "cd /home/${FRAPPE_USR}/frappe-bench/; sudo bench use ${SITE_URL}"



##################################################################
# 22 - CONGRATULATIONS!!!!!
##################################################################
echo -e "\033[0;33m \n>\n> Installation successful! CHEERS!!! \n>\n\033[0m"
echo -e "\033[0;33m \n>\n> Wishing you all the best from CODEWITHKARANI.COM \n>\n\033[0m"
