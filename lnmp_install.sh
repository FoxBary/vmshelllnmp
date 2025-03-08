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
    VERSION_CODENAME=${VERSION_CODENAME:-$VERSION_ID}
else
    echo -e "${RED}无法检测操作系统${NC}"
    exit 1
fi

# 检查网络并尝试备选下载地址的通用函数
try_download() {
    local url=$1
    local dest=$2
    local mirrors=(
        "$url"                                  # 主地址
        "https://mirrors.tuna.tsinghua.edu.cn/$url"      # 清华大学镜像
        "https://mirrors.aliyun.com/$url"                # 阿里云镜像
        "https://mirrors.tencent.com/$url"               # 腾讯云镜像
        "https://mirrors.cloud.tencent.com/$url"         # 腾讯云备用镜像
    )
    for mirror in "${mirrors[@]}"; do
        echo -e "${YELLOW}尝试从 $mirror 下载...${NC}"
        if curl -fsSL "$mirror" -o "$dest"; then
            echo -e "${GREEN}从 $mirror 下载成功${NC}"
            return 0
        fi
        echo -e "${RED}从 $mirror 下载失败${NC}"
    done
    echo -e "${RED}所有备选地址下载失败，请检查网络${NC}"
    exit 1
}

# 安装依赖函数（修正 Debian 的源问题）
install_dependencies() {
    echo -e "${YELLOW}正在更新系统并安装基本依赖...${NC}"
    case $OS in
        ubuntu)
            apt update -y && apt upgrade -y || { echo -e "${RED}更新失败${NC}"; exit 1; }
            apt install -y unzip software-properties-common || { echo -e "${RED}依赖安装失败${NC}"; exit 1; }
            ;;
        debian)
            # 清理可能残留的 Ubuntu PPA
            rm -f /etc/apt/sources.list.d/ondrej-*.list
            apt update -y && apt upgrade -y || { echo -e "${RED}更新失败${NC}"; exit 1; }
            apt install -y unzip software-properties-common || { echo -e "${RED}依赖安装失败${NC}"; exit 1; }
            ;;
        centos|rhel)
            yum update -y || { echo -e "${RED}更新失败${NC}"; exit 1; }
            yum install -y epel-release || { echo -e "${RED}依赖安装失败${NC}"; exit 1; }
            ;;
        fedora)
            dnf update -y || { echo -e "${RED}更新失败${NC}"; exit 1; }
            dnf install -y unzip || { echo -e "${RED}依赖安装失败${NC}"; exit 1; }
            ;;
        *)
            echo -e "${RED}不支持的操作系统: $OS${NC}"
            exit 1
            ;;
    esac
}

# 检查并安装Node.js和npm（使用真实镜像）
install_nodejs_npm() {
    echo -e "${YELLOW}检查并安装Node.js和npm...${NC}"
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        echo -e "${YELLOW}Node.js或npm未安装，正在安装...${NC}"
        case $OS in
            ubuntu|debian)
                try_download "https://deb.nodesource.com/setup_18.x" "/tmp/setup_node.sh"
                bash /tmp/setup_node.sh
                apt install -y nodejs || { echo -e "${RED}Node.js安装失败${NC}"; exit 1; }
                ;;
            centos|rhel|fedora)
                try_download "https://rpm.nodesource.com/setup_18.x" "/tmp/setup_node.sh"
                bash /tmp/setup_node.sh
                yum install -y nodejs || dnf install -y nodejs || { echo -e "${RED}Node.js安装失败${NC}"; exit 1; }
                ;;
            *)
                echo -e "${RED}不支持的操作系统: $OS${NC}"
                exit 1
                ;;
        esac
    else
        echo -e "${GREEN}Node.js和npm已安装${NC}"
    fi
    node -v && npm -v
}

# 安装MySQL（使用真实镜像）
install_mariadb() {
    echo -e "${YELLOW}=== 选择MySQL版本 ===${NC}"
    echo "1. MySQL 5.7"
    echo "2. MySQL 8.2"
    read -p "请选择MySQL版本 [1-2]: " db_choice

    case $OS in
        ubuntu|debian)
            case $db_choice in
                1) 
                    try_download "https://dev.mysql.com/get/mysql-apt-config_0.8.23-1_all.deb" "/tmp/mysql-apt-config.deb"
                    dpkg -i /tmp/mysql-apt-config.deb
                    apt update -y
                    apt install -y mysql-server=5.7.* ;;
                2) 
                    try_download "https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb" "/tmp/mysql-apt-config.deb"
                    dpkg -i /tmp/mysql-apt-config.deb
                    apt update -y
                    apt install -y mysql-server ;;
                *) echo -e "${RED}无效选项，使用MySQL 8.2${NC}"; 
                    try_download "https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb" "/tmp/mysql-apt-config.deb"
                    dpkg -i /tmp/mysql-apt-config.deb
                    apt update -y
                    apt install -y mysql-server ;;
            esac
            systemctl enable mysql
            systemctl start mysql
            ;;
        centos|rhel|fedora)
            case $db_choice in
                1) 
                    try_download "https://dev.mysql.com/get/mysql57-community-release-el$(rpm -E %rhel)-11.noarch.rpm" "/tmp/mysql57.rpm"
                    yum install -y /tmp/mysql57.rpm || dnf install -y /tmp/mysql57.rpm
                    yum install -y mysql-community-server-5.7.* || dnf install -y mysql-community-server-5.7.*
                    ;;
                2) 
                    try_download "https://dev.mysql.com/get/mysql80-community-release-el$(rpm -E %rhel)-1.noarch.rpm" "/tmp/mysql80.rpm"
                    yum install -y /tmp/mysql80.rpm || dnf install -y /tmp/mysql80.rpm
                    yum install -y mysql-community-server || dnf install -y mysql-community-server
                    ;;
                *) echo -e "${RED}无效选项，使用MySQL 8.2${NC}"; 
                    try_download "https://dev.mysql.com/get/mysql80-community-release-el$(rpm -E %rhel)-1.noarch.rpm" "/tmp/mysql80.rpm"
                    yum install -y /tmp/mysql80.rpm || dnf install -y /tmp/mysql80.rpm
                    yum install -y mysql-community-server || dnf install -y mysql-community-server
                    ;;
            esac
            systemctl enable mysqld
            systemctl start mysqld
            ;;
        *)
            echo -e "${RED}不支持的操作系统: $OS${NC}"
            exit 1
            ;;
    esac

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
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
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

