echo "Setting up the project"

#ask user name and print hello $name
echo "What do you want to call this project?"
read project_name
echo "Let's setup $project_name"

#ask user if need to install composer or skip
echo "Do you want to install composer? (y/n)[no]"
read install_composer
if [ "$install_composer" = "y" ] || [ "$install_composer" = "Y" ] ]
then
    echo "Installing composer"
    composer install
else
    echo "Skipping composer installation"
fi

#ask user if need to install yarn or skip
echo "Do you want to install yarn? (y/n)[no]"
read install_yarn
if [ "$install_yarn" = "y" ] || [ "$install_yarn" = "Y" ] ]
then
    echo "Installing yarn"
    yarn install
else
    echo "Skipping yarn installation"
fi

#ask user if want to import db or skip
echo "Do you want to import db? (y/n)[no]"
read import_db
if [ "$import_db" = "y" ] || [ "$import_db" = "Y" ] ]
then
    echo "Importing db"
    #ask user for the db file name and unzip if file exists
    echo "Enter the db file name"
    read db_file_name
    if [ -f "$db_file_name" ]
    then
        echo "Unzipping db file"
        gunzip $db_file_name
        psql -h db -d db -U db -f $db_file_name

        #delete unzipped file
        rm -f $db_file_name
    else
        echo "File not found"
    fi
else
    echo "Skipping db import"
fi


#ask user if want to recreate files
echo "Do you want to recreate files? (y/n)[no]"
read recreate_files
if [ "recreate_files" = "y" ] || [ "recreate_files" = "Y" ] ]
then
    #copy files
    for file in site/config/*.dist; do
        newname="${file%.dist}"
        cp "$file" "$newname"
    done

    cp site/web/index.php.dist site/web/index.php

    touch site/config/saml/firstdue-x509.crt
    touch site/config/saml/firstdue-x509.key

    echo "defined('YII_DEBUG') or define('YII_DEBUG', true);" >> site/web/index.php
#    rm vendor/yiisoft/yii/framework/db/ar/CActiveRecord.php && cp .ddev/extras/CActiveRecord.php  vendor/yiisoft/yii/framework/db/ar/CActiveRecord.php

    echo "Necessary files copied!!!"

else
    echo "Skipping file recreation"
fi


#ask user if want to run migrations
echo "Do you want to run migrations? (y/n)[no]"
read run_migrations
if [ "$run_migrations" = "y" ] || [ "$run_migrations" = "Y" ] ]
then
    echo "Running migrations"
    php console/yiic.php migrate
else
    echo "Skipping migrations"
fi



#write message in green color and in bold
echo -e "\e[1;32m $name setup complete, use 'ddev start' to start the project\e[0m"

