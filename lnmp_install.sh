#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请以root用户或使用sudo运行此脚本${NC}"
    exit 1
fi

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}无法检测操作系统${NC}"
    exit 1
fi

# 检查并安装curl和wget
install_curl_wget() {
    echo -e "${YELLOW}检查并安装curl和wget...${NC}"
    if ! command -v curl &> /dev/null || ! command -v wget &> /dev/null; then
        echo -e "${YELLOW}curl或wget未安装，正在安装...${NC}"
        if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
            apt update -y || { echo -e "${RED}更新失败，请检查网络${NC}"; exit 1; }
            apt install -y curl wget || { echo -e "${RED}安装失败${NC}"; exit 1; }
        elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
            yum update -y || { echo -e "${RED}更新失败，请检查网络${NC}"; exit 1; }
            yum install -y curl wget || { echo -e "${RED}安装失败${NC}"; exit 1; }
        else
            echo -e "${RED}不支持的操作系统${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}curl和wget已安装${NC}"
    fi
}

# 检查并安装Git
install_git() {
    echo -e "${YELLOW}检查并安装Git...${NC}"
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Git未安装，正在安装...${NC}"
        if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
            apt install -y git || { echo -e "${RED}Git安装失败${NC}"; exit 1; }
        elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
            yum install -y git || { echo -e "${RED}Git安装失败${NC}"; exit 1; }
        fi
    else
        echo -e "${GREEN}Git已安装${NC}"
    fi
    git --version
}

# 安装依赖函数
install_dependencies() {
    echo -e "${YELLOW}正在更新系统并安装基本依赖...${NC}"
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt update -y && apt upgrade -y || { echo -e "${RED}更新失败${NC}"; exit 1; }
        apt install -y unzip software-properties-common || { echo -e "${RED}依赖安装失败${NC}"; exit 1; }
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        yum update -y || { echo -e "${RED}更新失败${NC}"; exit 1; }
        yum install -y epel-release || { echo -e "${RED}依赖安装失败${NC}"; exit 1; }
    else
        echo -e "${RED}不支持的操作系统${NC}"
        exit 1
    fi
}

# 检查并安装Node.js和npm
install_nodejs_npm() {
    echo -e "${YELLOW}检查并安装Node.js和npm...${NC}"
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        echo -e "${YELLOW}Node.js或npm未安装，正在安装...${NC}"
        if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
            apt install -y nodejs || { echo -e "${RED}Node.js安装失败${NC}"; exit 1; }
        elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
            curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
            yum install -y nodejs || { echo -e "${RED}Node.js安装失败${NC}"; exit 1; }
        fi
    else
        echo -e "${GREEN}Node.js和npm已安装${NC}"
    fi
    node -v && npm -v
}

# 安装Nginx（仅提供1.20和1.21版本）
install_nginx() {
    echo -e "${YELLOW}=== 选择Nginx版本 ===${NC}"
    echo "1. Nginx 1.20"
    echo "2. Nginx 1.21"
    read -p "请选择Nginx版本 [1-2]: " nginx_choice
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        case $nginx_choice in
            1) apt install -y nginx=1.20.* ;;
            2) apt install -y nginx=1.21.* ;;
            *) echo -e "${RED}无效选项，使用Nginx 1.21${NC}"; apt install -y nginx=1.21.* ;;
        esac
        systemctl enable nginx
        systemctl start nginx
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        case $nginx_choice in
            1) yum install -y nginx-1.20.* ;;
            2) yum install -y nginx-1.21.* ;;
            *) echo -e "${RED}无效选项，使用Nginx 1.21${NC}"; yum install -y nginx-1.21.* ;;
        esac
        systemctl enable nginx
        systemctl start nginx
    fi
}

