FROM ubuntu:xenial
MAINTAINER Chris Miller <c.a.miller@wustl.edu>

LABEL "Image for basic ad-hoc bioinformatic analyses"

#some basic tools
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    wget \
    git \
    unzip \
    zip \
    bzip2 \
    g++ \
    make \
    build-essential \
    zlib1g-dev \
    ncurses-dev \
    python \
    rsync \
    default-jdk \
    default-jre \
    unzip \
    curl \
    emacs \
    emacs-goodies-el \
    python-pip \
    python-dev \
    build-essential \
    nodejs \
    libpng-dev \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    pkg-config && \
    pip install --upgrade pip

##############
#HTSlib 1.3.2#
##############
ENV HTSLIB_INSTALL_DIR=/opt/htslib

WORKDIR /tmp
RUN wget https://github.com/samtools/htslib/releases/download/1.3.2/htslib-1.3.2.tar.bz2 && \
    tar --bzip2 -xvf htslib-1.3.2.tar.bz2 && \
    cd /tmp/htslib-1.3.2 && \
    ./configure  --enable-plugins --prefix=$HTSLIB_INSTALL_DIR && \
    make && \
    make install && \
    cp $HTSLIB_INSTALL_DIR/lib/libhts.so* /usr/lib/ && \
    ln -s $HTSLIB_INSTALL_DIR/bin/tabix /usr/bin/tabix

################
#Samtools 1.3.1#
################
ENV SAMTOOLS_INSTALL_DIR=/opt/samtools

WORKDIR /tmp
RUN wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
    tar --bzip2 -xf samtools-1.3.1.tar.bz2 && \
    cd /tmp/samtools-1.3.1 && \
    ./configure --with-htslib=$HTSLIB_INSTALL_DIR --prefix=$SAMTOOLS_INSTALL_DIR && \
    make && \
    make install && \
    cd / && \
    RUN rm -rf /tmp/samtools-1.3.1

###############
#bam-readcount#
###############
ENV SAMTOOLS_ROOT=/opt/samtools
RUN apt-get update && apt-get install -y --no-install-recommends \
        cmake \
        patch && \
    mkdir /opt/bam-readcount && \
    cd /opt/bam-readcount && \
    git clone https://github.com/genome/bam-readcount.git /tmp/bam-readcount-0.7.4 && \
    git -C /tmp/bam-readcount-0.7.4 checkout v0.7.4 && \
    cmake /tmp/bam-readcount-0.7.4 && \
    make && \
    rm -rf /tmp/bam-readcount-0.7.4 && \
    ln -s /opt/bam-readcount/bin/bam-readcount /usr/bin/bam-readcount && \
    pip install cyvcf2

COPY bam_readcount_helper.py /usr/bin/bam_readcount_helper.py

################
#bcftools 1.3.1#
################
ENV BCFTOOLS_INSTALL_DIR=/opt/bcftools
WORKDIR /tmp
RUN wget https://github.com/samtools/bcftools/releases/download/1.3.1/bcftools-1.3.1.tar.bz2 && \
    tar --bzip2 -xf bcftools-1.3.1.tar.bz2 && \
    cd /tmp/bcftools-1.3.1 && \
    make prefix=$BCFTOOLS_INSTALL_DIR && \
    make prefix=$BCFTOOLS_INSTALL_DIR install && \
    cd / && \
    rm -rf /tmp/bcftools-1.3.1


##############
#Picard 2.4.1#
##############
ENV picard_version 2.4.1

# Assumes Dockerfile lives in root of the git repo. Pull source files into
# container
RUN apt-get update && apt-get install ant --no-install-recommends -y && \
    cd /usr/ && \
    git config --global http.sslVerify false && \
    git clone --recursive https://github.com/broadinstitute/picard.git && \
    cd /usr/picard && \
    git checkout tags/${picard_version} && \
    cd /usr/picard && \
    # Clone out htsjdk. First turn off git ssl verification
    git config --global http.sslVerify false && \
    git clone https://github.com/samtools/htsjdk.git && \
    cd htsjdk && \
    git checkout tags/${picard_version} && \
    cd .. && \
    # Build the distribution jar, clean up everything else
    ant clean all && \
    mv dist/picard.jar picard.jar && \
    mv src/scripts/picard/docker_helper.sh docker_helper.sh && \
    ant clean && \
    rm -rf htsjdk && \
    rm -rf src && \
    rm -rf lib && \
    rm build.xml

