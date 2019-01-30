#!/bin/bash

file_missing=0
for f in irods-icat-4.1.12-ubuntu14-x86_64.deb irods-database-plugin-postgres-1.12-ubuntu14-x86_64.deb 
do
    if [ ! -f /$file ] ; then
        ((++file_missing))
    fi
done

if [ $file_missing -gt 0 ]; then 
    bash /wget_ir4_1_12_pkgs.sh
fi

# to install manually from packages:
#     bash /var/lib/irods/packaging/setup_irods.sh
