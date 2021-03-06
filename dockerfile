
##################
###--- User ---###
##################

FROM    ubuntu:bionic AS french

#-- Time-Zone setup
RUN     ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
RUN     apt-get update && apt-get install --no-install-recommends \
            tzdata \
            && rm -rf /var/lib/apt/lists/*

#-- Locales setup
RUN     apt-get update && apt-get install --no-install-recommends \
            locales \
            && rm -rf /var/lib/apt/lists/*
RUN     locale-gen fr_FR.UTF-8
RUN     update-locale LANG=fr_FR.UTF-8 LANGUAGE=fr_FR.UTF-8 LC_ALL=fr_FR.UTF-8

#-- main user creation --#
RUN     useradd ubuntu --create-home --shell /bin/bash
RUN     echo "ubuntu:ubuntu" | chpasswd

USER    ubuntu
WORKDIR /home/ubuntu

ENV     LANG=fr_FR.UTF-8
ENV     LC_ALL=fr_FR.UTF-8
ENV     LANGUAGE=fr_FR.UTF-8


###############
###--- R ---###
###############

FROM french AS r0

USER    root
RUN     mkdir /install
WORKDIR /install

RUN     apt-get update && apt-get install --no-install-recommends --assume-yes \
            gnupg \
            software-properties-common \
            dirmngr \
            wget \
            sudo \
            # Development packages
            build-essential \
            && rm -rf /var/lib/apt/lists/*
RUN     wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN     add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN     apt-get update && apt-get install --no-install-recommends --assume-yes \
            r-base \
            r-base-dev \
            && rm -rf /var/lib/apt/lists/*

###############################
#-- R packages dependencies --#
###############################

# locally built
COPY    install-packages.R .
RUN     apt-get update && apt-get install --no-install-recommends --assume-yes \
            libxml2-dev libgit2-dev libssl-dev \
            && rm -rf /var/lib/apt/lists/*
RUN     sudo Rscript install-packages.R CRAN devtools
RUN     apt-get update && apt-get install --no-install-recommends --assume-yes \
            libfontconfig1-dev \
            && rm -rf /var/lib/apt/lists/*
RUN     sudo Rscript install-packages.R CRAN tidyverse
RUN     sudo Rscript install-packages.R CRAN languageserver
RUN     sudo Rscript install-packages.R CRAN dotenv

#####################
###--- RSTUDIO ---###
#####################

FROM    r0 AS rstudio
USER    root
WORKDIR /install

ARG     RSTUDIO_VERSION=2022.02.0-443
ARG     RSTUDIO_PUBLICKEY=3F32EE77E331692F
ARG     RSTUDIO_FILE=rstudio-server-${RSTUDIO_VERSION}-amd64.deb
ARG     RSTUDIO_SITE=https://download2.rstudio.org/server/bionic/amd64/${RSTUDIO_FILE}

RUN     apt-get update && apt-get install --no-install-recommends --assume-yes \
            gnupg \
            wget \
            dpkg-sig \
            gdebi-core \
            sudo \
            # RSTUDIO dependencies
            psmisc \
            libedit2 \
            libclang-dev \
            libssl1.0.0:amd64 \
            libpq5 \
            libapparmor1 \
            && rm -rf /var/lib/apt/lists/*
RUN     gpg --keyserver keyserver.ubuntu.com --recv-keys ${RSTUDIO_PUBLICKEY}
RUN     wget ${RSTUDIO_SITE}
RUN     dpkg-sig --verify ${RSTUDIO_FILE} && gdebi -n ${RSTUDIO_FILE}

######################
#-- Launch RStudio --#
######################

RUN     echo "ubuntu ALL=(ALL) NOPASSWD: /usr/sbin/rstudio-server" >> /etc/sudoers
WORKDIR /home/ubuntu
RUN     rm -fR /install
USER    ubuntu

EXPOSE  8787
ENTRYPOINT sudo rstudio-server start && tail -f /dev/null

####################
#-- R entrypoint --#
####################

FROM    r0 AS r
WORKDIR /home/ubuntu
RUN     rm -fR /install
USER    ubuntu
