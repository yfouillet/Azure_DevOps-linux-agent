FROM centos/systemd

#docker run -it --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -e VSTS_ACCOUNT=<name> -e VSTS_TOKEN=<pat> -e VSTS_AGENT_NAME=<name>  yfouillet/azure_devops-linux-agent
# VSTS_AGENT_NAME=<name> is optional, the hostname will be used if the option is not used

#docker build . -t yfouillet/azure_devops-linux-agent:1.0.0
# "yum --showduplicates list <package> for check versions available for package

ENV GIT_VERSION "v2.21.0"
ENV HELM_VERSION "v2.13.1"
ENV AGENT_VERSION "2.150.0"
ENV PYTHON_VERSION "2.7.5-77.el7_6"
ENV DOCKER_VERSION "18.09.5-3.el7"
ENV KUBECTL_VERSION "1.14.1-0"
ENV AZURECLI_VERSION "2.0.63-1.el7"
ENV GCP_SDK_VERSION "243.0.0-1.el7"
ENV ASPNETCORE_RUNTIME_2_1_VERSION "2.1.10-1"

RUN yum groupinstall "Development Tools" -y
#RUN yum install autoconf libcurl-devel expat-devel gcc gettext-devel kernel-headers openssl-devel perl-devel zlib-devel -y
RUN yum install autoconf libcurl-devel expat-devel gcc gettext-devel kernel-headers openssl-devel perl-devel -y
RUN yum install sudo openssh-clients -y
RUN useradd -u 10000 agent-user
RUN sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
RUN usermod -aG wheel agent-user

#RUN yum update -y
RUN yum install python -y
RUN yum install ca-certificates -y
RUN yum install -y wget

# Install git

RUN mkdir /tmp/git
RUN wget https://github.com/git/git/archive/${GIT_VERSION}.tar.gz -O /tmp/git.tar.gz
RUN tar -xvf /tmp/git.tar.gz -C /tmp/git/ --strip-components=1
RUN cd /tmp/git/ && make prefix=/usr/local/git all
RUN cd /tmp/git/ && make prefix=/usr/local/git install

#RUN yum install centos-release-scl-rh -y
#RUN yum install rh-git${GIT_MAJOR_VERSION}-${GIT_VERSION} -y

# install Helm

RUN wget https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -O helm.tar.gz --no-check-certificate
RUN tar -zxvf helm.tar.gz
RUN mv linux-amd64/helm /usr/local/bin/helm
RUN rm -rf linux-amd64 helm.tar.gz


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
RUN yum install docker-ce-${DOCKER_VERSION} docker-ce-cli containerd.io -y
RUN usermod -aG docker agent-user


# install kubectl
# OFFICIAL LINK https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux
RUN sh -c 'echo -e "[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" > /etc/yum.repos.d/kubernetes.repo'
RUN yum install kubectl-${KUBECTL_VERSION} -y

# install Azure CLI
# Official install link https://docs.microsoft.com/fr-fr/cli/azure/install-azure-cli-yum?view=azure-cli-latest
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
RUN sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
RUN yum install azure-cli-${AZURECLI_VERSION} -y

# install Google cloud cli

#RUN wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-243.0.0-linux-x86_64.tar.gz -O /tmp/google-cloud-sdk.tar.gz
RUN sh -c 'echo -e "[google-cloud-sdk]\nname=Google Cloud SDK\nbaseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" > /etc/yum.repos.d/gcloud-cli.repo'
RUN yum install google-cloud-sdk-${GCP_SDK_VERSION} -y

# install Dotnet core 2.1
# Official link https://dotnet.microsoft.com/download/linux-package-manager/centos/runtime-2.1.0
RUN rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
RUN yum install aspnetcore-runtime-2.1-${ASPNETCORE_RUNTIME_2_1_VERSION} -y

# install AzureDevops Agent

RUN mkdir -p /vsts-agent-linux/_work
COPY start.sh /vsts-agent-linux/

RUN chown -R agent-user:agent-user /vsts-agent-linux/
RUN chmod +x /vsts-agent-linux/start.sh
#RUN chmod 755 /vsts-agent-linux/dockerd.sh
RUN chmod u+s /usr/bin/dockerd-ce

USER agent-user
RUN wget https://vstsagentpackage.azureedge.net/agent/2.150.0/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz -O /tmp/vsts-agent-linux.tar.gz
RUN tar -zxvf /tmp/vsts-agent-linux.tar.gz -C /vsts-agent-linux/ --strip-components=1
USER root
# Clean system

RUN yum remove git -y
# priority path for git
#RUN ln -s /opt/rh/rh-git218/root/usr/libexec/git-core/git /usr/bin/git
RUN ln -s /usr/local/git/bin/git /usr/bin/git

RUN yum groupremove "Development Tools" -y
RUN yum remove autoconf libcurl-devel expat-devel gcc gettext-devel kernel-headers openssl-devel perl-devel zlib-devel -y
RUN yum remove git -y

RUN yum autoremove -y
RUN yum clean all
RUN rm -rf /tmp/*
RUN rm -rf /var/cache/yum



USER agent-user

WORKDIR "/vsts-agent-linux/"
CMD ["/bin/sh", "/vsts-agent-linux/start.sh"]
