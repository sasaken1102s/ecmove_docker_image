#!/bin/bash

set -e

date=$(date +%Y-%m-%d_%H-%M-%S)

remove=()

if [ "$#" -ne 3 ]; then
    echo "Arguments must be three"
    echo "Example: ecmove push staging td"
    exit
fi

if [ "$1" = "push" ] || [ "$1" = "pull" ]; then
    echo "$1"
else
    echo "First argument must be 'push' or 'pull'"
    exit
fi

dump_local_db() {
    echo ""
    echo "===========Dumping local database...=========="
    echo ""
    mkdir -p /root/backup/local
    mysqldump --skip-column-statistics -h mysql -u root -proot eccubedb >/root/backup/local/"$date".sql
    zip /root/backup/local/local_db_"$date" /root/backup/local/"$date".sql
    remove+=("/root/backup/local/$date.sql")
    echo ""
    echo "==========Dumped local database successfully!=========="
    echo ""
}

dump_local_eccube() {
    if [ "$ECMOVE_BACKUP_ECCUBE" = "true" ]; then
        echo ""
        echo "==========Dumping local ec-cube...=========="
        mkdir -p /root/backup/local
        zip -r /root/backup/local/local_eccube_"$date" /var/www/html/app /var/www/html/html /var/www/html/vendor /var/www/html/composer.json /var/www/html/composer.lock
        echo "==========Dumped local ec-cube successfully!=========="
        echo ""
    else
        echo ""
        echo "==========Ignore dumping local ec-cube=========="
        echo ""
    fi
}

dump_remote_db() {
    echo ""
    echo "==========Dumping $1 database...=========="
    echo ""
    mkdir -p /root/backup/"$1"
    host=$(eval echo '$'$1'_DB_HOST')
    user=$(eval echo '$'$1'_DB_USER')
    pass=$(eval echo '$'$1'_DB_PASSWORD')
    dbname=$(eval echo '$'$1'_DB_NAME')
    saveloca=$(eval echo '$'$1'_DIR_PATH')

    eval ssh '$'$1'_SSH_USER'@'$'$1'_SSH_HOST' "mysqldump --no-tablespaces -h $host -u $user -p$pass $dbname \>$saveloca/$date.sql"
    eval rsync -ahv '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/$date.sql /root/backup/"$1"/
    eval ssh '$'$1'_SSH_USER'@'$'$1'_SSH_HOST' "rm $saveloca/$date.sql"
    zip /root/backup/"$1"/"$1"_db_"$date" /root/backup/"$1"/$date.sql
    remove+=("/root/backup/$1/$date.sql")
    echo ""
    echo "==========Dumped $1 database successfully!=========="
    echo ""
}

dump_remote_eccube() {
    if [ "$ECMOVE_BACKUP_ECCUBE" = "true" ]; then
        echo ""
        echo "==========Dumping $1 ec-cube...=========="
        mkdir -p /root/backup/"$1"
        eval rsync -ahv '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/app /root/backup/"$1"/
        eval rsync -ahv '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/html /root/backup/"$1"/
        eval rsync -ahv '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/vendor /root/backup/"$1"/
        eval rsync -ahv '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/composer.json /root/backup/"$1"/composer.json
        eval rsync -ahv '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/composer.lock /root/backup/"$1"/composer.lock
        zip -r /root/backup/"$1"/"$1"_eccube_"$date" /root/backup/"$1"/app /root/backup/"$1"/html /root/backup/"$1"/vendor /root/backup/"$1"/composer.json /root/backup/"$1"/composer.lock
        remove+=("/root/backup/$1/app")
        remove+=("/root/backup/$1/html")
        remove+=("/root/backup/$1/vendor")
        remove+=("/root/backup/$1/composer.json")
        remove+=("/root/backup/$1/composer.lock")
        echo "==========Dumped $1 ec-cube successfully!=========="
        echo ""
    else
        echo ""
        echo "==========Ignore dumping $1 ec-cube=========="
        echo ""
    fi
}

clean() {
    echo ""
    for i in "${remove[@]}"; do
        rm -rfv $i
    done
}

push_data() {
    dump_local_db
    dump_local_eccube
    dump_remote_db $1
    dump_remote_eccube $1

    if [[ "$2" == *d* ]]; then
        echo ""
        echo "==========Pushing database...=========="
        echo ""
        eval rsync -ahv /root/backup/local/"$date".sql '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/

        host=$(eval echo '$'$1'_DB_HOST')
        user=$(eval echo '$'$1'_DB_USER')
        pass=$(eval echo '$'$1'_DB_PASSWORD')
        dbname=$(eval echo '$'$1'_DB_NAME')
        saveloca=$(eval echo '$'$1'_DIR_PATH')

        eval ssh '$'$1'_SSH_USER'@'$'$1'_SSH_HOST' "mysql -h $host -u $user -p$pass $dbname \<$saveloca/$date.sql"
        eval ssh '$'$1'_SSH_USER'@'$'$1'_SSH_HOST' "rm $saveloca/$date.sql"
    fi

    if [[ "$2" == *t* ]]; then
        echo ""
        echo "==========Pushing theme...=========="
        echo ""
        eval rsync -ahv --delete /var/www/html/app/ '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/app/
        eval rsync -ahv --delete /var/www/html/html/ '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/html/
        eval rsync -ahvz --delete /var/www/html/vendor/ '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/vendor/
        eval rsync -ahv --delete /var/www/html/composer.json '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/composer.json
        eval rsync -ahv --delete /var/www/html/composer.lock '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/composer.lock

        saveloca=$(eval echo '$'$1'_DIR_PATH')

        eval ssh '$'$1'_SSH_USER'@'$'$1'_SSH_HOST' "rm -rfv $saveloca/var/cache/*"
    fi

    clean
}

pull_data() {
    dump_local_db
    dump_local_eccube
    dump_remote_db $1
    dump_remote_eccube $1

    if [[ "$2" == *d* ]]; then
        echo "==========Pulling database...=========="
        eval mysql -h mysql -u root -proot eccubedb </root/backup/"$1"/"$date".sql
    fi

    if [[ "$2" == *t* ]]; then
        echo "==========Pulling theme...=========="
        eval rsync -ahv --delete '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/app/ /var/www/html/app/
        eval rsync -ahv --delete '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/html/ /var/www/html/html/
        eval rsync -ahvz --delete '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/vendor/ /var/www/html/vendor/
        eval rsync -ahv --delete '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/composer.json /var/www/html/composer.json
        eval rsync -ahv --delete '$'"$1"'_SSH_USER'@'$'"$1"'_SSH_HOST':'$'"$1"'_DIR_PATH'/composer.lock /var/www/html/composer.lock
    fi

    clean
}

if [ "$1" = "push" ]; then
    push_data $2 $3
elif [ "$1" = "pull" ]; then
    pull_data $2 $3
fi
