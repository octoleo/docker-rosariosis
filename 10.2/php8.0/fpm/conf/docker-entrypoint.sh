#!/bin/bash

set -e

if [ -n "$POSTGRES_PASSWORD_FILE" ] && [ -f "$POSTGRES_PASSWORD_FILE" ]; then
        POSTGRES_PASSWORD=$(cat "$POSTGRES_PASSWORD_FILE")
fi

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
        uid="$(id -u)"
        gid="$(id -g)"
        if [ "$uid" = '0' ]; then
                case "$1" in
                apache2*)
                        user="${APACHE_RUN_USER:-www-data}"
                        group="${APACHE_RUN_GROUP:-www-data}"

                        # strip off any '#' symbol ('#1000' is valid syntax for Apache)
                        pound='#'
                        user="${user#$pound}"
                        group="${group#$pound}"

                        # set user if not exist
                        if ! id "$user" &>/dev/null; then
                                # get the user name
                                : "${USER_NAME:=www-data}"
                                # change the user name
                                [[ "$USER_NAME" != "www-data" ]] &&
                                        usermod -l "$USER_NAME" www-data &&
                                        groupmod -n "$USER_NAME" www-data
                                # update the user ID
                                groupmod -o -g "$user" "$USER_NAME"
                                # update the user-group ID
                                usermod -o -u "$group" "$USER_NAME"
                        fi
                        ;;
                *) # php-fpm
                        user='www-data'
                        group='www-data'
                        ;;
                esac
        else
                user="$uid"
                group="$gid"
        fi

        if [ -n "$POSTGRES_PORT" ]; then
                if [ -z "$POSTGRES_HOST" ]; then
                        POSTGRES_HOST='postgres'
                else
                        echo >&2 "warning: both POSTGRES_HOST and POSTGRES_PORT found"
                        echo >&2 "  Connecting to POSTGRES_HOST ($POSTGRES_HOST)"
                        echo >&2 "  instead of the linked postgres container"
                fi
        fi

        if [ -z "$POSTGRES_HOST" ]; then
                echo >&2 "error: missing POSTGRES_HOST and POSTGRES_PORT environment variables"
                echo >&2 "  Did you forget to --link some_postgres_container:postgres or set an external db"
                echo >&2 "  with -e POSTGRES_HOST=hostname:port?"
                exit 1
        fi

        # If the DB user is 'root' then use the MySQL root password env var
        : "${POSTGRES_USER:=root}"
        if [ "$POSTGRES_USER" = 'root' ]; then
                : ${POSTGRES_PASSWORD:=$POSTGRES_ROOT_PASSWORD}
        fi
        : "${POSTGRES_DB:=rosariosis}"

        if [ -z "$POSTGRES_PASSWORD" ] && [ "$POSTGRES_PASSWORD_ALLOW_EMPTY" != 'yes' ]; then
                echo >&2 "error: missing required POSTGRES_PASSWORD environment variable"
                echo >&2 "  Did you forget to -e POSTGRES_PASSWORD=... ?"
                echo >&2
                echo >&2 "  (Also of interest might be POSTGRES_USER and POSTGRES_DB.)"
                exit 1
        fi

        if [ ! -e index.php ]; then
                # if the directory exists and Rosariosis doesn't appear to be installed AND the permissions of it are root:root, let's chown it (likely a Docker-created directory)
                if [ "$uid" = '0' ] && [ "$(stat -c '%u:%g' .)" = '0:0' ]; then
                        chown "$user:$group" .
                fi

                echo >&2 "Rosariosis not found in $PWD - copying now..."
                if [ "$(ls -A)" ]; then
                        echo >&2 "WARNING: $PWD is not empty - press Ctrl+C now if this is an error!"
                        (
                                set -x
                                ls -A
                                sleep 10
                        )
                fi
                # use full commands
                # for clearer intent
                sourceTarArgs=(
                        --create
                        --file -
                        --directory /usr/src/rosariosis
                        --one-file-system
                        --owner "$user" --group "$group"
                )
                targetTarArgs=(
                        --extract
                        --file -
                )
                if [ "$uid" != '0' ]; then
                        # avoid "tar: .: Cannot utime: Operation not permitted" and "tar: .: Cannot change mode to rwxr-xr-x: Operation not permitted"
                        targetTarArgs+=(--no-overwrite-dir)
                fi

                tar "${sourceTarArgs[@]}" . | tar "${targetTarArgs[@]}"

                if [ ! -e .htaccess ] && [ -f htaccess.txt ]; then
                        # NOTE: The "Indexes" option is disabled in the php:apache base image so remove it as we enable .htaccess
                        sed -r 's/^(Options -Indexes.*)$/#\1/' htaccess.txt >.htaccess
                        chown "$user":"$group" .htaccess
                fi

                echo >&2 "Complete! Rosariosis has been successfully copied to $PWD"
        fi

        echo >&2 "========================================================================"
        echo >&2
        echo >&2 "This server is now configured to run Rosariosis!"
        echo >&2
        echo >&2 "NOTE: You will need your database server address, database name,"
        echo >&2 "and database user credentials to install Rosariosis."
        echo >&2
        echo >&2 "========================================================================"
fi

exec "$@"
