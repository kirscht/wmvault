#!/usr/bin/env bash

#export k8ctl="/usr/local/bin/kubectl --namespace=${NameSpace}"
export k8ctl="/usr/local/bin/kubectl "
#export VaultLog="~/nfs/vault_init.log"

function ISCONSUL(){

    egrep '^consul' /IMAGE

}

function ISVAULT(){

    egrep '^vault' /IMAGE

}

function LOCALIP(){

    trap "ECHO ''" ERR
    ip addr show dev ${CONSUL_BIND_INTERFACE:-eth0} | egrep 'inet' | awk '{print $2}' | awk -F '/' '{print $1}'

}

function OLDESTPODIP(){

    kubectl get pods --sort-by=.metadata.creationTimestamp -o wide | egrep 'Running' | awk '{print $6}' | egrep -v 'IP' | head -1

}
function GETSERVER(){

    trap "ECHO ''" ERR
    ${k8ctl} exec -it ${1} -- consul members | egrep 'server' | egrep 'Running' | awk '{print $2}' - | awk -F ':' '{print $1}' -

}

function LOWESTIP(){

    trap "ECHO ''" ERR
    SORTEDPODLIST | head -1 | awk -F ':' '{print $2}' -

}

function POTENTIALLEADER(){

    trap "ECHO ''" ERR
    for item in $(SORTEDPODLIST)
    do
        POD=$(echo ${item} | awk -F ':' '{print $1}' -)
        export LEADER=

        if [[ "$(GETSERVER ${POD})" != "" ]]
        then
            echo "$(GETSERVER ${POD})"
            return
        fi
    done

    echo "$(LOWESTIP)"
}

function RUNONPOD(){

    echo "${k8ctl} exec -it ${1} -- ${2}"
    ${k8ctl} exec -it ${1} -- ${2}

}
function SORTEDPODLIST(){

    trap "ECHO ''" ERR
    ${k8ctl} get pods -o wide | egrep "^${Deployment}" | egrep 'Running' | awk '{print $1 ":" $6}' - | sort -t ':' -k 2

}

function UNSEALKEY(){

    egrep "Unseal Key ${1:-1}" ${VaultLog:=/var/log/vault/vault_init.log} | awk -F ':' '{print $2}'

}

function ROOTTOKEN(){

    egrep "Initial Root Token" ${VaultLog:=/var/log/vault/vault_init.log} | awk -F ':' '{print $2}' | sed 's/[ ]//g'

}