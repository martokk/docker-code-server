FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"

RUN \
  echo "\n\n**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
  git \
  jq \
  libatomic1 \
  nano \
  net-tools \
  netcat \
  sudo && \
  echo "\n\n**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
  CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
  | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  curl -o \
  /tmp/code-server.tar.gz -L \
  "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C \
  /app/code-server --strip-components=1 && \
  echo "\n\n**** clean up ****" && \
  apt-get clean && \
  rm -rf \
  /config/* \
  /tmp/* \
  /var/lib/apt/lists/* \
  /var/tmp/*

RUN \
  echo "\n\n**** install customizations: dependencies ****" && \
  apt-get update && \
  apt-get install -y \
  software-properties-common \
  fontconfig \
  gpg \
  unzip \
  wget && \
  echo "\n\n**** install python3.10 ****" && \
  echo "deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/deadsnakes.list && \
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA6932366A755776 && \
  echo "deb http://security.ubuntu.com/ubuntu focal-security main" | sudo tee /etc/apt/sources.list.d/focal-security.list && \
  sudo apt-get update && \
  sudo apt-get install libssl1.1 python3.10 python3.10-dev python3.10-venv python3.10-distutils python3.10-tk -y && \
  curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10 && \
  python3.10 -m pip install --upgrade pip && \
  python3.10 -m pip install wheel && \
  echo "\n\n**** pulling dotfiles ****" && \
  git clone https://github.com/martokk/dotfiles /root/dotfiles && \
  echo "\n\n**** clean up ****" && \
  apt-get clean && \
  rm -rf \
  /config/* \
  /tmp/* \
  /var/lib/apt/lists/* \
  /var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
