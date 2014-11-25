FROM ubuntu:precise

ENV PATH /opt/nodejs/bin:$PATH
ENV COACH_USERNAME app_runner
ENV HOME /home/${COACH_USERNAME}

# use ec2 server because it's more stable
RUN echo deb http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse > /etc/apt/sources.list
RUN echo deb http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse >> /etc/apt/sources.list
RUN echo deb http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -yy build-essential libpq-dev ntp curl git-core wget tar autoconf python-setuptools redis-server python-software-properties

RUN mkdir -p /opt/nodejs
RUN curl -s http://nodejs.org/dist/v0.10.33/node-v0.10.33-linux-x64.tar.gz | tar -v -C /opt/nodejs --strip-components=1 -xz

RUN echo "IdentityFile ~/.ssh/id_rsa" >> /etc/ssh/ssh_config
RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

RUN useradd -U -m $COACH_USERNAME
WORKDIR /home/app_runner

ADD ./ ${HOME}/coach
