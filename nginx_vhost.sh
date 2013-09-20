#!/usr/bin/env bash
#
# Nginx - new server block
# http://rosehosting.com
# sudo ./nginx_vhost.sh <domain_name>

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green
die() { echo -e '\e[1;31m'$1'\e[m'; exit 1; }

# Variables
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
WEB_DIR='/var/www'
WEB_USER='www-data'

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
[ $# != "1" ] && die "Usage: $(basename $0) domainName"

# Create nginx config file
cat > $NGINX_AVAILABLE_VHOSTS/$1 <<EOF
server {
  server_name $1;
  listen 80;
  root $WEB_DIR/$1/public_html;
  access_log $WEB_DIR/$1/logs/access.log;
  error_log $WEB_DIR/$1/logs/error.log;
  index index.html index.php;
  location / {
    try_files \$uri \$uri/ @rewrites;
  }
  location @rewrites {
    rewrite ^ /index.php last;
  }
  location ~* \.(jpg|jpeg|gif|css|png|js|ico|html)$ {
    access_log off;
    expires max;
  }
  location ~ /\.ht {
    deny  all;
  }
  location ~ \.php {
    fastcgi_index index.php;
    fastcgi_split_path_info ^(.+\.php)(.*)$;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  }
}
EOF

# Creating {public,log} directories
mkdir -p $WEB_DIR/$1/{public_html,logs}

# Creating index.html file
cat > $WEB_DIR/$1/public_html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
        <title>$1</title>
        <meta charset="utf-8" />
</head>
<body class="container">
        <header><h1>$1<h1></header>
        <div id="wrapper"><p>Hello World</p></div>
        <footer>© $(date +%Y)</footer>
</body>
</html>
EOF

# Changing permissions
chown -R $WEB_USER:$WEB_USER $WEB_DIR/$1

# Enable site by creating symbolic link
ln -s $NGINX_AVAILABLE_VHOSTS/$1 $NGINX_ENABLED_VHOSTS/$1

# Restart
echo "Do you wish to restart nginx?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) /etc/init.d/nginx restart ; break;;
        No ) exit;;
    esac
done

ok "Site Created for $1"