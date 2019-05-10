#!/usr/bin/env bash

export Deployment='consul'
export NameSpace='consulvault'
export ServiceAccountConsul='consul'
export ServiceAccountVault='vault'
export Zone="lab"

export k8ctl="/usr/local/bin/kubectl --namespace=${NameSpace}"

function TEARDOWN(){

    echo "Tearing Down Environment - Namespace: ${NameSpace}"

    ${k8ctl} delete deployment consul
    ${k8ctl} delete deployment ${Deployment}nfs
    ${k8ctl} delete pvc nfs
    ${k8ctl} delete pv nfs
    ${k8ctl} delete serviceaccount ${ServiceAccountConsul:=missing}
    ${k8ctl} delete serviceaccount ${ServiceAccountVault:=missing}
    ${k8ctl} delete namespace ${NameSpace}

}

function CREATE(){

    echo "Creating Environment - Namespace: ${NameSpace}"

    BUILDDOCKER consul
    BUILDDOCKER vault
    CREATENAMESPACE ${NameSpace}
    CREATESERVICEACCOUNT ${ServiceAccountConsul:=missing}
    CREATESERVICEACCOUNT ${ServiceAccountVault:=missing}
    #CREATE_PERSISTENTVOLUME
    #CREATE_PERSISTENTVOLUMECLAIM
    #CREATENFSDEPLOYMENT
    CREATEDEPLOYMENT consul consul

}

function CREATESERVICEACCOUNT(){

    ServiceAccount=${1}
    echo "Creating Service Account ${ServiceAccount} in Namespace ${NameSpace}"

    ${k8ctl} apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${ServiceAccount}
#automountServiceAccountToken: true
EOF

    ${k8ctl} describe serviceaccount ${ServiceAccount}

}

function CREATEDEPLOYMENT(){

    DeploymentName="${1:=none}"
    ServiceAccount="${2}"
    echo "Create Deployment ${DeploymentName} - NameSpace: ${NameSpace}"
    TEMPLATE_DEPLOYMENT_${DeploymentName} ${DeploymentName} ${ServiceAccount} | ${k8ctl} apply -f -

    ${k8ctl} describe deployment ${DeploymentName}

}

function BUILDDOCKER(){

    [[ -d /tmp/docker_${1} ]] && rm -rf /tmp/docker_${1}
    (cp -rv docker_${1} /tmp/docker_${1} && \
        cp -rv usr/ /tmp/docker_${1} && \
        cd /tmp/docker_${1} && \
        docker build -t kirscht/wm${1}:latest . && \
        docker push kirscht/wm${1}:latest && \
        rm -r /tmp/docker_${1})

}

function TEMPLATE_DEPLOYMENT_consul(){

    DeploymentName="${1:=none}"
    ServiceAccount="${2}"

cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DeploymentName}
  labels:
    app: "${DeploymentName}"
    zone: "${Zone:=lab}"
    version: "20190411_1"
spec:
  selector:
    matchLabels:
      app: ${DeploymentName}
  replicas: 3
  template:
    metadata:
      labels:
        app: ${DeploymentName}
        name: ${DeploymentName}
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
            - name: VAULT_ADDR
              value: http://127.0.0.1:8200
            - name: Deployment
              value: ${DeploymentName}
            - name: NameSpace
              value: ${NameSpace}
            - name: ServiceAccount
              value: ${ServiceAccount}
          #volumeMounts:
          #  - mountPath: /var/log/vault
          #    name: mypvc
      #volumes:
      #  - name: mypvc
      #    persistentVolumeClaim:
      #      claimName: nfs
EOF
}

function CREATENFSDEPLOYMENT(){

    TEMPLATE_NFS_DEPLOYMENT | ${k8ctl} apply -f -

}

function TEMPLATE_NFS_DEPLOYMENT(){

#  https://github.com/kubernetes/examples/tree/master/staging/volumes/nfs

cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${Deployment}nfs
  labels:
    app: "${Deployment}nfs"
    zone: "${Zone:=lab}"
    version: "20190411_1"
spec:
  selector:
    matchLabels:
      app: ${Deployment}nfs
  replicas: 3
  template:
    metadata:
      labels:
        app: ${Deployment}nfs
        name: ${Deployment}nfs

    spec:
      serviceAccountName: ${ServiceAccount}
      containers:
      - name: nfs-server
        image: k8s.gcr.io/volume-nfs:0.8
        env:
          - name: HOST_IP
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
          - name: VAULT_ADDR
            value: http://127.0.0.1:8200
          - name: Deployment
            value: ${Deployment}nfs
          - name: NameSpace
            value: ${NameSpace}
          - name: ServiceAccount
            value: ${ServiceAccount}
        ports:
          - name: nfs
            containerPort: 2049
          - name: mountd
            containerPort: 20048
          - name: rpcbind
            containerPort: 111
        securityContext:
          privileged: true
        volumeMounts:
          - mountPath: /exports
            name: mypvc
      volumes:
        - name: mypvc
          persistentVolumeClaim:
            claimName: nfs
EOF
}

function TEMPLATE_NAMESPACE() {

cat <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${1}
  labels:
    app: ${1}
    zone: ${Zone:=lab}
    version: ${VERSION:-v0.0}
EOF

}
function CREATENAMESPACE(){

    echo "Create Namespace ${1}"

    TEMPLATE_NAMESPACE ${1} | ${k8ctl} apply -f -
    kubectl describe namespace ${1}

}

function CREATE_PERSISTENTVOLUME(){

    TEMPLATE_PERSISTENTVOLUME | ${k8ctl} apply -f -

}


function TEMPLATE_PERSISTENTVOLUME(){

cat <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs
spec:
  storageClassName: hostpath
  capacity:
    storage: 1Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/Users/kkirscht/nfs"
  #nfs:
  #  server: nfs-server.default.svc.cluster.local
  #  path: "/Users/kkirscht/nfs"
EOF

}

function CREATE_PERSISTENTVOLUMECLAIM(){

    TEMPLATE_PERSISTENTVOLUMECLAIM | ${k8ctl} apply -f -

}

function TEMPLATE_PERSISTENTVOLUMECLAIM(){

cat <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: "hostpath"
  resources:
    requests:
      storage: 1Mi
EOF

}


TEARDOWN
CREATE


#  https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
