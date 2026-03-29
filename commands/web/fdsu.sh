echo "Setting up the project"

#ask user if need to install composer or skip
echo "Do you want to install composer? (y/n)[no]"
read install_composer
if [ "$install_composer" = "y" ] || [ "$install_composer" = "Y" ] ]
then
    echo "Installing composer"
    composer install
else
  echo -e "\e[1;33mSkipping composer installation\e[0m"
fi

#ask user if need to install yarn or skip
echo "Do you want to install yarn? (y/n)[no]"
read install_yarn
if [ "$install_yarn" = "y" ] || [ "$install_yarn" = "Y" ] ]
then
    echo -e "\e[1;32m Installing yarn \e[0m"
    yarn install

    cd site && yarn install --ignore-engines && cd ..
else
    echo -e "\e[1;33mSkipping yarn installation\e[0m"
fi


function runDatabaseImport() {
    echo "Enter the db file name"
    read -r db_file_name

    if [ -f "$db_file_name" ]; then

        #check file extension if gz
            if [[ "$db_file_name" == *.gz ]]
            then
                echo "File is gzipped"
                echo "Unzipping db file"
                gunzip "$db_file_name" -c > "db.sql"
                filename="db.sql"
            else
                filename="$db_file_name"
            fi

            echo "Importing db"
            psql -h db -d db -U db -f "$filename"
    else
        echo "File not found"
        retry="y"
        echo "Do you want to retry (y/n)[no]"
        read -r retry
        if [ "$retry" = "y" ] || [ "$retry" = "Y" ]
          then
              runDatabaseImport
          else
              echo -e "\e[1;33mSkipping db import\e[0m"
          fi
    fi
}

#ask user if want to import db or skip
echo "Do you want to import db? (y/n)[no]"
read -r import_db
if [ "$import_db" = "y" ] || [ "$import_db" = "Y" ] ]
then
    runDatabaseImport
else
    echo -e "\e[1;33mSkipping db import\e[0m"
fi

#ask user if want to recreate files
echo "Do you want to recreate files? (y/n)[no]"
read -r recreate_files
if [ "$recreate_files" = "y" ] || [ "$recreate_files" = "Y" ] ]
then
    #copy files
    for file in site/config/*.dist; do
        newname="${file%.dist}"
        cp "$file" "$newname"
    done

    cp site/web/index.php.dist site/web/index.php

    #edit file site/web/index.php and uncomment line 3
    sed -i '3 s/\/\/\(.*\)/\1/' ./site/web/index.php

    touch site/config/saml/firstdue-x509.crt
    touch site/config/saml/firstdue-x509.key

    echo "defined('YII_DEBUG') or define('YII_DEBUG', true);" >> site/web/index.php
#    rm vendor/yiisoft/yii/framework/db/ar/CActiveRecord.php && cp .ddev/extras/CActiveRecord.php  vendor/yiisoft/yii/framework/db/ar/CActiveRecord.php

    echo -e "\e[1;32mNecessary files copied!!!\e[0m"

else
    echo -e "\e[1;33mSkipping file recreation\e[0m"
fi


#ask user if want to run migrations
echo "Do you want to run migrations? (y/n)[no]"
read run_migrations
if [ "$run_migrations" = "y" ] || [ "$run_migrations" = "Y" ] ]
then
    echo "Running migrations"
    php console/yiic.php migrate
else
    echo -e "\e[1;33mSkipping migrations\e[0m"
fi

#write message in green color and in bold
echo -e "\e[1;32m $name setup complete, use 'ddev start' to start the project\e[0m"

