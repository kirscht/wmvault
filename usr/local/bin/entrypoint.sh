#!/usr/bin/dumb-init /bin/bash
set -e

set -x

exec 2>&1 > /var/log/entrypoint.log

#cp /var/log/vault/vault /usr/local/bin/.
#cp /var/log/vault/kubectl /usr/local/bin/.

. /usr/local/bin/functions.sh

function STARTVAULT(){

    /usr/local/bin/vault server -config=/usr/local/etc/vault.hcl &

}

function INITVAULT(){

    sleep 10
    /usr/bin/curl http://127.0.0.1:8200/v1/sys/init
    /usr/local/bin/vault operator init 2>&1 > /var/log/vault/vault_init.log

}

function UNSEALVAULT(){

    export SHELL=/bin/bash
    export VAULT_TOKEN="$(ROOTTOKEN)"
    /usr/local/bin/unseal.exp "$(UNSEALKEY 1)"
    /usr/local/bin/unseal.exp "$(UNSEALKEY 2)"
    /usr/local/bin/unseal.exp "$(UNSEALKEY 3)"

}

echo "LEADER $(POTENTIALLEADER)"

sleep 5

cat <<EOF

  LOCALIP = "$(LOCALIP)"
  OLDESTPODIP = "$(OLDESTPODIP)"

EOF

if [[ "$(LOCALIP)" != "$(OLDESTPODIP)" ]]
then
    if ISCONSUL
    then
        sleep 2
        /bin/consul agent -data-dir=/consul/data -retry-join $(OLDESTPODIP) -server &
        sleep 2
        /bin/consul join $(OLDESTPODIP)
    fi

    if ISVAULT
    then
        sleep 2
        STARTVAULT
    fi
else
    /usr/bin/nohup /bin/sh /usr/local/bin/docker-entrypoint.sh $@ </dev/null 2>&1 > /var/log/docker-entrypoint.log &
    sleep 2

    if ISVAULT
    then
        STARTVAULT
        INITVAULT
    fi
fi

if ISCONSUL
then
    /bin/consul members
    /bin/consul kv put nodes/$(LOCALIP) $(hostname)
fi

if ISVAULT
then
    UNSEALVAULT
    echo "export VAULT_TOKEN=\"$(ROOTTOKEN)\"" >> /etc/profile
fi

tail -f /dev/null

exit