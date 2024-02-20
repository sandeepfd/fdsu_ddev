#!/bin/bash

set -e

# Colors for better output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

# Log file for recording actions
LOG_FILE="install_log.txt"

# Function to log messages
log_message() {
    local message=$1
    local color=$2
    printf "%s - %b%s%b\n" "$(date '+%Y-%m-%d %H:%M:%S')" "${color}" "${message}" "${RESET}" >> "$LOG_FILE"
}

install_ddev() {
    # Initialize mkcert
    if ! mkcert -install; then
        echo "Error: Failed to install mkcert." "$RED"
        exit 1
    fi

    # Download and run the install script for ddev
    if ! curl -fsSL https://ddev.com/install.sh | bash; then
        echo "Error: Failed to download and run the ddev install script." "$RED"
        exit 1
    fi
}

# Function to check and create a directory
check_and_create_dir() {
    local dir=$1
    log_message "Checking directory ${dir} existence!" "$YELLOW"
    if [ ! -d "${dir}" ]; then
        log_message "${dir} directory does not exist." "$RED"
        log_message "Creating directory ${dir}" "$YELLOW"
        mkdir -p "${dir}" || { log_message "Failed to create directory ${dir}"  "$RED"; exit 1; }
        log_message "${dir} directory created successfully." "$GREEN"
    fi
}

# Function to read user input
read_user_input() {
    local prompt=$1
    local var_name=$2
    # shellcheck disable=SC2229
    read -p "$prompt" "$var_name"
    if [[ -z ${!var_name} ]]; then
        echo "Error: Input cannot be empty."
        exit 1
    fi
}

# Function to remove a directory if it exists
remove_directory_if_exists() {
    local dir=$1
    log_message "Checking directory ${dir} existence for removal!" "$YELLOW"
    if [ -d "${dir}" ]; then
        log_message "${dir} directory exists. Removing..." "$YELLOW"
        rm -r "${dir}" || { log_message "Failed to remove directory ${dir}" "$RED"; exit 1; }
        log_message "${dir} directory removed successfully." "$GREEN"
    else
        log_message "${dir} directory does not exist. Nothing to remove." "$YELLOW"
    fi
}

# Function to clone a repository
clone_repo() {
    local auth_repo_url="https://${PASSWORD}@github.com/${USERNAME}/${REPO_NAME}.git"
    local repo_url="https://github.com/${USERNAME}/${REPO_NAME}.git"

    log_message "Cloning '${repo_url}' into '${LOCAL_DIR}' directory!" "$YELLOW"

    # Check if the destination directory exists and is not an empty directory
    if [ -e "${LOCAL_DIR}" ]; then
        if [ "$(ls -A ${LOCAL_DIR})" ]; then
            log_message "${RED}Error: Destination path '${LOCAL_DIR}' already exists and is not an empty directory.${RESET}"
            exit 1
        else
            log_message "${YELLOW}Warning: Destination path '${LOCAL_DIR}' already exists but is an empty directory. Proceeding with clone.${RESET}"
        fi
    fi

    git clone --progress "${auth_repo_url}" "${LOCAL_DIR}" || { log_message "${RED}Error: Failed to clone repository.${RESET}"; exit 1; }

    log_message "Successfully cloned '${repo_url}' into '${LOCAL_DIR}' directory!"
}

# Function to clone the ddev repository
clone_ddev_repo() {
    local ddev_dir="/tmp/.ddev"

    remove_directory_if_exists "${ddev_dir}"

    log_message "Creating directory ${ddev_dir}"
    mkdir -p "${ddev_dir}" || { log_message "Failed to create directory ${ddev_dir}"; exit 1; }
    log_message "${ddev_dir} directory created successfully."

    log_message "Cloning ddev repo into ${LOCAL_DIR} directory!"
    git clone --progress "https://${PASSWORD}@github.com/nramakrishna2022/fdsu_ddev" "${ddev_dir}" || { log_message "Failed to clone ddev repository"; exit 1; }
    log_message "Successfully cloned ddev repo into '${ddev_dir}' directory!"

    log_message "Removing existing .ddev directory from '${LOCAL_DIR}' if it exists!"
    remove_directory_if_exists "${LOCAL_DIR}/.ddev"

    log_message "Moving .ddev directory into '${LOCAL_DIR}'!"
    mv "${ddev_dir}" -t "${LOCAL_DIR}" || { log_message "Failed to move .ddev directory"; exit 1; }
    log_message "Moved .ddev directory into '${LOCAL_DIR}'!"
}