# 安装PHP（使用真实镜像）
install_php() {
    echo -e "${YELLOW}=== 选择PHP版本 ===${NC}"
    echo "1. PHP 7.4"
    echo "2. PHP 8.1"
    read -p "请选择PHP版本 [1-2]: " php_choice
    case $OS in
        ubuntu)
            apt install -y software-properties-common
            add-apt-repository -y ppa:ondrej/php
            apt update -y
            case $php_choice in
                1) PHP_VER="7.4" ;;
                2) PHP_VER="8.1" ;;
                *) echo -e "${RED}无效选项，使用PHP 8.1${NC}"; PHP_VER="8.1" ;;
            esac
            apt install -y php${PHP_VER} php${PHP_VER}-fpm php${PHP_VER}-mysql php${PHP_VER}-cli php${PHP_VER}-mbstring php${PHP_VER}-zip php${PHP_VER}-gd
            systemctl enable php${PHP_VER}-fpm
            systemctl start php${PHP_VER}-fpm
            ;;
        debian)
            # 使用 packages.sury.org/php 源并提供真实镜像
            local php_mirrors=(
                "https://packages.sury.org/php/"
                "https://mirrors.tuna.tsinghua.edu.cn/debian-php/"
                "https://mirrors.aliyun.com/debian-php/"
                "https://mirrors.tencent.com/debian-php/"
                "https://mirrors.cloud.tencent.com/debian-php/"
            )
            for mirror in "${php_mirrors[@]}"; do
                echo -e "${YELLOW}尝试添加PHP源: $mirror${NC}"
                echo "deb $mirror ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/php.list
                try_download "${mirror}apt.gpg" "/tmp/php.gpg"
                apt-key add /tmp/php.gpg
                if apt update -y; then
                    echo -e "${GREEN}PHP源 $mirror 添加成功${NC}"
                    break
                fi
                echo -e "${RED}PHP源 $mirror 添加失败，尝试下一个${NC}"
            done
            [ $? -ne 0 ] && { echo -e "${RED}所有PHP源添加失败${NC}"; exit 1; }
            case $php_choice in
                1) PHP_VER="7.4" ;;
                2) PHP_VER="8.1" ;;
                *) echo -e "${RED}无效选项，使用PHP 8.1${NC}"; PHP_VER="8.1" ;;
            esac
            apt install -y php${PHP_VER} php${PHP_VER}-fpm php${PHP_VER}-mysql php${PHP_VER}-cli php${PHP_VER}-mbstring php${PHP_VER}-zip php${PHP_VER}-gd
            systemctl enable php${PHP_VER}-fpm
            systemctl start php${PHP_VER}-fpm
            ;;
        centos|rhel)
            local remi_mirrors=(
                "https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm"
                "https://mirrors.tuna.tsinghua.edu.cn/remi/enterprise/remi-release-$(rpm -E %rhel).rpm"
                "https://mirrors.aliyun.com/remi/enterprise/remi-release-$(rpm -E %rhel).rpm"
                "https://mirrors.tencent.com/remi/enterprise/remi-release-$(rpm -E %rhel).rpm"
                "https://mirrors.cloud.tencent.com/remi/enterprise/remi-release-$(rpm -E %rhel).rpm"
            )
            for mirror in "${remi_mirrors[@]}"; do
                echo -e "${YELLOW}尝试下载Remi源: $mirror${NC}"
                if try_download "$mirror" "/tmp/remi-release.rpm"; then
                    yum install -y /tmp/remi-release.rpm
                    break
                fi
            done
            [ $? -ne 0 ] && { echo -e "${RED}所有Remi源下载失败${NC}"; exit 1; }
            yum module reset php -y
            case $php_choice in
                1) yum module enable php:remi-7.4 -y; PHP_VER="7.4" ;;
                2) yum module enable php:remi-8.1 -y; PHP_VER="8.1" ;;
                *) echo -e "${RED}无效选项，使用PHP 8.1${NC}"; yum module enable php:remi-8.1 -y; PHP_VER="8.1" ;;
            esac
            yum install -y php php-fpm php-mysqlnd php-cli php-mbstring php-zip php-gd
            systemctl enable php-fpm
            systemctl start php-fpm
            ;;
        fedora)
            dnf module reset php -y
            case $php_choice in
                1) dnf module enable php:7.4 -y; PHP_VER="7.4" ;;
                2) dnf module enable php:8.1 -y; PHP_VER="8.1" ;;
                *) echo -e "${RED}无效选项，使用PHP 8.1${NC}"; dnf module enable php:8.1 -y; PHP_VER="8.1" ;;
            esac
            dnf install -y php php-fpm php-mysqlnd php-cli php-mbstring php-zip php-gd
            systemctl enable php-fpm
            systemctl start php-fpm
            ;;
        *)
            echo -e "${RED}不支持的操作系统: $OS${NC}"
            exit 1
            ;;
    esac
    echo "$PHP_VER"
}

# 其余函数保持不变，完整脚本基于之前版本
