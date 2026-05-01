#!/bin/bash
set -e

create_typo3_admin() {
  if [ -z "${TYPO3_INITIAL_ADMIN_PASSWORD:-}" ]; then
    echo "INFO: TYPO3_INITIAL_ADMIN_PASSWORD not set, skipping admin creation."
    return 0
  fi

  echo "Waiting for be_users table..."
  for i in $(seq 1 60); do
    if mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" \
        -e "SHOW TABLES LIKE 'be_users';" 2>/dev/null | grep -q be_users; then
      break
    fi
    echo "  attempt $i/60, retrying..."
    sleep 2
  done

  EXISTS=$(mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" \
    -sN -e "SELECT COUNT(*) FROM be_users WHERE username='admin' AND deleted=0;" 2>/dev/null)

  if [ "${EXISTS:-0}" -eq 0 ]; then
    HASH="$(php -r "echo md5('${TYPO3_INITIAL_ADMIN_PASSWORD}');")"
    TSTAMP="$(php -r "echo time();")"
    mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" 2>/dev/null <<SQL
INSERT INTO be_users (uid,pid,username,password,admin,disable,deleted,realName,email,TSconfig,tstamp,crdate)
VALUES (1,0,'admin','${HASH}',1,0,0,'Dev Admin','${TYPO3_INITIAL_ADMIN_EMAIL}','${TYPO3_INITIAL_ADMIN_OPTIONS}','${TSTAMP}','${TSTAMP}');
SQL
    echo "Admin user created."
  else
    echo "Admin user already exists."
  fi
}

if [ -n "$APPLICATION_UID" ] && [ "$APPLICATION_UID" != "$(id -u www-data)" ]; then
    echo "Updating www-data UID to $APPLICATION_UID..."
    usermod -u "$APPLICATION_UID" www-data
fi

if [ -n "$APPLICATION_GID" ] && [ "$APPLICATION_GID" != "$(id -g www-data)" ]; then
    echo "Updating www-data GID to $APPLICATION_GID..."
    groupmod -g "$APPLICATION_GID" www-data
fi

chown -R www-data:www-data /app/typo3temp

if [ "${PHP_DISPLAY_ERRORS:-0}" = "1" ]; then
    echo "display_errors = On" > /usr/local/etc/php/conf.d/display-errors.ini
else
    echo "display_errors = Off" > /usr/local/etc/php/conf.d/display-errors.ini
fi

sed \
    -e "s|SMTP_HOST|${SMTP_HOST}|g" \
    -e "s|SMTP_PORT|${SMTP_PORT}|g" \
    -e "s|SMTP_FROM|${SMTP_FROM}|g" \
    -e "s|SMTP_USER|${SMTP_USER}|g" \
    -e "s|SMTP_PASSWORD|${SMTP_PASSWORD}|g" \
    /etc/msmtprc.template > /etc/msmtprc
chown www-data:www-data /etc/msmtprc
chmod 600 /etc/msmtprc

rm -f /tmp/msmtp-logpipe
mkfifo -m 620 /tmp/msmtp-logpipe
chown root:www-data /tmp/msmtp-logpipe
cat < /tmp/msmtp-logpipe 1>&2 &
LOGPIPE_PID=$!
exec 3>/tmp/msmtp-logpipe

rm -f /tmp/php-logpipe
mkfifo -m 620 /tmp/php-logpipe
chown root:www-data /tmp/php-logpipe
cat < /tmp/php-logpipe 1>&2 &
PHP_LOGPIPE_PID=$!

if [ "${ENABLE_TYPO3_INSTALL_PERMANT:-0}" = "1" ]; then
  (while true; do touch /app/typo3conf/ENABLE_INSTALL_TOOL; sleep 3600; done) &
  INSTALL_TOOL_PID=$!
fi

trap 'kill $LOGPIPE_PID $PHP_LOGPIPE_PID ${INSTALL_TOOL_PID:-} 2>/dev/null' EXIT TERM INT

echo "sendmail_path = /usr/bin/msmtp -C /etc/msmtprc -t" > /usr/local/etc/php/conf.d/mail.ini
echo "log_errors = On" > /usr/local/etc/php/conf.d/error-log.ini
echo "error_log = /tmp/php-logpipe" >> /usr/local/etc/php/conf.d/error-log.ini

echo "date.timezone = ${TZ:-UTC}" > /usr/local/etc/php/conf.d/timezone.ini
create_typo3_admin

exec docker-php-entrypoint "$@"