# 安装MySQL（仅提供5.7和8.2版本）
install_mariadb() {
    echo -e "${YELLOW}=== 选择MySQL版本 ===${NC}"
    echo "1. MySQL 5.7"
    echo "2. MySQL 8.2"
    read -p "请选择MySQL版本 [1-2]: " db_choice

    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        case $db_choice in
            1) 
                wget https://dev.mysql.com/get/mysql-apt-config_0.8.23-1_all.deb
                dpkg -i mysql-apt-config_0.8.23-1_all.deb
                apt update -y
                apt install -y mysql-server=5.7.* ;;
            2) 
                wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
                dpkg -i mysql-apt-config_0.8.29-1_all.deb
                apt update -y
                apt install -y mysql-server ;;
            *) echo -e "${RED}无效选项，使用MySQL 8.2${NC}"; 
                wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
                dpkg -i mysql-apt-config_0.8.29-1_all.deb
                apt update -y
                apt install -y mysql-server ;;
        esac
        systemctl enable mysql
        systemctl start mysql
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        case $db_choice in
            1) 
                yum install -y https://dev.mysql.com/get/mysql57-community-release-el$(rpm -E %rhel)-11.noarch.rpm
                yum install -y mysql-community-server-5.7.* ;;
            2) 
                yum install -y https://dev.mysql.com/get/mysql80-community-release-el$(rpm -E %rhel)-1.noarch.rpm
                yum install -y mysql-community-server ;;
            *) echo -e "${RED}无效选项，使用MySQL 8.2${NC}"; 
                yum install -y https://dev.mysql.com/get/mysql80-community-release-el$(rpm -E %rhel)-1.noarch.rpm
                yum install -y mysql-community-server ;;
        esac
        systemctl enable mysqld
        systemctl start mysqld
    fi

    # 用户交互设置root密码
    echo -e "${YELLOW}设置MySQL root 用户密码${NC}"
    read -s -p "请输入root密码: " ROOT_PASSWORD
    echo
    read -s -p "请再次输入root密码以确认: " ROOT_PASSWORD_CONFIRM
    echo
    if [ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]; then
        echo -e "${RED}两次输入的密码不一致，请重新运行脚本${NC}"
        exit 1
    fi

    # 设置root密码并开启远程访问
    mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$ROOT_PASSWORD');"
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$ROOT_PASSWORD' WITH GRANT OPTION;"
    mysql -e "FLUSH PRIVILEGES;"

    # 修改配置文件以监听所有接口
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/my.cnf
    fi

    # 重启服务
    systemctl restart mysql || systemctl restart mysqld

    # 打开防火墙3306端口
    if command -v ufw &> /dev/null; then
        ufw allow 3306
        echo -e "${GREEN}已通过ufw开启3306端口${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=3306/tcp
        firewall-cmd --reload
        echo -e "${GREEN}已通过firewalld开启3306端口${NC}"
    else
        echo -e "${YELLOW}未检测到ufw或firewalld，请手动开启3306端口${NC}"
    fi

    echo -e "${GREEN}MySQL root 密码已设置，3306端口已开启，可远程访问${NC}"
}

# 安装PHP（仅提供7.4和8.1版本）
install_php() {
    echo -e "${YELLOW}=== 选择PHP版本 ===${NC}"
    echo "1. PHP 7.4"
    echo "2. PHP 8.1"
    read -p "请选择PHP版本 [1-2]: " php_choice
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        add-apt-repository ppa:ondrej/php -y
        apt update -y
        case $php_choice in
            1) PHP_VER="7.4" ;;
            2) PHP_VER="8.1" ;;
            *) echo -e "${RED}无效选项，使用PHP 8.1${NC}"; PHP_VER="8.1" ;;
        esac
        apt install -y php${PHP_VER} php${PHP_VER}-fpm php${PHP_VER}-mysql php${PHP_VER}-cli php${PHP_VER}-mbstring php${PHP_VER}-zip php${PHP_VER}-gd
        systemctl enable php${PHP_VER}-fpm
        systemctl start php${PHP_VER}-fpm
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
        yum module reset php -y
        case $php_choice in
            1) yum module enable php:remi-7.4 -y; PHP_VER="7.4" ;;
            2) yum module enable php:remi-8.1 -y; PHP_VER="8.1" ;;
            *) echo -e "${RED}无效选项，使用PHP 8.1${NC}"; yum module enable php:remi-8.1 -y; PHP_VER="8.1" ;;
        esac
        yum install -y php php-fpm php-mysqlnd php-cli php-mbstring php-zip php-gd
        systemctl enable php-fpm
        systemctl start php-fpm
    fi
    echo "$PHP_VER"
}

