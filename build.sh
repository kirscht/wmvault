#!/usr/bin/env bash

export Deployment='consul'
export NameSpace='consul'
export ServiceAccount='consul'

export k8ctl='/usr/local/bin/kubectl --namespace=consul'

function TEARDOWN(){

    ${k8ctl} delete deployment ${Deployment}
    ${k8ctl} delete serviceaccount ${ServiceAccount}
    ${k8ctl} delete namespace ${NameSpace}

}

function CREATE(){

    BUILDDOCKER
    CREATENAMESPACE
    CREATESERVICEACCOUNT
    CREATEDEPLOYMENT

}

function CREATESERVICEACCOUNT(){

${k8ctl} apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${ServiceAccount}
#automountServiceAccountToken: true
EOF

    ${k8ctl} get serviceaccounts

}

function CREATEDEPLOYMENT(){

    TEMPLATE_DEPLOYMENT | ${k8ctl} apply -f -

}
function BUILDDOCKER(){

    docker build -t kirscht/wmconsul:latest .
    docker push kirscht/wmconsul:latest

}

function TEMPLATE_DEPLOYMENT(){

cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${Deployment}
  labels:
    app: "${Deployment}"
    zone: "lab"
    version: "20190411_1"
spec:
  selector:
    matchLabels:
      app: ${Deployment}
  replicas: 3
  template:
    metadata:
      labels:
        app: ${Deployment}
        name: ${Deployment}
    spec:
      serviceAccountName: ${ServiceAccount}
      containers:
        - name: shell
          image: "kirscht/wmconsul:latest"
          env:
            - name: HOST_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: Deployment
              value: ${Deployment}
            - name: NameSpace
              value: ${NameSpace}
            - name: ServiceAccount
              value: ${ServiceAccount}
EOF
}

function TEMPLATE_NAMESPACE() {

cat <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: consul
  labels:
    app: consul
    zone: lab
    version: v1
EOF

}
function CREATENAMESPACE(){

    TEMPLATE_NAMESPACE | ${k8ctl} apply -f -

}

TEARDOWN
CREATE


#  https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/