#!/bin/bash
LOG=/tmp/sonar.log
SONAR_SRC=/opt/sonarqube

echo "Installing SonarQube Dependences"
yum install wget unzip java -y &>>$LOG
if [ $? -ne 0 ]; then
    echo " SonarQube Dependences ....FAILED"
    exit 1
else
    echo " SonarQube Dependences ....SUCCESS"    
fi 

echo " Downlaoding MYSQL Package "
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm -O /tmp/mysql-community-release-el7-5.noarch.rpm &>>$LOG
if [ $? -ne 0 ]; then
    echo " MYSQL Package Downlaod....FAILED"
    exit 1
else
    echo " MYSQL Package Downlaod....SUCCESS"    
fi 

echo "Installing MySql Package"
cd /tmp/
rpm -ivh mysql-community-release-el7-5.noarch.rpm &>>$LOG
yum install mysql-server -y &>>$LOG
if [ $? -ne 0 ]; then
    echo " Mysql Package ....FAILED"
    exit1
else
    echo " Mysql Package ....SUCCESS"
fi

echo " Starting MYSQL Service "
systemctl start mysqld &>>$LOG
if [ $? -ne 0 ]; then
    echo " Starting MYSQL Service ....FAILED"
    exit1
else
    echo " Starting MYSQL Service ....SUCCESS"
fi

echo " Configure SonarQube Database "

if [ -f /tmp/sonar.sql ]; then
echo " SonarQube Database is Updated ..!"
else
echo "CREATE DATABASE sonarqube_db;
CREATE USER 'sonarqube_user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON sonarqube_db.* TO 'sonarqube_user'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;" > /tmp/sonar.sql
mysql < /tmp/sonar.sql
echo " Configure SonarQube Database .... SUCCESS"
fi

echo " Creating Sonarqube User "
useradd Sonarqube &>>$LOG

echo " Downloading SonarQube Package "
if [ -d $SONAR_SRC ]; then
echo " Sonarqube Package Exists..! "
else
cd /tmp/
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-6.7.6.zip &>>$LOG
unzip sonarqube-6.7.6.zip &>>$LOG
mv sonarqube-6.7.6 /opt/sonarqube
chown Sonarqube. /opt/sonarqube -R
echo 'sonar.jdbc.username=sonarqube_user
sonar.jdbc.password=password
sonar.jdbc.url=jdbc:mysql://localhost:3306/sonarqube_db?useUnicode=true&amp;characterEncoding=utf8&amp;rewriteBatchedStatements=true&amp;useConfigs=maxPerformance' >> /opt/sonarqube/conf/sonar.properties
echo "Downloading SonarQube Package"
fi

echo "Updating Sonarqube Sonar.sh file"
sed -i 's/#RUN_AS_USER=/RUN_AS_USER=sonarqube/g' /opt/sonarqube/bin/linux-x86-32/sonar.sh