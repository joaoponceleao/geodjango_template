#!/usr/bin/env bash

DB_NAME='db_name' # needs to be all lower case.
DB_USERNAME='db_user'
DB_PASSWORD='password'

echo "INSTALLING REQUIREMENTS"

sudo su

if [ "$(whoami)" != "root" ]; then
    echo "THIS SCRIPT MUST BE RUN AS ROOT!"
    exit 1
fi

echo "SETTING UP ENVIRONMENT"

touch /etc/profile.d/profile.sh
echo "export LANGUAGE=en_US.UTF-8" >> /etc/profile.d/profile.sh
echo "export LANG=en_US.UTF-8" >> /etc/profile.d/profile.sh
echo "export LC_ALL=en_US.UTF-8" >> /etc/profile.d/profile.sh
source /etc/profile.d/profile.sh
locale-gen en_US.UTF-8
dpkg-reconfigure locales

echo "UPDATING SYSTEM"

apt-get -y update
apt-get -y upgrade
apt-get install -y python-software-properties
add-apt-repository ppa:ubuntugis/ppa
apt-get -y update
apt-get -y upgrade

echo "INSTALLING BUILD TOOLS."

apt-get install -y build-essential libxml2-dev libxslt1-dev

echo "INSTALLING PYTHON DEPENDENCIES."

apt-get install -y python python-dev
pip install virtualenv
pip install virtualenvwrapper
pip install --upgrade pip

echo "iNSTALLING SUPPORT TOOLS."
apt-get install -y git vim unzip

#echo "---------------------------------------------"
#echo "installing geoserver."
#echo "---------------------------------------------"
#apt-get install -y openjdk-6-jre apache2
#echo "export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64" >> ~/.bashrc
#source ~/.bashrc
#wget -O ~/geoserver-2.2.3-bin.zip http://downloads.sourceforge.net/geoserver/geoserver-2.2.3-bin.zip
#unzip ~/geoserver-2.2.3-bin.zip -d /opt/
#ln -s /opt/geoserver-2.2.3 /opt/geoserver
#mv ~/geoserver-2.2.3-bin.zip ~/archive/

echo "INSTALLING GEOSPATIAL LIBRARIES"
apt-get install -y binutils libproj-dev gdal-bin libgeoip1 python-gdal

echo "INSTALLING POSTGRESQL"
apt-get install -y postgresql-9.1 postgresql-9.1-postgis postgresql-contrib-9.1 postgis libpq-dev python-psycopg2
cp /vagrant/pg_hba.conf /etc/postgresql/9.1/main/
/etc/init.d/postgresql restart

echo "SETING UP SERVERS"

# Apache setup
# apt-get install apache2 apache2.2-common apache2-mpm-prefork apache2-utils libexpat1
# apt-get install libapache2-mod-wsgi
# service apache2 restart

# Create limited privileges user for deployment
# sudo groupadd --system webapps
# sudo useradd --system --gid webapps --home /webapps/gene gene
# sudo chown -R app:users /webapps/gene
# sudo chown -R g+w /webapps/gene
# sudo usermod -a -G users `whoami`

# Gunicorn setup
#pip install gunicorn
#pip install setproctitle
#sudo apt-get install supervisor
#sudo chmod u+x bin/gunicorn_start

# Nginx setup
#sudo apt-get install ngix
#sudo service nginx start

sudo su vagrant
echo "SETING UP VIRTUALENV"
echo "export WORKON_HOME=~/.venvs" >> ~/.profile
echo "export PROJECT_HOME=/vagrant/dev" >> ~/.profile
echo "export PIP_VIRTUALENV_BASE=$WORKON_HOME" >> ~/.profile
echo "export PIP_RESPECT_VIRTUALENV=true" >> ~/.profile
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.profile
mkvirtualenv gna_dev
sudo pip install -r /vagrant/requirements.txt

echo "CREATING PGSQL DB AND ROLE"

sudo su postgres
createdb $DB_NAME
psql $DB_NAME -c "CREATE EXTENSION adminpack;"
psql $DB_NAME -c "CREATE EXTENSION postgis;"
psql $DB_NAME -c "CREATE EXTENSION postgis_topology"
psql $DB_NAME -c "CREATE EXTENSION hstore"
psql -c "CREATE ROLE $DB_USERNAME WITH LOGIN ENCRYPTED PASSWORD '$DB_PASSWORD';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USERNAME;"

echo " FINISHED"

printf "Django database info:
DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': '$DB_NAME',
        'USER': '$DB_USERNAME',
        'PASSWORD': '$DB_PASSWORD',
        'HOST': 'localhost',
        'PORT': '',
    }
}
"
