#!/bin/sh
set -e

create_keystore() {
    ${NIFI_TOOLKIT_HOME}/bin/tls-toolkit.sh standalone -n "${HOSTNAME}" -S "${KEYSTORE_PASS}" -C "CN=${HOSTNAME}, OU=NIFI" -P "${TRUSTSTORE_PASS}" -o "${NIFI_TOOLKIT_HOME}"
    mv ${NIFI_TOOLKIT_HOME}/${HOSTNAME}/keystore.jks ${NIFI_HOME}/conf/keystore.jks
    mv ${NIFI_TOOLKIT_HOME}/${HOSTNAME}/truststore.jks  ${NIFI_HOME}/conf/truststore.jks
}

patch_nifi_properties()  {
    FQDN=$(hostname -f)
    cat "${NIFI_HOME}/conf/nifi.temp" > "${NIFI_HOME}/conf/nifi.properties"
    echo "nifi.web.http.host=${FQDN}" >> "${NIFI_HOME}/conf/nifi.properties"
    echo "nifi.web.https.host=${FQDN}" >> "${NIFI_HOME}/conf/nifi.properties"
    echo "nifi.remote.input.host=${FQDN}" >> "${NIFI_HOME}/conf/nifi.properties"
    echo "nifi.cluster.node.address=${FQDN}" >> "${NIFI_HOME}/conf/nifi.properties"
    echo "nifi.zookeeper.connect.string=${NIFI_ZOOKEEPER_CONNECT_STRING}" >> "${NIFI_HOME}/conf/nifi.properties"
}

create_keystore
patch_nifi_properties

sh "$@"