# Function to configure the project with ddev
configure_project_with_ddev() {
    log_message "Configuring project with ddev!"

    # Uncomment the lines below and customize the ddev configuration based on your needs
    # ddev config --project-name="${DDEV_PROJECT_NAME}" --project-type=php --docroot=site/web/ --php-version=7.4 --webserver-type=nginx-fpm --additional-fqdns=sizeup.firstduesizeup.test --database=postgres:15 --dbimage-extra-packages=postgis,postgresql-postgis --webimage-extra-packages=php-mailparse,supervisor --nodejs-version=18 --disable-settings-management=false --http-port=80 --https-port=443

    log_message "Stopping any existing ddev services..."
    cd ${LOCAL_DIR}

    if ! ddev stop --unlist fdsu; then
        log_message "${YELLOW}Warning: Failed to stop existing ddev services.${RESET}"
    else
        log_message "${GREEN}Successfully stopped existing ddev services.${RESET}"
    fi

    log_message "Starting ddev!"
    if ! ddev start; then
        log_message "Error: Failed to start ddev."
        exit 1
    fi

    log_message "Successfully configured project with ddev!"
}

# Function for additional project setup
additional_project_setup() {
    log_message "Starting setup the project!"

    log_message "Installing composer packages!"
    if ! ddev composer install --ignore-platform-reqs; then
        log_message "Error: Failed to install composer packages."
        exit 1
    fi

    log_message "Installing yarn packages!"
    cd "${LOCAL_DIR}"
    if ! ddev yarn --cwd site/ install --pure-lockfile; then
        log_message "Error: Failed to install yarn packages."
        exit 1
    fi

    log_message "Building yarn packages!"
    if ! ddev yarn --cwd site/ build:dev; then
        log_message "Error: Failed to build yarn packages."
        exit 1
    fi

    log_message "Setting up directory, file permissions!"

    cd "${LOCAL_DIR}"

    # ... (Add additional setup steps as needed)

    log_message "Directory and file permissions set up successfully!"
}

# Function to rename config files
rename_config_files() {
    cd "${LOCAL_DIR}"
    log_message "Renaming config files!"

    chmod +x console/yiic
    cp api/config/main-local.php.dist api/config/main-local.php
    cp console/config/main-local.php.dist console/config/main-local.php
    cp fd-api/config/main-local.php.dist fd-api/config/main-local.php
    cp fd-api/web/index.php.dist fd-api/web/index.php
    cp site/config/cache-local.php.dist site/config/cache-local.php
    cp site/config/cache_write-local.php.dist site/config/cache_write-local.php
    cp site/config/common-local.php.dist site/config/common-local.php
    cp site/config/db_read-local.php.dist site/config/db_read-local.php
    cp site/config/db_read_api-local.php.dist site/config/db_read_api-local.php
    cp site/config/db_read_report-local.php.dist site/config/db_read_report-local.php
    cp site/config/db_write-local.php.dist site/config/db_write-local.php
    cp site/config/main-local.php.dist site/config/main-local.php
    cp site/config/message_broker-local.php.dist site/config/message_broker-local.php
    cp site/config/test-local.php.dist site/config/test-local.php
    cp site/phpunit.xml.dist site/phpunit.xml
    cp site/web/.user.ini.dist site/web/.user.ini
    cp site/web/index.php.dist site/web/index.php

    log_message "Config files renamed successfully!"
}

