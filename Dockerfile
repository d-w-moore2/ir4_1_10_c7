FROM centos:7

SHELL ["/bin/bash", "-c"]

ADD db_commands.txt \
    irods-database-plugin-postgres-1.10-centos7-x86_64.rpm \
    irods-icat-4.1.10-centos7-x86_64.rpm                   \
    /

RUN yum install -y epel-release && \
    yum install -y wget tig git vim sudo postgresql lsof \
                   postgresql postgresql-server unixODBC perl authd postgresql-odbc \
                   fuse-libs python-psutil python-requests python-jsonschema \
                   perl-JSON python-jsonschema python-psutil python-pip

# Setup ICAT database.
#RUN service postgresql start && su - postgres -c "psql -f /db_commands.txt" && \
#    service postgresql stop

COPY run_irods_4_1.sh /
COPY wget_ir4_1_12_pkgs.sh /

#WORKDIR /

#RUN chmod u+x /run_irods_4_1.sh /wget_ir4_1_12_pkgs.sh

CMD [ "/bin/bash" ]
