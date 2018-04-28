#!/bin/sh
set -e

create_keystore() {
    echo ${HOST}
    ${NIFI_TOOLKIT_HOME}/bin/tls-toolkit.sh standalone -n "${HOST}" -S "${KEYSTORE_PASS}" -C "CN=${HOST}, OU=NIFI" -P "${TRUSTSTORE_PASS}" -o "${NIFI_TOOLKIT_HOME}"
    mv ${NIFI_TOOLKIT_HOME}/${HOST}/keystore.jks ${NIFI_HOME}/conf/keystore.jks
    chown nifi:nifi ${NIFI_HOME}/conf/keystore.jks
    mv ${NIFI_TOOLKIT_HOME}/${HOST}/truststore.jks  ${NIFI_HOME}/conf/truststore.jks
    chown nifi:nifi ${NIFI_HOME}/conf/truststore.jks
}

patch_nifi_properties()  {
    cat "${NIFI_HOME}/conf/nifi.temp" > "${NIFI_HOME}/conf/nifi.properties"
    echo "nifi.web.http.host=${HOST}.${HEADLESS}" >> "${NIFI_HOME}/conf/nifi.properties"
    echo "nifi.remote.input.host=${HOST}.${HEADLESS}" >> "${NIFI_HOME}/conf/nifi.properties"
    echo "nifi.cluster.node.address=${HOST}.${HEADLESS}" >> "${NIFI_HOME}/conf/nifi.properties"
    echo "nifi.zookeeper.connect.string=${NIFI_ZOOKEEPER_CONNECT_STRING}" >> "${NIFI_HOME}/conf/nifi.properties"
}

create_keystore
patch_nifi_properties
chown nifi:nifi /opt/nifi/data
chown nifi:nifi /opt/nifi/flowfile_repository
chown nifi:nifi /opt/nifi/content_repository
chown nifi:nifi /opt/nifi/logs

su nifi "$@"
