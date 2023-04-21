# FDSU ddev
A ddev development environment for fdsu which works based on docker

### Install Docker
https://docs.docker.com/engine/install/ubuntu/

### Install ddev
https://ddev.readthedocs.io/en/latest/users/install/ddev-installation/#linux

### Configure within project
cd [project root] # goto project root

git clone https://github.com/sandeepfd/fdsu_ddev.git .ddev

ddev start

### Import database 
ddev import-db --src=[./fdsu.sql.gz]
> Any customizations in environment can be done in config.local.yaml and run ddev restart.
>
> For more config options https://ddev.readthedocs.io/en/stable/users/configuration/config/

