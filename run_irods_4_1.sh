#!/bin/bash

#warning()
#{
#   cat <<'....EOF' >&2
#       In this docker container, it is good practice to clean up in case of
#       unexpected exit or when TERM signal  is sent by 'docker stop').
#       To do this automatically:
#       trap 'service irods stop ;  service postgresql stop; echo "***"' EXIT TERM
#...EOF
#}

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

if ! id -u irods >/dev/null 2>&1
then

     # -- no irods user , instructions for install

    { echo 'To configure iRODS ... '
      echo 'Do: 1. service postgresql start'
      echo '    2. /var/lib/irods/packaging/setup_irods.sh' ; } >&2

else #-- irods user exists

    if pgrep 'irods.*Server' >/dev/null 2>&1
    then
        echo >&2 'iRODS server already running!'
    else
        { echo 'To run iRODS ... '
          echo 'Do: 1. service postgresql start'
          echo "    2. su - irods -c ~irods'/iRODS/irodsctl start'" ; } >&2
    fi
fi

untrap_signals() {
  for sig in EXIT TERM INT 
  do
      trap -- $sig
  done
}

trap_signals() {
  trap 'echo " ** Starting orderly  shutdown of ICAT db and iRODS server"
        service irods stop ;  service postgresql stop; echo " ** Exiting"
        untrap_signals; exit 1
       ' EXIT TERM INT
}

sleep_til_done() {
  echo >&2 "will sleep indefinitely. ^P ^Q will detach this connection to the container"
  trap_signals
  while : 
  do
     sleep 1
  done
}

