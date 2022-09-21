#!/bin/bash -ex
set -ex

function parseArgs()
{
   for change in "$@"; do
      name="${change%%=*}"
      value="${change#*=}"
      eval $name="$value"
   done
}

function installPonysay()
{
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2079EE53D4B33595B07BDA9FE1FFCE65CB95493
	echo "deb http://ppa.launchpad.net/vincent-c/ponysay/ubuntu xenial main" >> /etc/apt/sources.list
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get -y install ponysay fortune
}

function installSudo()
{
    apt-get install -y sudo
    echo "root:root" | chpasswd
}

function noPassword()
{
    local user=""
    local sudo=""
    parseArgs $@

    $sudo passwd -d $user #Delete a user's password
    cp /etc/sudoers /tmp/sudoers
    $sudo chmod 755 /tmp/sudoers
    echo "$user ALL=(ALL) NOPASSWD:ALL" >> /tmp/sudoers
    $sudo chmod 440 /tmp/sudoers
    $sudo chown 0:0 /tmp/sudoers
    $sudo mv -f /tmp/sudoers /etc/sudoers
}

function createUser()
{
    local user=""
    local uid=""
    local gid=""
    local sudo=""
    parseArgs $@

    if [[ "$uid" == "" && "$gid" == "" ]]; then
        $sudo useradd --system --create-home --home-dir /home/$user --shell /bin/bash --groups sudo,root $user
    else
        $sudo groupadd --gid $gid $user && true
        $sudo useradd --system --create-home --home-dir /home/$user --shell /bin/bash --gid $gid --groups sudo,root,$gid --uid $uid $user
    fi
}

function installMediaWiki()
{
	if [ ! -d "/var/www/html/wiki" ]; then
	pushd /tmp
	unzip mediawiki-1.38.2.zip
	sudo rm -fr mediawiki-1.38.2.zip
	mv mediawiki-1.38.2 /var/www/html/wiki
	popd
	fi
}

function configureSelfSignedCertificate()
{
    mkdir -p /tmp/certs
    pushd /tmp/certs
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout server.key -out server.crt -subj "/CN=osletek.com" -addext "subjectAltName=DNS:osletek.com,DNS:www.osletek.com,IP:127.0.0.1"
    #sudo cp server.crt /home/dev/.ssh/self-signed.crt
    #sudo cp server.key /home/dev/.ssh/self-signed.key
    #sudo service apache2 restart
    popd
}

function installNginx()
{
#https://www.theserverside.com/blog/Coffee-Talk-Java-News-Stories-and-Opinions/Nginx-PHP-FPM-config-example

	#usermod -a -G dev www-data
	add-apt-repository -y ppa:ondrej/php
	apt update -y
	apt install -y \
		nginx \
		php8.1-fpm \
		php8.1-bcmath \
		php8.1-bz2 \
		php8.1-cli \
		php8.1-curl \
		php8.1-dev \
		php8.1-fpm \
		php8.1-gd \
		php8.1-intl \
		php8.1-mbstring \
		php8.1-mongodb \
		php8.1-opcache \
		php8.1-sqlite3 \
		php8.1-xml \
		php8.1-zip \
		php-pear \

	configureSelfSignedCertificate
	mv -f /tmp/certs/server.crt /etc/ssl/certs/ssl-cert-snakeoil.pem;
	mv -f /tmp/certs/server.key /etc/ssl/private/ssl-cert-snakeoil.key;
	cp /tmp/etc.nginx.sites-available.default /etc/nginx/sites-available/default

# /usr/sbin/nginx
# /var/log/nginx/error.log
# sudo vi /etc/nginx/sites-available/default # root /var/www/html
# The default PHP configuration file is at /etc/php/#.#/fpm/php.ini
# to test configuration
# sudo /usr/sbin/nginx -t
# sudo service php8.1-fpm start
# sudo service nginx start

}

