#!/usr/bin/dumb-init /bin/bash
set -e

set -x

#exec 2>&1 > /var/log/entrypoint.log

. /usr/local/bin/functions.sh

echo "LEADER $(POTENTIALLEADER)"

sleep 20

cat <<EOF

  LOCALIP = "$(LOCALIP)"
  OLDESTPODIP = "$(OLDESTPODIP)"

EOF

if [[ "$(LOCALIP)" != "$(OLDESTPODIP)" ]]
then
    set -x
    sleep 45
    /bin/consul agent -data-dir=/consul/data -retry-join $(OLDESTPODIP) -server &
#    /bin/consul agent -client 127.0.0.1 -data-dir=/consul/data &
    sleep 45
    /bin/consul members < /dev/null
    /bin/consul join $(OLDESTPODIP)
else
    /usr/bin/nohup /bin/sh /usr/local/bin/docker-entrypoint.sh $@ </dev/null 2>&1 > /var/log/docker-entrypoint.log &
    sleep 10
fi

/bin/consul members </dev/null
/bin/consul kv put nodes/$(LOCALIP) $(hostname)

tail -f /dev/null

exit