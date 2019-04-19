#!/usr/bin/env bash

export k8ctl='/usr/local/bin/kubectl --namespace=consul'

function TEARDOWN(){

    ${k8ctl} delete deployment consul
    ${k8ctl} delete serviceaccount consul
    ${k8ctl} delete namespace consul

}

function BUILD(){

    # BUILDDOCKER
    BUILDNAMESPACE
    CREATESERVICEACCOUNT
    CREATEDEPLOYMENT

}

function CREATESERVICEACCOUNT(){

${k8ctl} apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: consul
#automountServiceAccountToken: true
EOF

    ${k8ctl} get serviceaccounts

}

function CREATEDEPLOYMENT(){

    ${k8ctl} apply -f ./deployment.yml

}
function BUILDDOCKER(){

    docker build -t kirscht/wmconsul:latest .
    docker push kirscht/wmconsul:latest

}

function BUILDNAMESPACE(){

    ${k8ctl} apply -f ns.yml

}

TEARDOWN
BUILD

# ${k8ctl} apply -f ./deploy_consul.yml


#${k8ctl} apply -f - <<EOF
#apiVersion: v1
#kind: Pod
#metadata:
#  name: test-projected-volume
#spec:
#  containers:
#  - name: test-projected-volume
#    image: busybox
#    args:
#    - sleep
#    - "86400"
#    volumeMounts:
#    - name: all-in-one
#      mountPath: "/projected-volume"
#      readOnly: true
#  volumes:
#  - name: all-in-one
#    projected:
#      sources:
#      - secret:
#          name: firstNode
#EOF


#  https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/