# Function to update database parameters in config files
update_db_params() {
    log_message "Updating database parameters in config files!"

    cd "${LOCAL_DIR}/site/config" || exit 1

    files=(db_*.php)

    if [ ${#files[@]} -eq 0 ]; then
        log_message "Error: No matching files found."
        exit 1
    fi

    read_user_input "Enter db host: " db_host
    read_user_input "Enter db port: " db_port
    read_user_input "Enter db username: " db_username
    #read_user_input "Enter db password: " db_password
    read -s -p "Enter db password: " db_password

    for file in "${files[@]}"; do
        sed -i "s/host=[^;]*;dbname=[^']*'/host=$db_host;dbname=$db_port'/" "$file"
        sed -i "s/'username' => '[^']*'/\x27username\x27 => \x27$db_username\x27/" "$file"
        sed -i "s/'password' => '[^']*'/\x27password\x27 => \x27$db_password\x27/" "$file"
    done

    files=(cache-*.php)

    if [ ${#files[@]} -eq 0 ]; then
        log_message "Error: No matching files found."
        exit 1
    fi

    for file in "${files[@]}"; do
        sed -i "s/'password' => '[^']*'/\x27password\x27 => \x276nk9DL8AR79FrXtj7ZVugTJ7JJqEVv7n\x27/" "$file"
    done

    log_message "Database parameters updated successfully!"
}

update_redis_params() {
    log_message "Updating database parameters in config files!"

    cd "${LOCAL_DIR}/site/config" || exit 1

    new_content="<?php

    // yii1 cache write component config
    return [
        'class' => 'system.caching.CRedisCache',
        'hostname' => 'redis',
        'port' => 6379,
        'database' => 0,
        'options' => STREAM_CLIENT_CONNECT,
        'keyPrefix' => 'dev10',
        'password' => '6nk9DL8AR79FrXtj7ZVugTJ7JJqEVv7n',
        'behaviors' => [
            'cacheTag' => [
                'class' => 'site_app.components.CacheTagBehavior',
            ],
        ],
    ];
    "

    files=(cache*.php)

    if [ ${#files[@]} -eq 0 ]; then
        log_message "Error: No matching files found."
        exit 1
    fi

    for file in "${files[@]}"; do
        echo "$new_content" > "$file"
    done

    log_message "Redis parameters updated successfully!"
}

# Define reusable SQL statements
CREATE_ROLE_SQL="CREATE ROLE fdsu WITH LOGIN PASSWORD 'fdsu' SUPERUSER CREATEDB CREATEROLE;"

CREATE_EXTENSIONS_SQL="
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE EXTENSION IF NOT EXISTS pg_trgm;

  ALTER TABLE IF EXISTS geography_columns OWNER TO db;
  ALTER TABLE IF EXISTS geometry_columns OWNER TO db;
  ALTER TABLE IF EXISTS spatial_ref_sys OWNER TO db;
"

ALTER_USER_SQL=$(cat <<'EOF'
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'db') THEN
    EXECUTE 'ALTER USER db SET search_path = app, public;';
  END IF;
END $$;
EOF
)

CREATE_SCHEMAS_SQL="
  CREATE SCHEMA IF NOT EXISTS app;
  CREATE SCHEMA IF NOT EXISTS rrule;
"

CREATE_TEST_SCHEMA_SQL="
  CREATE SCHEMA IF NOT EXISTS app;
"

# Function to import the database using ddev
import_database() {
    log_message "Importing database using ddev import-db!"
    cd "${LOCAL_DIR}"

    # Check if role exists before creating
    if ! ddev psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='fdsu'" | grep -q 1; then
        log_message "Creating role 'fdsu'..."
        if ! ddev psql -c "${CREATE_ROLE_SQL}"; then
            log_message "${RED}Error: Failed to create role 'fdsu'.${RESET}"
            exit 1
        fi
    else
        log_message "Role 'fdsu' already exists."
    fi

    # Check if extensions and search path are already set
    if ! ddev psql -U db -d db -c "${CREATE_EXTENSIONS_SQL}"; then
        log_message "${RED}Error: Failed to create extensions or set search path.${RESET}"
        exit 1
    fi

    # Check if user exists before altering search path
    if ! ddev psql -U db -d db -c "${ALTER_USER_SQL}"; then
        log_message "${RED}Error: Failed to alter search path for user 'db'.${RESET}"
        exit 1
    fi

    # Check if schemas exist before creating
    if ! ddev psql -U db -d db -c "${CREATE_SCHEMAS_SQL}"; then
        log_message "${RED}Error: Failed to create schemas.${RESET}"
        exit 1
    fi

    # Check if database exists before creating
    if ! ddev psql -tAc "SELECT 1 FROM pg_database WHERE datname='test_fdsu'" | grep -q 1; then
        log_message "Creating database 'test_fdsu'..."
        createdb -U db -p 5439 test_fdsu --encoding=UTF8 || exit 1
    else
        log_message "Database 'test_fdsu' already exists."
    fi

    # Check if schema exists before creating in the test database
    ddev psql -U db -d test_fdsu -c "${CREATE_TEST_SCHEMA_SQL}" || exit 1

    # Read user input for the database dump file
    read_user_input "Enter the path to your database dump file (must be a .sql.gz file): " db_dump_path

    # Check if the specified database dump file exists
    if [ ! -f "$db_dump_path" ]; then
        log_message "${RED}Error: The specified database dump file does not exist.${RESET}"
        exit 1
    fi

    # Import the database dump
    log_message "Importing database dump..."
    if ! ddev import-db --file "$db_dump_path"; then
        log_message "${RED}Error: Failed to import the database dump.${RESET}"
        exit 1
    fi

    log_message "Database imported successfully!"
}


# Main execution starts here

log_message "Script started."

read_user_input "Enter the local project directory path: " LOCAL_DIR
read_user_input "Enter your Github repo name: " REPO_NAME
read_user_input "Enter your Github username: " USERNAME
read -s -p "Enter your Github Password: " PASSWORD

if [ -z "$PASSWORD" ]; then
    echo "Error: PASSWORD environment variable is not set."
    exit 1
fi

install_ddev
check_and_create_dir "${LOCAL_DIR}"

# ... (Add other checks or preparations as needed)

clone_repo
clone_ddev_repo
configure_project_with_ddev
additional_project_setup
rename_config_files
update_db_params
update_redis_params

# Import database using ddev import-db
import_database

log_message "*"
log_message "DDEV Running Services!"
ddev describe
log_message "*"
