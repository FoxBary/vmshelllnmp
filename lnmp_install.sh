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
        echo -e "${RED}不支持的操作系统!${NC}"
        exit 1
    fi
}

# Show advertisement and confirmation
show_ad() {
    echo -e "${YELLOW}CMI线路高速网络云计算中心和美国云计算中心${NC}"
    echo "小巧灵动的VPS为全球网络提供全方位服务"
    echo "官网订购地址: https://vmshell.com/"
    echo "企业高速网络: https://tototel.com/"
    echo "TeleGram讨论: https://t.me/vmshellhk"
    echo "TeleGram频道: https://t.me/vmshell"
    echo "提供微信/支付宝/美国PayPal/USDT/比特币/支付(3日内无条件退款)"
    read -p "请确认安装LNMP脚本？(y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${RED}安装已取消${NC}"
        exit 0
    fi
}

# Update system and install basic tools
update_and_install_tools() {
    echo -e "${YELLOW}更新系统并安装基础工具...${NC}"
    case $OS in
        "centos")
            yum update -y
            yum install -y curl vim wget nano screen unzip zip cronie
            systemctl enable crond
            systemctl start crond
            ;;
        "ubuntu"|"debian")
            apt update -y
            apt install -y curl vim wget nano screen unzip zip cron
            systemctl enable cron
            systemctl start cron
            ;;
    esac
    echo -e "${GREEN}系统更新和基础工具安装完成${NC}"
}

# Version selection menu
select_version() {
    echo -e "${YELLOW}选择 Nginx 版本:${NC}"
    echo "1) 1.22.1 (稳定版)"
    echo "2) 1.23.3 (开发版)"
    read -p "输入选择 (1-2): " nginx_choice
    
    echo -e "${YELLOW}选择 MySQL 版本:${NC}"
    echo "1) 5.7.42"
    echo "2) 8.0.32"
    read -p "输入选择 (1-2): " mysql_choice
    
    echo -e "${YELLOW}选择 PHP 版本:${NC}"
    echo "1) 7.4.33"
    echo "2) 8.0.28"
    echo "3) 8.1.15"
    echo "4) 8.2.2"
    read -p "输入选择 (1-4): " php_choice
    
    case $nginx_choice in
        1) NGINX_VER="1.22.1" ;;
        2) NGINX_VER="1.23.3" ;;
        *) NGINX_VER="1.22.1" ;;
    esac
    
    case $mysql_choice in
        1) MYSQL_VER="5.7.42"; MYSQL_PKG="5.7" ;;
        2) MYSQL_VER="8.0.32"; MYSQL_PKG="8.0" ;;
        *) MYSQL_VER="8.0.32"; MYSQL_PKG="8.0" ;;
    esac
    
    case $php_choice in
        1) PHP_VER="7.4.33"; PHP_PKG="7.4" ;;
        2) PHP_VER="8.0.28"; PHP_PKG="8.0" ;;
        3) PHP_VER="8.1.15"; PHP_PKG="8.1" ;;
        4) PHP_VER="8.2.2"; PHP_PKG="8.2" ;;
        *) PHP_VER="8.0.28"; PHP_PKG="8.0" ;;
    esac
}

# Set MySQL root password
set_mysql_password() {
    read -s -p "输入 MySQL root 密码: " MYSQL_ROOT_PASSWORD
    echo
    read -s -p "确认 MySQL root 密码: " MYSQL_ROOT_PASSWORD_CONFIRM
    echo
    if [ "$MYSQL_ROOT_PASSWORD" != "$MYSQL_ROOT_PASSWORD_CONFIRM" ]; then
        echo -e "${RED}密码不匹配!${NC}"
        exit 1
    fi
}

