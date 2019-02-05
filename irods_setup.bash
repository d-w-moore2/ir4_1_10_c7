#!/bin/bash
#----------------------

# sudo yum install -y wget
# sudo yum install -y irods-server
# sudo yum install -y irods-database-plugin-postgres
# sudo python /var/lib/irods/scripts/setup_irods.py </var/lib/irods/packaging/localhost_setup_postgres.input
# sudo yum install -y ctags-etags.x86_64
# sudo yum remove ctags-etags.x86_64
# sudo yum install -y cscope
# mkdir ~/github; cd ~/github
# git clone http://github.com/irods/irods ; cd irods ; git submodule update --init
# sudo yum -y install openssl-devel pam-devel unixODBC-devel python gcc-c++
# sudo yum install -y irods-externals\*
# PATH=/opt/irods-externals/cmake3.5.2-0/bin:$PATH
# echo 'PATH=/opt/irods-externals/cmake3.5.2-0/bin:$PATH'>>~/.bashrc
# rm -fr *; cmake -DCMAKE_BUILD_TYPE=Debug ../irods  -GNinja
# sudo yum install -y rpm-build ninja-build
# ninja-build package
# sudo yum install -y help2man
# ninja-build package
# -- install iRODS after building
# sudo rpm -ivh irods-runtime-4.2.8-1.x86_64.rpm irods-devel-4.2.8-1.x86_64.rpm
# sudo rpm -ivh irods-icommands-4.2.8-1.x86_64.rpm
# sudo rpm --force -ivh irods-icommands-4.2.8-1.x86_64.rpm
# sudo rpm --force -ivh irods-server-4.2.8-1.x86_64.rpm  irods-database-plugin-postgres-4.2.8-1.x86_64.rpm
# sudo python /var/lib/irods/scripts/setup_irods.py </var/lib/irods/packaging/localhost_setup_postgres.input
# yum install psmisc # for fuser
# -- gdb
#./configure --enable-tui --with-curses

SUDO=''

[ `id -u` = 0 -a "$1" = "store" ] && {   # - run by Dockerfile
  echo $PREINSTALL >/root/preinstall.txt
  exit 0
}

sudo_is_pwless()
{
  sudo -n ls /root >/dev/null && { SUDO=sudo; true; }
} \
2>/dev/null

make_sudo_pwless()
{
  sudo_is_pwless && return;
  local cmd="echo '$USER ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers"
  sudo su - -c "/bin/bash -c \"$cmd\"" && SUDO='sudo'
}

can_be_root() { [ `id -u` = 0 ] || make_sudo_pwless; }

ensure_preinstall_pkgs()
{
  can_be_root || return 126
  local preinstall_pkgs=`$SUDO cat /root/preinstall.txt`
  for pkg in ${preinstall_pkgs}; do
    echo >&2 "checking $pkg ."
    rpm -q $pkg >/dev/null || $SUDO yum install -y $pkg
  done
}

install_prereqs()
{
  can_be_root || return 126
  local STATUS=good
  for pkg in epel-release postgresql-server ;do
    command $SUDO yum install -y $pkg || { STATUS=bad; break; }
  done
  [ $STATUS = "good" ] && command $SUDO su - postgres -c "/usr/bin/pg_ctl initdb"
}

db_ctl() 
{
  can_be_root || return 126
  if pgrep -f -u postgres bin/postgres >/dev/null
  then
    x=10
    while [ $((--x)) -ge 0 ] && { ! $SUDO su - postgres -c "psql -c '\l' >/dev/null 2>&1" || x=""; }
    do
      [ -z "$x" ] && break
      sleep 1
    done
    [ -z "$x" ] && {
      DB_RUNNING="Y"
      [ "$1" = "stop" ] && { $SUDO su - postgres -c "/usr/bin/pg_ctl stop" ; return; }
    }
  else
    DB_RUNNING="N"
    [ "$1" = "start" ] && { $SUDO su - postgres -c "/usr/bin/pg_ctl -D /var/lib/pgsql/data -l logfile start" ; return; }
  fi
  [ "$DB_RUNNING" = "Y" ]
}

set_up_coredev_repo()
{
  can_be_root || return 126
  $SUDO  rpm --import https://core-dev.irods.org/irods-core-dev-signing-key.asc
  wget -qO - https://core-dev.irods.org/renci-irods-core-dev.yum.repo | $SUDO tee /etc/yum.repos.d/renci-irods-core-dev.yum.repo
}

set_up_package_repo()
{
  can_be_root || return 126
  $SUDO rpm --import https://packages.irods.org/irods-signing-key.asc
  wget -qO - https://packages.irods.org/renci-irods.yum.repo | $SUDO tee /etc/yum.repos.d/renci-irods.yum.repo
}

uninit_database_and_user() {
  can_be_root || return 126
  $SUDO su - postgres -c "dropdb --if-exists ICAT ; dropuser --if-exists irods"

}

PSQL_IRODS_INIT="psql <<'EOF'
CREATE USER irods WITH PASSWORD 'testpassword';
CREATE DATABASE \"ICAT\";
GRANT ALL PRIVILEGES ON DATABASE \"ICAT\" TO irods;
EOF
"

init_database_and_user()
{
  can_be_root || return 126
  $SUDO su - postgres -c "$PSQL_IRODS_INIT"
}

