# FDSU ddev
A ddev development environment for fdsu that works based on docker.

You can download the below tools as per your system OS and configuration.

### Install Docker
https://docs.docker.com/engine/install/

### Install ddev
https://ddev.readthedocs.io/en/latest/users/install/ddev-installation/

### Configure within project
```
cd [project root] # goto project root
git clone https://github.com/sandeepfd/fdsu_ddev.git .ddev # This will clone the environment into .ddev folder
ddev start # start the environment
```
If you can see `Successfully started fdsu` on the terminal, it's up and working.
Please try any provided local URL and confirm.

### Import database 
```
ddev import-db --src=[./fdsu.sql.gz] #  replace '[./fdsu.sql.gz]' with your respective filename with path.
```

> Any customizations in the environment can be done in config.local.yaml and run `ddev restart`
>
> For more config options https://ddev.readthedocs.io/en/stable/users/configuration/config/

