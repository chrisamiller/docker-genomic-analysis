FROM mgibio/bam-readcount AS rcnt
FROM bioconductor/bioconductor_docker:RELEASE_3_14
LABEL Image for basic ad-hoc bioinformatic analyses - c.a.miller@wustl.edu

#deps
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ack-grep \
    build-essential \
    byobu \
    bzip2 \
    curl \
    csh \
    dbus \
    default-jdk \
    default-jre \
    emacs \
    emacs-goodies-el \
    ess \
    evince \
    g++ \
    gawk \
    git \
    grep \
    less \
    libcurl4-openssl-dev \
    libnss-sss \
    libpng-dev \
    librsvg2-bin \
    libssl-dev \
    libxml2-dev \
    lsof \
    make \
    man \
    nano \
    ncurses-dev \
    nodejs \
    openssh-client \
    pdftk \
    pkg-config \
    rsync \
    tabix \
    tmux \
    unzip \
    wget \
    zip \
    zlib1g-dev

##############
# HTSlib     #
##############
ENV HTSLIB_INSTALL_DIR=/opt/htslib
WORKDIR /tmp
RUN wget https://github.com/samtools/htslib/releases/download/1.14/htslib-1.14.tar.bz2 && \
    tar --bzip2 -xvf htslib-1.14.tar.bz2 && \
    cd /tmp/htslib-1.14 && \
    ./configure  --enable-plugins --prefix=$HTSLIB_INSTALL_DIR && \
    make && \
    make install && \
    cp $HTSLIB_INSTALL_DIR/lib/libhts.so* /usr/lib/ && \
    rm -rf /tmp/htslib-1.14*
  
##################
# Samtools 1.3.1 #
##################

WORKDIR /tmp
RUN wget https://github.com/samtools/samtools/releases/download/1.14/samtools-1.14.tar.bz2 && \
    tar --bzip2 -xf samtools-1.14.tar.bz2 && \
    cd /tmp/samtools-1.14 && \
    ./configure --with-htslib=/opt/htslib --prefix=/opt/samtools && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/samtools-1.14* && \
    ln -s /opt/samtools/bin/* /usr/bin/ \

################
#bcftools      #
################
WORKDIR /tmp
RUN wget https://github.com/samtools/bcftools/releases/download/1.14/bcftools-1.14.tar.bz2 && \
    tar --bzip2 -xf bcftools-1.14.tar.bz2 && \
    mkdir -p /opt/bcftools && \
    cd /tmp/bcftools-1.14 && \
    make prefix=/opt/bcftools && \
    make prefix=/opt/bcftools install && \
    cd / && \
    ln -s /opt/bcftools/bin/* /usr/bin/ && \
    rm -rf /tmp/bcftools-*

#################
# bam-readcount #
#################
#grab the binary instead of compiling
COPY --from=rcnt /bin/bam-readcount /opt/bam-readcount/

##TODO - is this up tp date?
#note - this script needs cyvcf - installed in the python secetion!
COPY bam_readcount_helper.py /usr/bin/bam_readcount_helper.py


############
# GATK     #
############
WORKDIR /opt
RUN wget https://github.com/broadinstitute/gatk/releases/download/4.2.3.0/gatk-4.2.3.0.zip && \
    unzip gatk-4.2.3.0.zip
ENV PATH="/opt/gatk-4.2.3.0/bin:${PATH}"

COPY split_interval_list_helper.pl /usr/bin/split_interval_list_helper.pl

##############
## bedtools ##
##############
WORKDIR /tmp
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.30.0/bedtools.static.binary && \
    mv bedtools.static.binary /bin/bedtools && \
    chmod a+x /bin/bedtools

##############
## vcftools ##
##############
WORKDIR /tmp
RUN wget https://github.com/vcftools/vcftools/releases/download/v0.1.16/vcftools-0.1.16.tar.gz && \
    tar -xvf vcftools-0.1.16.tar.gz && \
    cd vcftools-0.1.16 && \
   ./configure && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/vcftools-0.1.16*

##################
# ucsc utilities #
##################
RUN mkdir -p /tmp/ucsc && \
    cd /tmp/ucsc && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigBedToBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigAverageOverBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigToBedGraph http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/wigToBigWig && \
    chmod ugo+x * && \
    mv * /usr/bin/ && \
    rm -rf /tmp/ucsc


##################
# R packages     #
##################
ADD rpackages.R /tmp/
RUN R -f /tmp/rpackages.R

## install fishplot ##
RUN cd /tmp/ && \
    wget https://github.com/chrisamiller/fishplot/archive/v0.4.tar.gz && \
    mv v0.4.tar.gz fishplot_0.4.tar.gz && \
    R CMD INSTALL fishplot_0.4.tar.gz && \
    cd && rm -rf /tmp/fishplot_0.4.tar.gz


#################################
# Python 3, plus packages
 
# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

# Install conda
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    curl -s https://repo.anaconda.com/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh -o miniconda.sh && \
    /bin/bash miniconda.sh -f -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    conda clean -tipsy

# Install Python 3 packages available through pip
RUN conda install --yes 'pip' && \
    conda clean -tipsy && \
    #dependencies sometimes get weird - installing each on it's own line seems to help
    pip install numpy==1.21.4 && \
    pip install scipy==1.7.3 && \
    pip install cruzdb==0.5.6 && \
    pip install cython==0.29.25 && \
    pip install pyensembl==1.9.4 && \
    pip install pyfaidx==0.6.3.1 && \
    pip install pybedtools==0.8.2 && \
    pip install cyvcf2==0.30.14 && \
    pip install intervaltree_bio==1.0.1 && \
    pip install pandas==1.3.5 && \
    pip install pysam==0.18.0 && \
    pip install seaborn==0.11.2 && \
    pip install scikit-learn==1.0.1 && \
    pip install openpyxl==3.0.9 && \
    pip install svviz==1.6.2 && \
    pip install vatools==5.0.1 && \
    pip install multiqc==1.11
# pip install text2excel

############
# Fastqc   #
############
WORKDIR /opt
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip && \
    unzip fastqc_v0.11.9.zip && \
    ln -s /opt/FastQC/fastqc /usr/local/bin/fastqc

#set timezone to CDT
#LSF: Java bug that need to change the /etc/timezone.
#/etc/localtime is not enough.
RUN ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime && \
    echo "America/Chicago" > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata

#UUID is needed to be set for some applications
RUN dbus-uuidgen >/etc/machine-id

## Clean up
RUN cd / && \
    rm -rf /tmp/* && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

ADD utilities/* /usr/bin/

