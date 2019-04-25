FROM centos:7

#docker run -it  -e VSTS_ACCOUNT=<name> -e VSTS_TOKEN=<pat>  azure-devops-agent 
#ENV GIT_VERSION "v2.21.0"
RUN useradd -u 10000 agent-user


#RUN yum update -y
RUN yum install python -y
RUN yum install ca-certificates -y
RUN yum groupinstall "Development Tools" -y
RUN yum install autoconf libcurl-devel expat-devel gcc gettext-devel kernel-headers openssl-devel perl-devel zlib-devel -y

RUN yum install -y wget

# Install git
RUN mkdir /tmp/git
RUN wget https://github.com/git/git/archive/v2.21.0.tar.gz -O /tmp/git.tar.gz
RUN tar -xvf /tmp/git.tar.gz -C /tmp/git/ --strip-components=1
RUN cd /tmp/git/ && make prefix=/usr/local/git all
RUN cd /tmp/git/ && make prefix=/usr/local/git install

# priority path for git
RUN ln -s /usr/local/sbin/git /usr/local/git

# Docker install

RUN yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
RUN yum install -y yum-utils device-mapper-persistent-data lvm2 -y
RUN yum-config-manager  --add-repo https://download.docker.com/linux/centos/docker-ce.repo -y
RUN yum install docker-ce docker-ce-cli containerd.io -y

# install Helm

RUN wget https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz -O /tmp/helm.tar.gz
RUN tar -zxvf /tmp/helm.tar.gz linux-amd64/helm -C /usr/local/bin/ --strip-components=1

# install kubectl
# OFFICIAL LINK https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux
RUN sh -c 'echo -e "[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" > /etc/yum.repos.d/kubernetes.repo'
RUN yum install kubectl -y


# install Azure CLI
# Official install link https://docs.microsoft.com/fr-fr/cli/azure/install-azure-cli-yum?view=azure-cli-latest
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
RUN sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
RUN yum install azure-cli -y


# install Google cloud cli

RUN wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-243.0.0-linux-x86_64.tar.gz -O /tmp/google-cloud-sdk.tar.gz
RUN sh -c 'echo -e "[google-cloud-sdk]\nname=Google Cloud SDK\nbaseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" > /etc/yum.repos.d/gcloud-cli.repo'
RUN yum install google-cloud-sdk -y

# install Dotnet core 2.1
# Official link https://dotnet.microsoft.com/download/linux-package-manager/centos/runtime-2.1.0
RUN rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
RUN yum install aspnetcore-runtime-2.1 -y

# install AzureDevops Agent

RUN mkdir -p /vsts-agent-linux/_work
COPY start.sh /vsts-agent-linux/
RUN wget https://vstsagentpackage.azureedge.net/agent/2.150.0/vsts-agent-linux-x64-2.150.0.tar.gz -O /tmp/vsts-agent-linux.tar.gz
RUN tar -zxvf /tmp/vsts-agent-linux.tar.gz -C /vsts-agent-linux/ --strip-components=1
RUN chown -R agent-user /vsts-agent-linux 
RUN chmod +x /vsts-agent-linux/start.sh

# Clean system

RUN yum groupremove "Development Tools" -y
RUN yum remove autoconf libcurl-devel expat-devel gcc gettext-devel kernel-headers openssl-devel perl-devel zlib-devel -y
RUN yum remove git -y

RUN yum autoremove -y
RUN yum clean all
RUN rm -rf /tmp/*

User agent-user

Workdir ["/vsts-agent-linux"]
CMD ["/bin/sh", "/vsts-agent-linux/start.sh"]
#ENTRYPOINT ["sh -C", "/vsts-agent-linux/start.sh"]
