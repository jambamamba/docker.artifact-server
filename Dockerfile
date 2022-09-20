FROM ubuntu-minimal:focal

ENV PATH="${PATH}:/usr/games:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/data/klocwork/server20.3/bin"

RUN DEBIAN_FRONTEND=noninteractive apt-get update &&\
    	echo "tzdata tzdata/Areas select Europe \
tzdata tzdata/Zones/Europe select Berlin" > /tmp/preseed.txt &&\
    	debconf-set-selections /tmp/preseed.txt
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
	apt-transport-https \
	software-properties-common \
	build-essential \
	chrpath \
	coreutils \
	libssl-dev \
	net-tools \
	openssh-server \
	pigz \
	tzdata \
	unzip \
	vim \
	wget \
	xterm \
	xz-utils && \
	rm -fr /var/lib/apt/lists/* && \
	apt-get clean
	
COPY in/.ssh /home/dev/
COPY in/etc.nginx.sites-available.default /tmp/

COPY tmp/run.sh /tmp/
RUN /tmp/run.sh installNginx
RUN /tmp/run.sh installPonysay
RUN /tmp/run.sh createUser user="dev" sudo=""
RUN /tmp/run.sh installSudo
RUN /tmp/run.sh noPassword user="dev" sudo=""

RUN rm -f /tmp/run.sh
USER dev
