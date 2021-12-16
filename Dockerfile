FROM rocker/r-ubuntu:20.04
LABEL Image for basic ad-hoc bioinformatic analyses - c.a.miller@wustl.edu


#add the r repository, so we get binary installs of packages, which are smaller
#then install a bunch of utilities and r packages
RUN add-apt-repository ppa:c2d4u.team/c2d4u4.0+ && \
    apt-get update -y && apt-get install -y --no-install-recommends \
    ack-grep \
    bzip2 \
    curl \
    tmux \
    dbus \
    default-jre \
    emacs \
    emacs-goodies-el \
    ess \
    gawk \
    git \
    grep \
    less \
    lsof \
    nano \
    openssh-client \
    pdftk \
    software-properties-common \
    tabix \
    rsync \
    unzip \
    wget \
    zip \
    r-cran-biocmanager \
    r-cran-data.table \
    r-cran-dplyr \
    r-cran-foreach \
    r-cran-gridextra \
    r-cran-hmisc \
    r-cran-plotrix \
    r-cran-png \
    r-cran-rcolorbrewer \
    r-cran-tidyverse \
    r-cran-wesanderson \
    r-cran-viridis \
    python3-pip \
    python3-numpy \
    python3-scipy \
    cython \
    python3-pyfaidx \
    python3-pybedtools \
    python3-cyvcf2 \
    python3-pandas \
    python3-pysam \
    python3-seaborn \
    python3-openpyxl 

# add bioconductor packages not in cran
ADD rpackages.R /tmp/
RUN R -f /tmp/rpackages.R
# install fishplot
RUN cd /tmp/ && \
    wget https://github.com/chrisamiller/fishplot/archive/v0.4.tar.gz && \
    mv v0.4.tar.gz fishplot_0.4.tar.gz && \
    R CMD INSTALL fishplot_0.4.tar.gz && \
    cd && rm -rf /tmp/fishplot_0.4.tar.gz


# a few python libs that weren't available through apt-get
RUN pip install cruzdb==0.5.6 \
    intervaltree_bio==1.0.1 \
    multiqc==1.11 \
    pyensembl==1.9.4 \
    scikit-learn==1.0.1 \
    svviz==1.6.2 \
    vatools==5.0.1

# grab the samtools and bcftools binaries instead of compiling
COPY --from=quay.io/biocontainers/samtools:1.14--hb421002_0 /usr/local/bin/samtools /usr/local/bin/samtools
COPY --from=quay.io/biocontainers/samtools:1.14--hb421002_0 /usr/local/lib/libhts.so* /usr/local/lib/libtinfow.so* /usr/local/lib/
COPY --from=quay.io/biocontainers/bcftools:1.14--h88f3f91_0 /usr/local/bin/bcftools /usr/local/bin/bcftools
COPY --from=quay.io/biocontainers/bcftools:1.14--h88f3f91_0 /usr/local/lib/libgsl.so* /usr/local/lib/

# grab the bam-readcount binary instead of compiling
COPY --from=mgibio/bam-readcount:1.0.0 /bin/bam-readcount /bin/bam-readcount/
COPY bam_readcount_helper.py /usr/bin/bam_readcount_helper.py

# bedtools
RUN cd /tmp && wget https://github.com/arq5x/bedtools2/releases/download/v2.30.0/bedtools.static.binary && \
    mv bedtools.static.binary /bin/bedtools && \
    chmod a+x /bin/bedtools

# vcftools
COPY --from=quay.io/biocontainers/vcftools:0.1.16--h9a82719_5 /usr/local/bin/vcftools /usr/local/bin/vcftools


# fastqc
RUN cd /opt && wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip && \
    unzip fastqc_v0.11.9.zip && \
    ln -s /opt/FastQC/fastqc /usr/local/bin/fastqc

# gatk
RUN cd /opt && wget https://github.com/broadinstitute/gatk/releases/download/4.2.3.0/gatk-4.2.3.0.zip && \
    unzip gatk-4.2.3.0.zip
ENV PATH="/opt/gatk-4.2.3.0:${PATH}"
COPY split_interval_list_helper.pl /usr/bin/split_interval_list_helper.pl

# a few utilities from ucsc
RUN mkdir -p /tmp/ucsc && \
    cd /tmp/ucsc && \
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigBedToBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigAverageOverBed http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigToBedGraph http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/wigToBigWig && \
    chmod ugo+x * && \
    mv * /usr/bin/ && \
    rm -rf /tmp/ucsc

# a few misc useful utilities:
ADD utilities/* /usr/bin/

#install google cloud stuff
RUN curl -sSL https://sdk.cloud.google.com > /tmp/gcloud_installer.sh && bash /tmp/gcloud_installer.sh --install-dir=/opt/gcloud --disable-prompts
ENV PATH="/opt/gcloud/google-cloud-sdk/bin:${PATH}"

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

#add some aliases - updating PATH doesn't get passed through on cluster sometimes
RUN ln -s /usr/bin/python3 /usr/bin/python && \
    ln -s /opt/gatk-4.2.3.0/gatk /usr/bin/gatk && \
    ln -s /opt/gcloud/google-cloud-sdk/bin/gcloud /usr/bin/gcloud && \
    ln -s /opt/gcloud/google-cloud-sdk/bin/gsutil /usr/bin/gsutil
