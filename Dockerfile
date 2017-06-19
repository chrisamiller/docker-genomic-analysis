FROM ubuntu:xenial
MAINTAINER Chris Miller <c.a.miller@wustl.edu>

LABEL "Image for basic ad-hoc bioinformatic analyses" 

RUN apt-get update -y && apt-get install -y \
    wget \
    git \
    unzip \
    bzip2 \
    g++ \
    make \
    zlib1g-dev \
    ncurses-dev \
    python \
    rsync \
    default-jdk \
    default-jre \
    unzip \
    curl \
    ant \
    emacs \
    emacs-goodies-el \
    python-pip \
    python-dev \
    build-essential \
    nodejs \
    libpng-dev \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev
    
RUN pip install --upgrade pip

##############
#HTSlib 1.3.2#
##############
ENV HTSLIB_INSTALL_DIR=/opt/htslib

WORKDIR /tmp
RUN wget https://github.com/samtools/htslib/releases/download/1.3.2/htslib-1.3.2.tar.bz2 && \
    tar --bzip2 -xvf htslib-1.3.2.tar.bz2

WORKDIR /tmp/htslib-1.3.2
RUN ./configure  --enable-plugins --prefix=$HTSLIB_INSTALL_DIR && \
    make && \
    make install && \
    cp $HTSLIB_INSTALL_DIR/lib/libhts.so* /usr/lib/

################
#Samtools 1.3.1#
################
ENV SAMTOOLS_INSTALL_DIR=/opt/samtools

WORKDIR /tmp
RUN wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
    tar --bzip2 -xf samtools-1.3.1.tar.bz2

WORKDIR /tmp/samtools-1.3.1
RUN ./configure --with-htslib=$HTSLIB_INSTALL_DIR --prefix=$SAMTOOLS_INSTALL_DIR && \
    make && \
    make install

WORKDIR /
RUN rm -rf /tmp/samtools-1.3.1

###############
#bam-readcount#
###############
RUN apt-get install -y \
        cmake \
        patch \
        git

ENV SAMTOOLS_ROOT=/opt/samtools
RUN mkdir /opt/bam-readcount

WORKDIR /opt/bam-readcount
RUN git clone https://github.com/genome/bam-readcount.git /tmp/bam-readcount-0.7.4 && \
    git -C /tmp/bam-readcount-0.7.4 checkout v0.7.4 && \
    cmake /tmp/bam-readcount-0.7.4 && \
    make && \
    rm -rf /tmp/bam-readcount-0.7.4 && \
    ln -s /opt/bam-readcount/bin/bam-readcount /usr/bin/bam-readcount

COPY bam_readcount_helper.py /usr/bin/bam_readcount_helper.py

RUN pip install cyvcf2

#######
#tabix#
#######
RUN ln -s $HTSLIB_INSTALL_DIR/bin/tabix /usr/bin/tabix

################
#bcftools 1.3.1#
################
ENV BCFTOOLS_INSTALL_DIR=/opt/bcftools

WORKDIR /tmp
RUN wget https://github.com/samtools/bcftools/releases/download/1.3.1/bcftools-1.3.1.tar.bz2 && \
    tar --bzip2 -xf bcftools-1.3.1.tar.bz2

WORKDIR /tmp/bcftools-1.3.1
RUN make prefix=$BCFTOOLS_INSTALL_DIR && \
    make prefix=$BCFTOOLS_INSTALL_DIR install

WORKDIR /
RUN rm -rf /tmp/bcftools-1.3.1

##############
#Picard 2.4.1#
##############
ENV picard_version 2.4.1

# Install ant, git for building

# Assumes Dockerfile lives in root of the git repo. Pull source files into
# container
RUN cd /usr/ && git config --global http.sslVerify false && git clone --recursive https://github.com/broadinstitute/picard.git && cd /usr/picard && git checkout tags/${picard_version}
WORKDIR /usr/picard

# Clone out htsjdk. First turn off git ssl verification
RUN git config --global http.sslVerify false && git clone https://github.com/samtools/htsjdk.git && cd htsjdk && git checkout tags/${picard_version} && cd ..

# Build the distribution jar, clean up everything else
RUN ant clean all && \
    mv dist/picard.jar picard.jar && \
    mv src/scripts/picard/docker_helper.sh docker_helper.sh && \
    ant clean && \
    rm -rf htsjdk && \
    rm -rf src && \
    rm -rf lib && \
    rm build.xml

COPY split_interval_list_helper.pl /usr/bin/split_interval_list_helper.pl

#############
#verifyBamId#
#############
RUN apt-get install -y build-essential gcc-multilib apt-utils zlib1g-dev git

RUN cd /tmp/ && git clone https://github.com/statgen/verifyBamID.git && git clone https://github.com/statgen/libStatGen.git

RUN cd /tmp/libStatGen && git checkout tags/v1.0.14

RUN cd /tmp/verifyBamID && git checkout tags/v1.1.3 && make

RUN cp /tmp/verifyBamID/bin/verifyBamID /usr/local/bin

RUN rm -rf /tmp/verifyBamID /tmp/libStatGen

    
#############
## IGV 3.0 ##

RUN apt-get install -y \
    software-properties-common \
    glib-networking-common

RUN mkdir -p /igv && \
    cd /igv && \
    wget http://data.broadinstitute.org/igv/projects/downloads/3.0_beta/IGV_3.0_beta.zip && \
    unzip IGV_3.0_beta.zip && \
    cd IGV_3.0_beta && \
    sed -i 's/Xmx4000/Xmx8000/g' igv.sh && \
    cd /usr/bin && \
    ln -s /igv/IGV_3.0_beta/igv.sh ./igv

