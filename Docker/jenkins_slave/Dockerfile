FROM jenkins/jnlp-slave
# if we want to install via apt
USER root
# terraform version
ENV VER="0.12.16"
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
  && rm -rf /var/lib/apt/lists/*

RUN wget --quiet https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_linux_amd64.zip \
  && unzip terraform_${VER}_linux_amd64.zip \
  && mv terraform /usr/local/bin \
  && rm terraform_${VER}_linux_amd64.zip

USER jenkins
