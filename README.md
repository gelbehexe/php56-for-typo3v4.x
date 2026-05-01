# php56-for-typo3v4.x

[![Build](https://github.com/gelbehexe/php56-for-typo3v4.x/actions/workflows/docker.yml/badge.svg)](https://github.com/gelbehexe/php56-for-typo3v4.x/actions/workflows/docker.yml)

A PHP 5.6 FPM Docker image for running legacy TYPO3 4.x installations that cannot be migrated to modern PHP versions.

Based on `php:5.6-fpm-stretch`.

## Included PHP extensions

- `gd` (with FreeType and JPEG support)
- `mysql`
- `mbstring`

## Additional packages

- GraphicsMagick
- Tidy (system binary)
- msmtp (for SMTP mail delivery)
- MySQL client

## PHP configuration

| Setting             | Value                              |
|---------------------|------------------------------------|
| `memory_limit`      | 512M                               |
| `max_execution_time`| 240                                |
| `error_reporting`   | `E_ALL & ~E_STRICT & ~E_DEPRECATED`|

## Environment variables

| Variable                       | Description                                                          |
|--------------------------------|----------------------------------------------------------------------|
| `APPLICATION_UID`              | UID for the `www-data` user (for matching host file permissions)     |
| `APPLICATION_GID`              | GID for the `www-data` group                                         |
| `PHP_DISPLAY_ERRORS`           | Set to `1` to enable `display_errors`                                |
| `MYSQL_HOST`                   | MySQL host                                                           |
| `MYSQL_USER`                   | MySQL user                                                           |
| `MYSQL_PASSWORD`               | MySQL password                                                       |
| `MYSQL_DATABASE`               | MySQL database name                                                  |
| `TYPO3_INITIAL_ADMIN_USERNAME` | Username for the initial admin user (default: `admin`)        |
| `TYPO3_INITIAL_ADMIN_PASSWORD` | If set, creates a TYPO3 backend admin user on first start            |
| `TYPO3_INITIAL_ADMIN_UID`      | UID for the initial admin user (default: `1`, set to `auto` for AI)  |
| `TYPO3_INITIAL_ADMIN_EMAIL`    | Email address for the initial admin user                             |
| `ENABLE_TYPO3_INSTALL_PERMANT` | Set to `1` to keep the TYPO3 Install Tool permanently enabled        |
| `SMTP_HOST`                    | SMTP server hostname                                                 |
| `SMTP_PORT`                    | SMTP server port                                                     |
| `SMTP_FROM`                    | Sender address for outgoing mail                                     |
| `SMTP_USER`                    | SMTP username                                                        |
| `SMTP_PASSWORD`                | SMTP password                                                        |

## Usage

```yaml
services:
  php:
    image: gelbehexe/php56-for-typo3v4.x:latest
    volumes:
      - ./webroot:/app
    environment:
      APPLICATION_UID: 1000
      APPLICATION_GID: 1000
      MYSQL_HOST: db
      MYSQL_USER: typo3
      MYSQL_PASSWORD: secret
      MYSQL_DATABASE: typo3
      SMTP_HOST: mailhog
      SMTP_PORT: 1025
      SMTP_FROM: noreply@example.com
      SMTP_USER: ""
      SMTP_PASSWORD: ""
      PHP_DISPLAY_ERRORS: 1
```
For information on how to build and test the image locally, please see [DEVELOPMENT.md](https://github.com/gelbehexe/php56-for-typo3v4.x/blob/main/DEVELOPMENT.md).
