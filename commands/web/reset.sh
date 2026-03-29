echo "Setting up the project"

#ask user if really want to reset project
echo "Are you sure you want to reset the project? (y/n)[no]"
read -r answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    rm -f db.sql
    rm -f db.sql.gz

    #remove files
    rm -rf site/config/saml/firstdue-x509.crt
    rm -rf site/config/saml/firstdue-x509.key

    rm -rf site/config/cache-local.php
    rm -rf site/config/cache_write-local.php
    rm -rf site/config/common-local.php
    rm -rf site/config/db_read-local.php
    rm -rf site/config/db_read_api-local.php
    rm -rf site/config/db_read_report-local.php
    rm -rf site/config/db_write-local.php
    rm -rf site/config/main-local.php
    rm -rf site/config/message_broker-local.php
    rm -rf site/config/test-local.php


    #delete vendor folder
    rm -rf vendor

    #delete node_modules folder
    rm -rf node_modules


else
    echo "Reset cancelled"
    exit 1
fi