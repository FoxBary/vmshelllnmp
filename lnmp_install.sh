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

# 检查并安装Git
install_git() {
    echo -e "${YELLOW}检查并安装Git...${NC}"
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Git未安装，正在安装...${NC}"
        if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
            apt update -y
            apt install -y git
        elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
            yum update -y
            yum install -y git
        else
            echo -e "${RED}不支持的操作系统${NC}"
            exit 1
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
        apt update -y && apt upgrade -y
        apt install -y curl wget unzip software-properties-common
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        yum update -y
        yum install -y curl wget unzip epel-release
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
            apt install -y nodejs
        elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
            curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
            yum install -y nodejs
        fi
    else
        echo -e "${GREEN}Node.js和npm已安装${NC}"
    fi
    node -v && npm -v
}

# 安装Nginx
install_nginx() {
    echo -e "${YELLOW}=== 选择Nginx版本 ===${NC}"
    echo "1. Nginx Stable (默认稳定版)"
    echo "2. Nginx Mainline (最新开发版)"
    read -p "请选择Nginx版本 [1-2]: " nginx_choice
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        case $nginx_choice in
            1) apt install -y nginx ;;
            2) 
                add-apt-repository ppa:nginx/development -y
                apt update -y
                apt install -y nginx ;;
            *) echo -e "${RED}无效选项，使用默认稳定版${NC}"; apt install -y nginx ;;
        esac
        systemctl enable nginx
        systemctl start nginx
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        case $nginx_choice in
            1) yum install -y nginx ;;
            2) 
                yum install -y yum-utils
                echo "[nginx-mainline]" > /etc/yum.repos.d/nginx-mainline.repo
                echo "name=nginx mainline repo" >> /etc/yum.repos.d/nginx-mainline.repo
                echo "baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/" >> /etc/yum.repos.d/nginx-mainline.repo
                echo "gpgcheck=1" >> /etc/yum.repos.d/nginx-mainline.repo
                echo "enabled=1" >> /etc/yum.repos.d/nginx-mainline.repo
                echo "gpgkey=https://nginx.org/keys/nginx_signing.key" >> /etc/yum.repos.d/nginx-mainline.repo
                yum install -y nginx ;;
            *) echo -e "${RED}无效选项，使用默认稳定版${NC}"; yum install -y nginx ;;
        esac
        systemctl enable nginx
        systemctl start nginx
    fi
}

# 安装MariaDB并设置root密码，开启3306端口
install_mariadb() {
    echo -e "${YELLOW}=== 选择MariaDB版本 ===${NC}"
    echo "1. MariaDB 10.5 (稳定版)"
    echo "2. MariaDB 10.11 (最新版)"
    read -p "请选择MariaDB版本 [1-2]: " mariadb_choice

    # 安装MariaDB
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        case $mariadb_choice in
            1) apt install -y mariadb-server-10.5 mariadb-client-10.5 ;;
            2) 
                wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
                bash mariadb_repo_setup --mariadb-server-version="mariadb-10.11"
                apt update -y
                apt install -y mariadb-server mariadb-client ;;
            *) echo -e "${RED}无效选项，使用默认版${NC}"; apt install -y mariadb-server ;;
        esac
        systemctl enable mariadb
        systemctl start mariadb
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        case $mariadb_choice in
            1) yum install -y mariadb-server-10.5 mariadb-10.5 ;;
            2) 
                wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
                bash mariadb_repo_setup --mariadb-server-version="mariadb-10.11"
                yum install -y mariadb-server mariadb ;;
            *) echo -e "${RED}无效选项，使用默认版${NC}"; yum install -y mariadb-server ;;
        esac
        systemctl enable mariadb
        systemctl start mariadb
    fi

    # 用户交互设置root密码
    echo -e "${YELLOW}设置MariaDB root用户密码${NC}"
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

    # 修改MariaDB配置文件以监听所有接口
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf
    fi

    # 重启MariaDB服务
    systemctl restart mariadb

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

    echo -e "${GREEN}MariaDB root密码已设置，3306端口已开启，可远程访问${NC}"
}

# 安装PHP
install_php() {
    echo -e "${YELLOW}=== 选择PHP版本 ===${NC}"
    echo "1. PHP 7.4"
    echo "2. PHP 8.0"
    echo "3. PHP 8.1"
    echo "4. PHP 8.2"
    read -p "请选择PHP版本 [1-4]: " php_choice
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        add-apt-repository ppa:ondrej/php -y
        apt update -y
        case $php_choice in
            1) PHP_VER="7.4" ;;
            2) PHP_VER="8.0" ;;
            3) PHP_VER="8.1" ;;
            4) PHP_VER="8.2" ;;
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
            2) yum module enable php:remi-8.0 -y; PHP_VER="8.0" ;;
            3) yum module enable php:remi-8.1 -y; PHP_VER="8.1" ;;
            4) yum module enable php:remi-8.2 -y; PHP_VER="8.2" ;;
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

    # 安装Node.js和npm
    install_nodejs_npm

    # 创建管理面板目录
    mkdir -p /opt/lnmp_panel
    cp panel.js /opt/lnmp_panel/
    cp package.json /opt/lnmp_panel/
    cd /opt/lnmp_panel
    npm install

    # 创建配置文件
    cat > /opt/lnmp_panel/config.json <<EOF
{
    "port": $PORT,
    "username": "$USERNAME",
    "password": "$PASSWORD"
}
EOF

    # 设置服务
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

# 服务管理菜单
manage_services() {
    while true; do
        echo -e "${YELLOW}=== LNMP 服务管理 ===${NC}"
        echo "1. 重启Nginx"
        echo "2. 重启MariaDB"
        echo "3. 重启PHP-FPM (选择版本)"
        echo "4. 重启Redis"
        echo "5. 重启管理面板"
        echo "6. 停止所有服务"
        echo "7. 启动所有服务"
        echo "8. 返回主菜单"
        read -p "请选择操作 [1-8]: " choice
        case $choice in
            1) systemctl restart nginx ;;
            2) systemctl restart mariadb ;;
            3) 
                echo "选择PHP版本:"
                echo "1. PHP 7.4"
                echo "2. PHP 8.0"
                echo "3. PHP 8.1"
                echo "4. PHP 8.2"
                read -p "请输入 [1-4]: " php_ver_choice
                case $php_ver_choice in
                    1) systemctl restart php7.4-fpm ;;
                    2) systemctl restart php8.0-fpm ;;
                    3) systemctl restart php8.1-fpm ;;
                    4) systemctl restart php8.2-fpm ;;
                    *) echo -e "${RED}无效选项${NC}" ;;
                esac ;;
            4) systemctl restart redis ;;
            5) systemctl restart lnmp_panel ;;
            6) systemctl stop nginx mariadb php*-fpm redis lnmp_panel ;;
            7) systemctl start nginx mariadb php*-fpm redis lnmp_panel ;;
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
        echo "3. 退出"
        read -p "请选择操作 [1-3]: " choice
        case $choice in
            1) install_lnmp ;;
            2) manage_services ;;
            3) echo -e "${GREEN}退出程序${NC}"; exit 0 ;;
            *) echo -e "${RED}无效选项${NC}" ;;
        esac
    done
}

# 运行主菜单
main_menu