function configureSshServer()
{
    #to test, run: 
    #sudo /usr/sbin/sshd -d -p 2222
    #then in host machine: ssh oosman@localhost -p 2222

    sudo ssh-keygen -At rsa # -f /etc/ssh/ssh_host_rsa_key
    sudo ssh-keygen -At dsa # -f /etc/ssh/ssh_host_dsa_key
    sudo ssh-keygen -At ecdsa # -f /etc/ssh/ssh_host_ecdsa_key
    
    sudo cp /etc/ssh/sshd_config /tmp/
    sudo chown $USER:$USER /tmp/sshd_config
    sudo chmod 755 /tmp/sshd_config   
    echo "PasswordAuthentication yes" >> /tmp/sshd_config
    echo "PermitEmptyPasswords yes" >> /tmp/sshd_config
    sudo chmod 600 -R /etc/ssh/*
    sudo cp /tmp/sshd_config /etc/ssh/

    sudo cp /etc/group /tmp/
    sudo chown $USER:$USER /tmp/group
    sudo chmod 755 /tmp/group
    echo "sshd:*:27:" >> /tmp/group
    sudo chmod 600 /tmp/group
    sudo cp /tmp/group /etc/
 

    sudo cp /etc/passwd /tmp/
    sudo chown $USER:$USER /tmp/passwd
    sudo chmod 755 /tmp/passwd
    sudo mkdir -p /run/sshd
    echo "sshd:*:27:27:sshd privsep:/var/empty:/sbin/nologin" >> /tmp/passwd
    sudo chmod 600 /tmp/passwd
    sudo cp /tmp/passwd /etc/

    sudo service ssh start
}

function welcome()
{
   #sudo service ssh start
   fortune>/tmp/welcome
   echo \"\">>/tmp/welcome
   echo \"Welcome! You are inside a Docker container.\">>/tmp/welcome
   cat /tmp/welcome|ponysay
}

function getGitUser()
{
    parseArgs $@
    git_user="$(git config --get user.name)"
    if [ "$git_user" == "" ]; then
        echo "no git user"
        exit -1
    fi
    git_user="${git_user// /_}" #replace space with _
}

function getGitEmail()
{
    parseArgs $@
    git_user="$(git config --get user.email)"
    if [ "$git_email" == "" ]; then
    	echo "no git email"
    	exit -1
    fi
    git_email="${git_email// /_}" #replace space with _
}

function dockerParams()
{
    local dockerimage
    local container_name
    local interactive_terminal
    parseArgs $@

    if [ "$container_name" == "" ]; then 
        local container_name="jambamamba"
    fi

    if [ "$interactive_terminal" == "yes" ]; then 
        interactive_terminal="-it"; 
    else 
        interactive_terminal=""; 
    fi

#    local git_user=""
#    getGitUser git_user=""
#    local git_email=""
#    getGitEmail git_email=""
    
    local mem_gb=$(free -h | grep Mem | awk '{print $2}')
    local mem_gb=${mem_gb%Gi}
    local script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    if [ "$USER" == "null" ] || [ "$USER" == "" ]; then
        USER="dev"
    fi

    local params=(
    --rm 
    -e DOCKERUSER=$USER 
    -e USER=$USER
    -e UID=$(id -u) 
    -e GID=$(id -g)
    -e DISPLAY=$DISPLAY
#    -e GITUSER="$git_user"
#    -e GITEMAIL="$git_email"
    --user $(id -u):$(id -g)
    --workdir="/home/$USER"
    -p 443:443
    -v /home/$USER:/home/$USER
    -v /datadisk/nextgen/www/:/var/www/html
    -v /datadisk/nextgen/www-db/:/var/www/data
    -v $script_dir/tmp/run.sh:/tmp/run.sh
    -v $script_dir/tmp/etc.passwd:/etc/passwd
    -v $script_dir/tmp/etc.group:/etc/group
    -v $script_dir/tmp/etc.shadow:/etc/shadow
    -v /tmp/.X11-unix:/tmp/.X11-unix
    -v $HOME/.Xauthority:/home/dev/.Xauthority
    -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket
    -v /run/user/1000:/run/user/1000
    #--net=host #host same network as host, not needed here 
    --memory="$mem_gb"g --memory-swap="$mem_gb"g
    --name $container_name
    --cap-add=SYS_PTRACE
    --privileged -v /dev/bus/usb:/dev/bus/usbs
    $interactive_terminal 
    $dockerimage
    )
    echo ${params[@]}
}