COPY split_interval_list_helper.pl /usr/bin/split_interval_list_helper.pl


#############
## IGV 3.0 ##

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    glib-networking-common && \
    mkdir -p /igv && \
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
RUN git clone https://github.com/arq5x/bedtools2.git && \
    cd /usr/local/bedtools2 && \
    git checkout v2.25.0 && \
    make && \
    ln -s /usr/local/bedtools2/bin/* /usr/local/bin/


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


##################
# ucsc utilities #
RUN mkdir -p /tmp/ucsc && \
    cd /tmp/ucsc && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigBedToBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigAverageOverBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigToBedGraph http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/wigToBigWig && \
    chmod ugo+x * && \
    mv * /usr/bin/


############################
# R, bioconductor packages #
# from https://raw.githubusercontent.com/rocker-org/rocker-versioned/master/r-ver/3.4.0/Dockerfile
# we'll pin to 3.4.0 for now

ARG R_VERSION
ARG BUILD_DATE
ENV BUILD_DATE ${BUILD_DATE:-}
ENV R_VERSION=${R_VERSION:-3.4.0}
RUN apt-get update && apt-get install -y --no-install-recommends locales && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    locale-gen en_US.UTF-8 && \
    LC_ALL=en_US.UTF-8 && \
    LANG=en_US.UTF-8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8 && \
    TERM=xterm && \
    apt-get install -y --no-install-recommends \
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
    zlib1g \
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
    zlib1g-dev && \
    cd /tmp/ \
    ## Download source code
    curl -O https://cran.r-project.org/src/base/R-3/R-${R_VERSION}.tar.gz && \
    ## Extract source code
    tar -xf R-${R_VERSION}.tar.gz && \
    cd R-${R_VERSION} && \
    ## Set compiler flags
    R_PAPERSIZE=letter && \
    R_BATCHSAVE="--no-save --no-restore" && \
    R_BROWSER=xdg-open && \
    PAGER=/usr/bin/pager && \
    PERL=/usr/bin/perl && \
    R_UNZIPCMD=/usr/bin/unzip && \
    R_ZIPCMD=/usr/bin/zip && \
    R_PRINTCMD=/usr/bin/lpr && \
    LIBnn=lib && \
    AWK=/usr/bin/awk && \
    CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" && \
    CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" && \
    ## Configure options
    ./configure --enable-R-shlib \
               --enable-memory-profiling \
               --with-readline \
               --with-blas="-lopenblas" \
               --disable-nls \
               --without-recommended-packages && \
    ## Build and install
    make && \
    make install && \
    ## Add a default CRAN mirror
    echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site && \
    ## Add a library directory (for user-installed packages)
    mkdir -p /usr/local/lib/R/site-library && \
    chown root:staff /usr/local/lib/R/site-library && \
    chmod g+wx /usr/local/lib/R/site-library && \
    ## Fix library path
    echo "R_LIBS_USER='/usr/local/lib/R/site-library'" >> /usr/local/lib/R/etc/Renviron && \
    echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron && \
    ## install packages from date-locked MRAN snapshot of CRAN
    [ -z "$BUILD_DATE" ] && BUILD_DATE=$(TZ="America/Los_Angeles" date -I) || true && \
    MRAN=https://mran.microsoft.com/snapshot/${BUILD_DATE} && \
    echo MRAN=$MRAN >> /etc/environment && \
    export MRAN=$MRAN && \
    echo "options(repos = c(CRAN='$MRAN'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site && \
    ## Use littler installation scripts
    Rscript -e "install.packages(c('littler', 'docopt'), repo = '$MRAN')" && \
    ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r && \
    ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r && \
    ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r

   ## install r packages, bioconductor, etc ##
   ADD rpackages.R /tmp/
   RUN R -f /tmp/rpackages.R && \
   ## install fishplot ##
   cd /tmp/ && \
    wget https://github.com/chrisamiller/fishplot/archive/v0.4.tar.gz && \
    mv v0.4.tar.gz fishplot_0.4.tar.gz && \
    R CMD INSTALL fishplot_0.4.tar.gz && \
    cd && rm -rf /tmp/fishplot_0.4.tar.gz

   ## Clean up
   RUN cd / && \
   rm -rf /tmp/* && \
   apt-get remove --purge -y $BUILDDEPS && \
   apt-get autoremove -y && \
   apt-get autoclean -y && \
   rm -rf /var/lib/apt/lists/* && \
   apt-get clean