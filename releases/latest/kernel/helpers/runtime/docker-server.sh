#!/bin/sh

set -e

SNIPPETS_SOURCE=/opt/ol/helpers/build/configuration_snippets
SNIPPETS_TARGET_DEFAULTS=/config/configDropins/defaults
SNIPPETS_TARGET_OVERRIDES=/config/configDropins/overrides

keystorePath="$SNIPPETS_TARGET_DEFAULTS/keystore.xml"

if [ "$SSL" = "true" ] || [ "$TLS" = "true" ]
then
  cp $SNIPPETS_SOURCE/tls.xml $SNIPPETS_TARGET_OVERRIDES/tls.xml
fi

if [ "$SSL" != "false" ] && [ "$TLS" != "false" ]
then
  if [ ! -e $keystorePath ]
  then
    # Generate the keystore.xml
    export KEYSTOREPWD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
    sed -i.bak "s|REPLACE|$KEYSTOREPWD|g" $SNIPPETS_SOURCE/keystore.xml
    cp $SNIPPETS_SOURCE/keystore.xml $SNIPPETS_TARGET_DEFAULTS/keystore.xml
  fi
fi

publicCert="/etc/wlp/config/certificates/tls.crt"
privateKey="/etc/wlp/config/certificates/tls.key"
customkeystore="/etc/wlp/config/customKeystore/customkeystore.p12"
customtruststore="/etc/wlp/config/customTruststore/customtruststore.p12"

# If the ICP CA tls.crt and tls.key, or custom keystore and truststore exists, convert to P12 and use
if [ -e $publicCert ] && [ -e $privateKey ] || [ -e $customkeystore ]
then
  echo 'debug: cert/key or customkeystore found, running script'
  #Always generate on startup
  /opt/ibm/helpers/runtime/gen-icp-cert.sh
  
  #Start inotify
  /opt/ibm/helpers/runtime/inotify-cert.sh &
fi

# Pass on to the real server run
exec "$@"
