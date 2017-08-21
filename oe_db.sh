#!/usr/bin/env bash

echo "DBUS (c) ownego"
if [[ -e config.json ]]
then
    tput setaf 2
    echo "Configuration file found."
    tput setaf 7
else
    tput setaf 1
    echo "No configuration file found!"
    tput setaf 7
    echo "Creating a new one..."
    touch config.json
    printf "[]" > config.json
    tput setaf 2
    echo "Done!"
    tput setaf 7
fi

start() {
    echo "What do you want to do?"
    echo "1. Add/Remove database connection"
    echo "2. Exit"
    read opt
    case $opt in
        1)  db_modify
            ;;
        2)  echo "Bye!"
            exit
            ;;
    esac
}

# contains(string, substring)
#
# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1.
contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

# db_input()
#
# Write database information to config file.
db_input() {
    config=$(jq '.[]' config.json)
    count=$(jq '. | length' config.json)
    echo "Database name: $1"
    read -p "Database username: " db_uname
    read -s -p "Database password: " db_password
    echo ""
    read -p "Database backup cycle (days): " db_cycle
    read -p "Database backup directory: " db_dir
    sed -i 's/]//g' config.json
    if [[ $count -gt 0 ]]
    then
        printf "," >> config.json
    fi
    jq -n "{\"db_name\": \"$1\", \"db_uname\": \"$db_uname\", \"db_password\": \"$db_password\", \"db_cycle\": \"$db_cycle\", \"db_dir\": \"$db_dir\"}" >> config.json
    echo "]" >> config.json
    jq '.' config.json
    start
}

# db_backup_one(db_name, db_user, db_password, db_cycle, db_dir)
#
# Run backup progress for one specific database.
db_backup_one() {
    FILE_LAST_MONTH=$5/$1_backup.sql.`date --date="$4 days ago" +%Y_%m_%d_%H_%M`.gz
    FILE=$5/$1_backup.sql.`date +%Y_%m_%d_%H_%M`
    rm -rf ${FILE_LAST_MONTH}
    mysqldump --opt --user=$2 --password=$3 $1 > ${FILE}
    gzip $FILE
    tput setaf 2
    echo "Backed up $1 at $FILE."
    tput setaf 7
}

# db_backup_all()
#
# Execute backup progress for all database in config file.
db_backup_all() {
    count=$(jq '. | length' config.json)
    for ((i=0; i<=count-1; i++));
    do
        DB_NAME=$(jq -r --arg i "$i" '.[$i | tonumber].db_name' config.json)
        DB_UNAME=$(jq -r --arg i "$i" '.[$i | tonumber].db_uname' config.json)
        DB_PASSWORD=$(jq -r --arg i "$i" '.[$i | tonumber].db_password' config.json)
        DB_CYCLE=$(jq -r --arg i "$i" '.[$i | tonumber].db_cycle' config.json)
        DB_DIR=$(jq -r --arg i "$i" '.[$i | tonumber].db_dir' config.json)
        db_backup_one $DB_NAME $DB_UNAME $DB_PASSWORD $DB_CYCLE $DB_DIR
    done
}

# db_find_and_back_up(db_name)
#
# Find config for db_name and backup.
db_find_and_back_up() {
    count=$(jq '. | length' config.json)
    for ((i=0; i<=count-1; i++));
    do
        db_name=$(jq -r --arg i "$i" '.[$i | tonumber].db_name' config.json)
        if [[ $db_name == $1 ]]
        then
            echo "$1 found. Starting backup..."
            DB_NAME=$(jq -r --arg i "$i" '.[$i | tonumber].db_name' config.json)
            DB_UNAME=$(jq -r --arg i "$i" '.[$i | tonumber].db_uname' config.json)
            DB_PASSWORD=$(jq -r --arg i "$i" '.[$i | tonumber].db_password' config.json)
            DB_CYCLE=$(jq -r --arg i "$i" '.[$i | tonumber].db_cycle' config.json)
            DB_DIR=$(jq -r --arg i "$i" '.[$i | tonumber].db_dir' config.json)
            db_backup_one $DB_NAME $DB_UNAME $DB_PASSWORD $DB_CYCLE $DB_DIR
            return 0
        fi
    done
}

# db_modify()
#
# Check if database exist then delete it. Otherwise create it.
db_modify() {
    config_plain=$(cat config.json)
    count=$(jq '. | length' config.json)
    read -p "Enter database name: " db_enter
    for ((i=0; i<=count-1; i++));
    do
        db_name=$(jq -r --arg i "$i" '.[$i | tonumber].db_name' config.json)
        if [[ $db_name == $db_enter ]]
        then
            echo "$db_name found. Deleting..."
            jq --arg i "$i" 'del(.[$i | tonumber])' config.json > tmp.json
            rm -rf config.json
            mv tmp.json config.json
            tput setaf 2
            echo "Deleted!"
            tput setaf 7
            found=1
            break
        else
            found=0
        fi
    done
    if [[ $found -eq 0 ]]
    then
        echo "Database not found. Creating..."
        echo "Enter database information: "
        db_input $db_enter
    else
        start
    fi
}

while getopts ad:c opts; do
   case ${opts} in
      a)
        echo "Running backup for all database..."
        db_backup_all
        tput setaf 7
        ;;
      d)
        DB_NAME=${OPTARG}
        db_find_and_back_up $DB_NAME
        tput setaf 7
        ;;
      c)
        start
        ;;
   esac
done