# 安装最新Redis
install_redis() {
    echo -e "${YELLOW}正在安装最新版Redis...${NC}"
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt install -y redis-server
        systemctl enable redis-server
        systemctl start redis-server
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        yum install -y redis
        systemctl enable redis
        systemctl start redis
    fi
}

# 配置Nginx支持PHP
config_nginx_php() {
    local php_ver=$1
    echo -e "${YELLOW}正在配置Nginx以支持PHP ${php_ver}...${NC}"
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${php_ver}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
        ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    fi
    systemctl restart nginx
}

# 配置管理面板
setup_management_panel() {
    echo -e "${YELLOW}=== 配置管理面板 ===${NC}"
    read -p "请输入管理面板端口号 (默认8080): " PORT
    PORT=${PORT:-8080}
    read -p "请输入管理面板用户名: " USERNAME
    read -s -p "请输入管理面板密码: " PASSWORD
    echo

    install_nodejs_npm
    mkdir -p /opt/lnmp_panel
    cp panel.js /opt/lnmp_panel/
    cp package.json /opt/lnmp_panel/
    cd /opt/lnmp_panel
    npm install

    cat > /opt/lnmp_panel/config.json <<EOF
{
    "port": $PORT,
    "username": "$USERNAME",
    "password": "$PASSWORD"
}
EOF

    cat > /etc/systemd/system/lnmp_panel.service <<EOF
[Unit]
Description=LNMP Management Panel
After=network.target

[Service]
ExecStart=/usr/bin/node /opt/lnmp_panel/panel.js
Restart=always
User=root
WorkingDirectory=/opt/lnmp_panel

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable lnmp_panel
    systemctl start lnmp_panel
    echo -e "${GREEN}管理面板已启动，请访问 http://你的服务器IP:${PORT}${NC}"
}

# 一键安装LNMP
install_lnmp() {
    install_curl_wget
    install_git
    install_dependencies
    install_nginx
    install_mariadb
    PHP_VERSION=$(install_php)
    install_redis
    config_nginx_php "$PHP_VERSION"
    setup_management_panel
    echo -e "${GREEN}LNMP环境及管理面板安装完成！${NC}"
}

