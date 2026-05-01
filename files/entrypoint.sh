#!/bin/bash
set -e

create_typo3_admin() {
  if [ -z "${TYPO3_INITIAL_ADMIN_PASSWORD:-}" ]; then
    echo "INFO: TYPO3_INITIAL_ADMIN_PASSWORD not set, skipping admin creation."
    return 0
  fi

  local ADMIN_USER="${TYPO3_INITIAL_ADMIN_USERNAME:-admin}"
  local ADMIN_UID_VAR="${TYPO3_INITIAL_ADMIN_UID:-1}"
  local ADMIN_UID_VAL

  echo "Waiting for be_users table..."
  for i in $(seq 1 60); do
    if mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" \
        -e "SHOW TABLES LIKE 'be_users';" 2>/dev/null | grep -q be_users; then
      break
    fi
    if [ $i -eq 60 ]; then
      echo "ERROR: Table 'be_users' not found after 60 attempts. Check database initialization."
      return 1
    fi
    echo "  attempt $i/60, retrying..."
    sleep 2
  done

  EXISTS=$(mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" \
    -sN -e "SELECT COUNT(*) FROM be_users WHERE username='${ADMIN_USER}' AND deleted=0;")

  if [ "${EXISTS:-0}" -eq 0 ]; then
    # UID Logic
    if [ "$ADMIN_UID_VAR" = "auto" ]; then
        ADMIN_UID_VAL="NULL"
    else
        # Verify if UID is already taken
        UID_EXISTS=$(mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" \
            -sN -e "SELECT COUNT(*) FROM be_users WHERE uid='${ADMIN_UID_VAR}';" 2>/dev/null)
        if [ "${UID_EXISTS:-0}" -gt 0 ]; then
            echo "ERROR: Cannot create admin user '${ADMIN_USER}'. UID ${ADMIN_UID_VAR} is already taken."
            return 1
        fi
        ADMIN_UID_VAL="'${ADMIN_UID_VAR}'"
    fi

    echo "Creating admin user '${ADMIN_USER}'..."
    HASH=$(php -r "echo md5('${TYPO3_INITIAL_ADMIN_PASSWORD}');")
    TSTAMP=$(php -r "echo time();")
    if mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" <<SQL
INSERT INTO be_users (uid,pid,username,password,admin,disable,deleted,realName,email,TSconfig,tstamp,crdate)
VALUES (${ADMIN_UID_VAL},0,'${ADMIN_USER}','${HASH}',1,0,0,'Dev Admin','${TYPO3_INITIAL_ADMIN_EMAIL}','${TYPO3_INITIAL_ADMIN_OPTIONS}','${TSTAMP}','${TSTAMP}');
SQL
    then
      echo "SUCCESS: Admin user '${ADMIN_USER}' (UID: ${ADMIN_UID_VAR}) created."
    else
      echo "ERROR: Failed to create admin user."
      return 1
    fi
  else
    echo "INFO: Admin user '${ADMIN_USER}' already exists."
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

if [ -d /app/typo3temp ]; then
    chown -R www-data:www-data /app/typo3temp
fi

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
MAILER_LOGPIPE_PID=$!
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

trap 'kill $MAILER_LOGPIPE_PID $PHP_LOGPIPE_PID ${INSTALL_TOOL_PID:-} 2>/dev/null' EXIT TERM INT

echo "sendmail_path = /usr/bin/msmtp -C /etc/msmtprc -t" > /usr/local/etc/php/conf.d/mail.ini
echo "log_errors = On" > /usr/local/etc/php/conf.d/error-log.ini
echo "error_log = /tmp/php-logpipe" >> /usr/local/etc/php/conf.d/error-log.ini

echo "date.timezone = ${TZ:-UTC}" > /usr/local/etc/php/conf.d/timezone.ini
create_typo3_admin

exec docker-php-entrypoint "$@"