#!/bin/bash
chown 999:999 /usr/local/lsws/conf -R
cd /var/www/vhosts/localhost/html
if [ ! -f "./wp-config.php" ]; then
	# su -s /bin/bash www-data -c
    COUNTER=0
	until [ "$(curl -v mysql:3306 2>&1 | grep native)" ];
	do
	    echo "Counter: ${COUNTER}"
		COUNTER=$((COUNTER+1))
		if [ ${COUNTER} = 10 ]; then
			echo '--- MySQL is starting, please wait... ---'
		elif [ ${COUNTER} = 60 ]; then	
		    echo '--- MySQL is timeout, exit! ---'
			exit 1
		fi
		sleep 1
	done
	wp core download \
	    --allow-root \
	    --force
    wp core config \
	    --dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${MYSQL_PASSWORD}" \
		--dbhost=mysql \
		--dbprefix="${WP_DB_PREFIX}" \
		--allow-root \
		--force
	wp core install \
	    --title="${WP_TITLE}" \
		--url="${DOMAIN}" \
		--admin_user="${ADMIN_USERNAME}" \
		--admin_email="${ADMIN_EMAIL}" \
		--admin_password="${ADMIN_PASSWORD}" \
		--skip-email \
		--allow-root 
	wp plugin install litespeed-cache \
	    --activate \
	    --allow-root
	first_www_uid=$(stat -c "%u" /var/www/vhosts/localhost)
	first_www_gid=$(stat -c "%g" /var/www/vhosts/localhost)
	chown $first_www_uid:$first_www_gid /var/www/vhosts/localhost -R

fi

www_uid=$(stat -c "%u" /var/www/vhosts/localhost)
if [ ${www_uid} -eq 0 ]; then
    #echo "./sites/localhost is owned by root, auto changing ownership of ./sites/localhost to uid 1000"
    chown 1000:1000 /var/www/vhosts/localhost -R
fi

echo "WordPress installation finished."
exec "$@"