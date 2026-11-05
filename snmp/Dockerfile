FROM ubuntu:22.04

# Install packages net-snmp depends on
RUN apt update > /dev/null && \
    apt install -y apt-utils > /dev/null && \
    apt install -y wget file gcc make openssl libssl-dev libperl-dev snmp-mibs-downloader > /dev/null

# Get net-snmp source code
RUN cd /opt && \
    wget https://sourceforge.net/projects/net-snmp/files/net-snmp/5.9.5.2/net-snmp-5.9.5.2.tar.gz && \
    tar -xzvf net-snmp-5.9.5.2.tar.gz && cd net-snmp-5.9.5.2

# Compile and install net-snmp
RUN cd /opt/net-snmp-5.9.5.2 && \
    ./configure --with-default-snmp-version="3" \
                --with-sys-contact="@@no.where" \
                --with-sys-location="Unknown" \
                --with-logfile="/var/log/snmpd.log" \
                --with-persistent-directory="/var/net-snmp" && \
    make 2>&1 | tee make.log && make install 

# Set environment variable LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/local/lib

# Expose snmp port
EXPOSE 161/udp

# Run snmpd
CMD [ "/usr/local/sbin/snmpd", "-Dmib_init", "-f", "-Lo" ]