# Add third-party repositories
add_repositories() {
    case $OS in
        "centos")
            yum install -y epel-release
            curl -o /etc/yum.repos.d/remi.repo http://rpms.remirepo.net/enterprise/remi-release-7.rpm
            ;;
        "debian")
            # Add MySQL APT repository
            wget -O mysql-apt-config.deb https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
            dpkg -i mysql-apt-config.deb
            rm mysql-apt-config.deb
            # Add PHP Sury repository
            apt install -y lsb-release ca-certificates apt-transport-https
            wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
            echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
            apt update
            ;;
        "ubuntu")
            add-apt-repository -y ppa:ondrej/php || true
            apt update
            ;;
    esac
}

# Install LNMP with progress
install_lnmp() {
    case $OS in
        "centos")
            echo -e "${YELLOW}正在安装 Nginx...${NC}"
            yum install -y nginx
            echo -e "${GREEN}Nginx $NGINX_VER 安装完成${NC}"

            echo -e "${YELLOW}正在安装 MySQL/MariaDB...${NC}"
            yum install -y mariadb-server mariadb
            echo -e "${GREEN}MySQL $MYSQL_VER 安装完成${NC}"

            echo -e "${YELLOW}正在安装 PHP...${NC}"
            yum-config-manager --enable remi-php${PHP_PKG//./}
            yum install -y php php-fpm php-mysqlnd php-common
            echo -e "${GREEN}PHP $PHP_VER 安装完成${NC}"
            ;;
            
        "ubuntu"|"debian")
            echo -e "${YELLOW}正在安装 Nginx...${NC}"
            apt install -y nginx
            echo -e "${GREEN}Nginx $NGINX_VER 安装完成${NC}"

            echo -e "${YELLOW}正在安装 MySQL...${NC}"
            apt install -y mysql-server-${MYSQL_PKG} || apt install -y mariadb-server
            echo -e "${GREEN}MySQL $MYSQL_VER 安装完成${NC}"

            echo -e "${YELLOW}正在安装 PHP...${NC}"
            apt install -y php${PHP_PKG} php${PHP_PKG}-fpm php${PHP_PKG}-mysql php${PHP_PKG}-common
            echo -e "${GREEN}PHP $PHP_VER 安装完成${NC}"
            ;;
    esac
    
    # Configure MySQL
    echo -e "${YELLOW}正在配置 MySQL...${NC}"
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    echo -e "${GREEN}MySQL 配置完成${NC}"
}

# Start services and configure firewall for CentOS
start_services() {
    echo -e "${YELLOW}正在启动服务...${NC}"
    case $OS in
        "centos")
            systemctl enable nginx mariadb php-fpm
            systemctl start nginx mariadb php-fpm
            # Open port 3306
            if command -v firewall-cmd >/dev/null; then
                firewall-cmd --permanent --add-port=3306/tcp
                firewall-cmd --reload
                echo -e "${GREEN}已为 CentOS 开启 3306 端口${NC}"
            fi
            ;;
        "ubuntu"|"debian")
            systemctl enable nginx mysql php${PHP_PKG}-fpm
            systemctl start nginx mysql php${PHP_PKG}-fpm
            ;;
    esac
    echo -e "${GREEN}服务启动完成${NC}"
}

# Uninstall function
uninstall_lnmp() {
    echo -e "${YELLOW}正在卸载 LNMP...${NC}"
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
    echo -e "${GREEN}LNMP 已卸载${NC}"
}

# Main execution
echo -e "${GREEN}LNMP 安装脚本${NC}"
detect_os
show_ad
update_and_install_tools
add_repositories
echo "1) 安装 LNMP"
echo "2) 卸载 LNMP"
read -p "选择操作 (1-2): " choice

case $choice in
    1)
        select_version
        set_mysql_password
        install_lnmp
        start_services
        echo -e "${GREEN}LNMP 安装完成!${NC}"
        echo "Nginx 版本: $NGINX_VER"
        echo "MySQL 版本: $MYSQL_VER"
        echo "PHP 版本: $PHP_VER"
        ;;
    2)
        uninstall_lnmp
        ;;
    *)
        echo -e "${RED}无效选项${NC}"
        exit 1
        ;;
esac