##############
## bedtools ##

WORKDIR /usr/local
RUN git clone https://github.com/arq5x/bedtools2.git
WORKDIR /usr/local/bedtools2
RUN git checkout v2.25.0
RUN pwd
RUN make
RUN ln -s /usr/local/bedtools2/bin/* /usr/local/bin/

##############
## vcftools ##
ENV ZIP=vcftools-0.1.14.tar.gz
ENV URL=https://github.com/vcftools/vcftools/releases/download/v0.1.14/
ENV FOLDER=vcftools-0.1.14
ENV DST=/tmp

RUN wget $URL/$ZIP -O $DST/$ZIP && \
    tar xvf $DST/$ZIP -C $DST && \
    rm $DST/$ZIP && \
    cd $DST/$FOLDER && \
    ./configure && \
    make && \
    make install && \
    cd / && \
    rm -rf $DST/$FOLDER


#Cleanup
RUN apt-get clean


############################
# R, bioconductor packages #
###########################
# from https://raw.githubusercontent.com/rocker-org/rocker-versioned/master/r-ver/3.4.0/Dockerfile
# we'll pin to 3.4.0 for now

ARG R_VERSION
ARG BUILD_DATE
ENV BUILD_DATE ${BUILD_DATE:-}
ENV R_VERSION=${R_VERSION:-3.4.0}
RUN apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    LC_ALL=en_US.UTF-8 && \
    LANG=en_US.UTF-8 && \
    TERM=xterm

## dependencies
RUN apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    libbz2-1.0 \
    libcurl3 \
    libicu55 \
    libjpeg-turbo8 \
    libopenblas-dev \
    libpangocairo-1.0-0 \
    libpcre3 \
    libpng12-0 \
    libtiff5 \
    liblzma5 \
    locales \
    make \
    unzip \
    zip \
    zlib1g \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_US.utf8 \
  && /usr/sbin/update-locale LANG=en_US.UTF-8 \
  && BUILDDEPS="curl \
    default-jdk \
    libbz2-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libicu-dev \
    libpcre3-dev \
    libpng-dev \
    libreadline-dev \
    libtiff5-dev \
    liblzma-dev \
    libx11-dev \
    libxt-dev \
    perl \
    tcl8.5-dev \
    tk8.5-dev \
    texinfo \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-recommended \
    x11proto-core-dev \
    xauth \
    xfonts-base \
    xvfb \
    zlib1g-dev" \
  && apt-get install -y --no-install-recommends $BUILDDEPS \
  && cd tmp/ \
  ## Download source code
  && curl -O https://cran.r-project.org/src/base/R-3/R-${R_VERSION}.tar.gz \
  ## Extract source code
  && tar -xf R-${R_VERSION}.tar.gz \
  && cd R-${R_VERSION} \
  ## Set compiler flags
  && R_PAPERSIZE=letter \
    R_BATCHSAVE="--no-save --no-restore" \
    R_BROWSER=xdg-open \
    PAGER=/usr/bin/pager \
    PERL=/usr/bin/perl \
    R_UNZIPCMD=/usr/bin/unzip \
    R_ZIPCMD=/usr/bin/zip \
    R_PRINTCMD=/usr/bin/lpr \
    LIBnn=lib \
    AWK=/usr/bin/awk \
    CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
    CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
  ## Configure options
  ./configure --enable-R-shlib \
               --enable-memory-profiling \
               --with-readline \
               --with-blas="-lopenblas" \
               --disable-nls \
               --without-recommended-packages \
  ## Build and install
  && make \
  && make install \
  ## Add a default CRAN mirror
  && echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site \
  ## Add a library directory (for user-installed packages)
  && mkdir -p /usr/local/lib/R/site-library \
  && chown root:staff /usr/local/lib/R/site-library \
  && chmod g+wx /usr/local/lib/R/site-library \
  ## Fix library path
  && echo "R_LIBS_USER='/usr/local/lib/R/site-library'" >> /usr/local/lib/R/etc/Renviron \
  && echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron \
  ## install packages from date-locked MRAN snapshot of CRAN
  && [ -z "$BUILD_DATE" ] && BUILD_DATE=$(TZ="America/Los_Angeles" date -I) || true \
  && MRAN=https://mran.microsoft.com/snapshot/${BUILD_DATE} \
  && echo MRAN=$MRAN >> /etc/environment \
  && export MRAN=$MRAN \
  && echo "options(repos = c(CRAN='$MRAN'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site \
  ## Use littler installation scripts
  && Rscript -e "install.packages(c('littler', 'docopt'), repo = '$MRAN')" \
  && ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
  && ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
  && ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r \
  ## Clean up from R source install
  && cd / \
  && rm -rf /tmp/* \
  && apt-get remove --purge -y $BUILDDEPS \
  && apt-get autoremove -y \
  && apt-get autoclean -y \
  && rm -rf /var/lib/apt/lists/*

## install r packages, bioconductor, etc ##
ADD rpackages.R /tmp/
RUN R -f /tmp/rpackages.R

## install fishplot ##
RUN cd /tmp/ && \
    wget https://github.com/chrisamiller/fishplot/archive/v0.4.tar.gz && \
    mv v0.4.tar.gz fishplot_0.4.tar.gz && \
    R CMD INSTALL fishplot_0.4.tar.gz && \
    cd && rm -rf /tmp/fishplot_0.4.tar.gz
    
##################
# ucsc utilities #
RUN mkdir -p /tmp/ucsc && \
    cd /tmp/ucsc && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigBedToBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigAverageOverBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigToBedGraph http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/wigToBigWig && \
    chmod ugo+x * && \
    mv * /usr/bin/

