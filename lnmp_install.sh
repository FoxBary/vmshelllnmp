#!/bin/bash
# LNMP Installation Script for CentOS/Ubuntu/Debian
# Created on March 08, 2025
# Author: Grok 3 (xAI)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
detect_os() {
    if [ -f /etc/redhat-release ]; then
        OS="centos"
    elif [ -f /etc/debian_version ]; then
        if [ -f /etc/lsb-release ]; then
            OS="ubuntu"
        else
            OS="debian"
        fi
    else
        echo -e "${RED}Unsupported operating system!${NC}"
        exit 1
    fi
}

# Update package manager
update_package_manager() {
    echo -e "${YELLOW}Updating package manager...${NC}"
    case $OS in
        "centos")
            yum update -y
            yum install -y wget curl
            ;;
        "ubuntu"|"debian")
            apt update -y
            apt install -y wget curl
            ;;
    esac
}

# Version selection menu
select_version() {
    echo -e "${YELLOW}Select Nginx version:${NC}"
    echo "1) 1.22.1 (Stable)"
    echo "2) 1.23.3 (Development)"
    read -p "Enter choice (1-2): " nginx_choice
    
    echo -e "${YELLOW}Select MySQL version:${NC}"
    echo "1) 5.7.42"
    echo "2) 8.0.32"
    read -p "Enter choice (1-2): " mysql_choice
    
    echo -e "${YELLOW}Select PHP version:${NC}"
    echo "1) 7.4.33"
    echo "2) 8.0.28"
    echo "3) 8.1.15"
    echo "4) 8.2.2"
    read -p "Enter choice (1-4): " php_choice
    
    # Set versions based on choices
    case $nginx_choice in
        1) NGINX_VER="1.22.1" ;;
        2) NGINX_VER="1.23.3" ;;
        *) NGINX_VER="1.22.1" ;;
    esac
    
    case $mysql_choice in
        1) MYSQL_VER="5.7.42" ;;
        2) MYSQL_VER="8.0.32" ;;
        *) MYSQL_VER="8.0.32" ;;
    esac
    
    case $php_choice in
        1) PHP_VER="7.4.33" ;;
        2) PHP_VER="8.0.28" ;;
        3) PHP_VER="8.1.15" ;;
        4) PHP_VER="8.2.2" ;;
        *) PHP_VER="8.0.28" ;;
    esac
}

# Set MySQL root password
set_mysql_password() {
    read -s -p "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
    echo
    read -s -p "Confirm MySQL root password: " MYSQL_ROOT_PASSWORD_CONFIRM
    echo
    if [ "$MYSQL_ROOT_PASSWORD" != "$MYSQL_ROOT_PASSWORD_CONFIRM" ]; then
        echo -e "${RED}Passwords do not match!${NC}"
        exit 1
    fi
}

# Install LNMP
install_lnmp() {
    echo -e "${YELLOW}Installing LNMP...${NC}"
    
    case $OS in
        "centos")
            # Install Nginx
            yum install -y epel-release
            yum install -y nginx
            
            # Install MySQL/MariaDB
            yum install -y mariadb-server mariadb
            
            # Install PHP
            yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
            yum-config-manager --enable remi-php${PHP_VER//./}
            yum install -y php php-fpm php-mysqlnd php-common
            ;;
            
        "ubuntu"|"debian")
            # Install Nginx
            apt install -y nginx
            
            # Install MySQL
            apt install -y mysql-server
            
            # Install PHP
            apt install -y software-properties-common
            add-apt-repository -y ppa:ondrej/php
            apt update
            apt install -y php${PHP_VER} php${PHP_VER}-fpm php${PHP_VER}-mysql php${PHP_VER}-common
            ;;
    esac
    
    # Configure MySQL
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
}

# Start services
start_services() {
    echo -e "${YELLOW}Starting services...${NC}"
    case $OS in
        "centos")
            systemctl enable nginx mariadb php-fpm
            systemctl start nginx mariadb php-fpm
            ;;
        "ubuntu"|"debian")
            systemctl enable nginx mysql php${PHP_VER}-fpm
            systemctl start nginx mysql php${PHP_VER}-fpm
            ;;
    esac
}

# Uninstall function
uninstall_lnmp() {
    echo -e "${YELLOW}Uninstalling LNMP...${NC}"
    case $OS in
        "centos")
            systemctl stop nginx mariadb php-fpm
            yum remove -y nginx mariadb-server php php-fpm
            rm -rf /etc/nginx /var/lib/mysql /etc/php*
            ;;
        "ubuntu"|"debian")
            systemctl stop nginx mysql php*-fpm
            apt purge -y nginx mysql-server php*
            rm -rf /etc/nginx /var/lib/mysql /etc/php
            ;;
    esac
    echo -e "${GREEN}LNMP has been uninstalled${NC}"
}

# Main execution
echo -e "${GREEN}LNMP Installation Script${NC}"
echo "1) Install LNMP"
echo "2) Uninstall LNMP"
read -p "Select an option (1-2): " choice

case $choice in
    1)
        detect_os
        update_package_manager
        select_version
        set_mysql_password
        install_lnmp
        start_services
        echo -e "${GREEN}LNMP installation completed!${NC}"
        echo "Nginx version: $NGINX_VER"
        echo "MySQL version: $MYSQL_VER"
        echo "PHP version: $PHP_VER"
        ;;
    2)
        detect_os
        uninstall_lnmp
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac
