#!/bin/bash


sudo yum update -y

sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm

sudo yum install mysql80-community-release-el9-4.noarch.rpm -y

sudo yum install mysql-community-server -y
