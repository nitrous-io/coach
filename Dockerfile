FROM ubuntu

ENV PATH /opt/nodejs/bin:$PATH
ENV COACH_USERNAME app_runner
ENV HOME /home/${COACH_USERNAME}

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -yy python-software-properties
RUN add-apt-repository http://ppa.launchpad.net/brightbox/experimental/ubuntu
RUN apt-get update

RUN apt-get install -yy build-essential libpq-dev ntp curl git-core wget tar autoconf python-setuptools redis-server
RUN mkdir -p /opt/nodejs
RUN curl -s http://nodejs.org/dist/v0.8.25/node-v0.8.25-linux-x64.tar.gz | tar -v -C /opt/nodejs --strip-components=1 -xz
RUN curl https://npmjs.org/install.sh | clean=no sh

ADD github_rsa /root/.ssh/id_rsa
RUN echo "IdentityFile ~/.ssh/id_rsa" >> /etc/ssh/ssh_config
RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

RUN useradd -U -m $COACH_USERNAME
WORKDIR /home/app_runner

ADD ./ ${HOME}/coach

RUN cd ${HOME}/coach && git submodule init && git submodule update
RUN cd ${HOME}/coach && npm install

# Get rid of color in mocha for CI
RUN echo "--no-colors" >> ${HOME}/coach/test/mocha.opts
