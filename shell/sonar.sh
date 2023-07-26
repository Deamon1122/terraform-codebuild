#!/bin/bash
LOG=/tmp/sonar.log
SONAR_SRC=/opt/sonarqube
MYSQL_URL=http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm 
MYSQL_RPM=mysql-community-release-el7-5.noarch.rpm
SONAR_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-6.7.6.zip
SONAR_ZIP=sonarqube-6.7.6.zip
SONAR_VER=sonarqube-6.7.6

VALIDATE(){

if [ $1 -ne 0 ]; then
        echo "$2 .... FAILED"
    else    
        echo "$2 .... SUCCESS"
fi
}

yum install wget unzip java-1.8.0-openjdk -y &>>$LOG
VALIDATE $? "Installing SonarQube Dependences"

wget $MYSQL_URL -O /tmp/$MYSQL_RPM &>>$LOG
VALIDATE $? "Download Mysql"

cd /tmp/
rpm -ivh $MYSQL_RPM &>>$LOG
yum install mysql-server -y &>>$LOG
VALIDATE $? "MYSQL Package Installation"

systemctl start mysqld &>>$LOG
VALIDATE $? "MYSQL Service Start"


if [ -f /tmp/sonar.sql ]; then
echo " SonarQube Database is Updated ..!"
else
echo "CREATE DATABASE sonarqube_db;
CREATE USER 'sonarqube_user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON sonarqube_db.* TO 'sonarqube_user'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;" > /tmp/sonar.sql
mysql < /tmp/sonar.sql
VALIDATE $? "Configure SonarQube Database"
fi

egrep "Sonarqube" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
    echo " Sonarqube User Exists ...!"
else
    useradd Sonarqube &>>$LOG
    VALIDATE $? "Sonarqube User Creation"
fi    

if [ -d $SONAR_SRC ]; then
echo " Sonarqube Package Exists..! "
else
cd /tmp/
wget $SONAR_URL &>>$LOG
unzip $SONAR_ZIP &>>$LOG
mv $SONAR_VER /opt/sonarqube
sudo chown Sonarqube /opt/sonarqube -R
echo 'sonar.jdbc.username=sonarqube_user
sonar.jdbc.password=password
sonar.jdbc.url=jdbc:mysql://localhost:3306/sonarqube_db?useUnicode=true&amp;characterEncoding=utf8&amp;rewriteBatchedStatements=true&amp;useConfigs=maxPerformance' >> /opt/sonarqube/conf/sonar.properties
VALIDATE $? "Downloading SonarQube Package"
fi

echo "Updating Sonarqube Sonar.sh file"
sed -i 's/#RUN_AS_USER=/RUN_AS_USER=sonarqube/g' /opt/sonarqube/bin/linux-x86-64/sonar.sh

sh /opt/sonarqube/bin/linux-x86-64/sonar.sh start
VALIDATE $? "Starting SonarQube"