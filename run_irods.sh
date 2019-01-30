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
    { echo "One or more packages missing" ;
      echo "Attempting to download ..."; } >&2
    if ! bash /wget_ir4_1_12_pkgs.sh >/dev/null 2>&1; then
         { echo 'Packages missing and could not be downloaded'
           echo -n 'run the commands in ' ; ls /wget_*pkgs.sh
           echo -n 'Then: ' ; } >&2
    fi
fi

{ echo 'To setup manually from packages ... ';
  echo 'Do - 1. service postgresql start';
  echo '   - 2. /var/lib/irods/packaging/setup_irods.sh'; } >&2
