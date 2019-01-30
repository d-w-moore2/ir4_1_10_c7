#!/bin/bash

file_missing=0

for F in irods-icat-4.1.12-ubuntu14-x86_64.deb \
         irods-database-plugin-postgres-1.12-ubuntu14-x86_64.deb 
do
    if [ ! -f /$F ] ; then
        ((++file_missing))
    fi
done

if [ $file_missing -gt 0 ]; then 
    if bash /wget_ir4_1_12_pkgs.sh >/dev/null 2>&1; then
        { echo 'To install manually from packages:';
          echo ' /var/lib/irods/packaging/setup_irods.sh'; } >&2
    else
        { echo 'Packages missing and could not be downloaded'; } >&2
    fi
fi