# 卸载函数
uninstall_component() {
    echo -e "${YELLOW}=== 选择要卸载的组件 ===${NC}"
    echo "1. 卸载Nginx"
    echo "2. 卸载MySQL"
    echo "3. 卸载PHP"
    echo "4. 卸载Redis"
    echo "5. 卸载管理面板"
    echo "6. 卸载所有LNMP组件"
    echo "7. 返回主菜单"
    read -p "请选择操作 [1-7]: " uninstall_choice

    case $uninstall_choice in
        1) 
            systemctl stop nginx
            if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
                apt purge -y nginx nginx-common nginx-full
                rm -rf /etc/nginx
            elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
                yum remove -y nginx
                rm -rf /etc/nginx
            fi
            echo -e "${GREEN}Nginx已卸载${NC}" ;;
        2) 
            systemctl stop mysql || systemctl stop mysqld
            if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
                apt purge -y mysql-server mysql-client
                rm -rf /etc/mysql /var/lib/mysql
            elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
                yum remove -y mysql-community-server
                rm -rf /etc/my.cnf /var/lib/mysql
            fi
            echo -e "${GREEN}MySQL已卸载${NC}" ;;
        3) 
            systemctl stop php*-fpm
            if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
                apt purge -y php7.4* php8.1*
                rm -rf /etc/php
            elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
                yum remove -y php php-fpm php-mysqlnd php-cli php-mbstring php-zip php-gd
                rm -rf /etc/php.d /etc/php.ini
            fi
            echo -e "${GREEN}PHP已卸载${NC}" ;;
        4) 
            systemctl stop redis
            if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
                apt purge -y redis-server
                rm -rf /etc/redis
            elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
                yum remove -y redis
                rm -rf /etc/redis
            fi
            echo -e "${GREEN}Redis已卸载${NC}" ;;
        5) 
            systemctl stop lnmp_panel
            systemctl disable lnmp_panel
            rm -f /etc/systemd/system/lnmp_panel.service
            rm -rf /opt/lnmp_panel
            echo -e "${GREEN}管理面板已卸载${NC}" ;;
        6) 
            systemctl stop nginx mysql mysqld php*-fpm redis lnmp_panel
            if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
                apt purge -y nginx nginx-common nginx-full mysql-server mysql-client php7.4* php8.1* redis-server
                apt autoremove -y
                rm -rf /etc/nginx /etc/mysql /var/lib/mysql /etc/php /etc/redis /opt/lnmp_panel
            elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
                yum remove -y nginx mysql-community-server php php-fpm php-mysqlnd php-cli php-mbstring php-zip php-gd redis
                yum autoremove -y
                rm -rf /etc/nginx /etc/my.cnf /var/lib/mysql /etc/php.d /etc/php.ini /etc/redis /opt/lnmp_panel
            fi
            systemctl disable lnmp_panel
            rm -f /etc/systemd/system/lnmp_panel.service
            echo -e "${GREEN}所有LNMP组件已卸载${NC}" ;;
        7) return ;;
        *) echo -e "${RED}无效选项${NC}" ;;
    esac
}

# 服务管理菜单
manage_services() {
    while true; do
        echo -e "${YELLOW}=== LNMP 服务管理 ===${NC}"
        echo "1. 重启Nginx"
        echo "2. 重启MySQL"
        echo "3. 重启PHP-FPM (选择版本)"
        echo "4. 重启Redis"
        echo "5. 重启管理面板"
        echo "6. 停止所有服务"
        echo "7. 启动所有服务"
        echo "8. 返回主菜单"
        read -p "请选择操作 [1-8]: " choice
        case $choice in
            1) systemctl restart nginx ;;
            2) systemctl restart mysql || systemctl restart mysqld ;;
            3) 
                echo "选择PHP版本:"
                echo "1. PHP 7.4"
                echo "2. PHP 8.1"
                read -p "请输入 [1-2]: " php_ver_choice
                case $php_ver_choice in
                    1) systemctl restart php7.4-fpm ;;
                    2) systemctl restart php8.1-fpm ;;
                    *) echo -e "${RED}无效选项${NC}" ;;
                esac ;;
            4) systemctl restart redis ;;
            5) systemctl restart lnmp_panel ;;
            6) systemctl stop nginx mysql mysqld php*-fpm redis lnmp_panel ;;
            7) systemctl start nginx mysql mysqld php*-fpm redis lnmp_panel ;;
            8) break ;;
            *) echo -e "${RED}无效选项${NC}" ;;
        esac
    done
}

# 主菜单
main_menu() {
    while true; do
        echo -e "${YELLOW}=== LNMP 管理面板 ===${NC}"
        echo "1. 一键安装LNMP（含Redis和管理面板）"
        echo "2. 管理服务"
        echo "3. 卸载组件"
        echo "4. 退出"
        read -p "请选择操作 [1-4]: " choice
        case $choice in
            1) install_lnmp ;;
            2) manage_services ;;
            3) uninstall_component ;;
            4) echo -e "${GREEN}退出程序${NC}"; exit 0 ;;
            *) echo -e "${RED}无效选项${NC}" ;;
        esac
    done
}

# 运行主菜单
main_menu
