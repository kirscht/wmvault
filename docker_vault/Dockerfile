FROM vault:1.1.1

# Install requirements
#RUN apk add -U openssl curl tar gzip bash ca-certificates && \
#  wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub && \
#  wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk && \
#  apk add glibc-2.23-r3.apk && \
#  rm glibc-2.23-r3.apk

# Install kubectl
#RUN curl -L -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.6.0/bin/linux/amd64/kubectl && \
#  chmod +x /usr/bin/kubectl && \
#  kubectl version --client

# Install vault
#RUN cd /usr/local/bin && \
#  curl -L -o /usr/local/bin/vault_1.1.1_linux_amd64.zip https://releases.hashicorp.com/vault/1.1.1/vault_1.1.1_linux_amd64.zip && \
#  unzip vault_1.1.1_linux_amd64.zip && \
#  chmod +x /usr/local/bin/vault && \
#  vault -h && vault status

RUN echo "vault:1.1.1" > /IMAGE
ENV CONSUL_BIND_INTERFACE=eth0

RUN apk update && apk upgrade && apk add bash expect

#RUN mkdir /usr/local/etc

#COPY build_secret.sh .
#ADD ../usr /usr/
ADD usr /usr/
#COPY usr/local/etc/vault.cfg /usr/local/etc/vault.cfg

#COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
#COPY entrypoint.sh functions.sh /usr/local/bin/
#RUN chmod a+x /usr/local/bin/entrypoint.sh /usr/local/bin/vault /usr/local/bin/kubectl
#ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

#ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
#CMD ["agent", "-bootstrap-expect=1", "-data-dir=/consul/data", "-server"]

#ENTRYPOINT ["tail", "-f", "/dev/null"]
#CMD []

# /usr/local/bin/entrypoint.sh agent -bootstrap-expect=1 -data-dir=/consul/data -server
# consul agent -bootstrap-expect=1 -data-dir=/consul/data -server

# onsul agent -data-dir=/consul/data -retry-join 10.1.0.161

# consul agent -client 127.0.0.1 -data-dir=/consul/data

# k8ctl cp entrypoint.sh consul-5d5dd445db-5swqj:entrypoint.sh ; k8ctl exec -it consul-5d5dd445db-5swqj -- /bin/sh entrypoint.sh