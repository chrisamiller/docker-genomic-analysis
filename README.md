# genomic-analysis docker
A fat docker image for ad-hoc genomic analyses - combines a lot of the tools that are handy for exploring data
  
R 4.11 and some basic packages are installed. For convenience, it can be useful to set up a specific folder in which to keep your own library installs for testing. This will keep them persistent across sessions. Add something like this to your .Rprofile:
 
    devlib <- paste('/home/USERNAME/lib/R',paste(R.version$major,R.version$minor,sep="."),sep="")
    if (!file.exists(devlib))
      dir.create(devlib)
    x <- .libPaths()
    .libPaths(c(devlib,x))
    rm(x,devlib)
    
This is great for quickly prototyping and exploring data, but don't forget that if you're sharing code with others, you'll need to create a new container with the proper libraries installed so they can also use it!

### Partial list of tools:
 - Bedtools
 - Samtools
 - BCFtools
 - VCFtools
 - pdftk
 - tabix
 - bam-readcount
 - GATK (and picard tools)
 - FastQC
 - Google cloud SDK
 - R 4.11 and packages including:
   - BioCManager
   - data.table
   - dplyr
   - foreach
   - fishplot
   - gridExtra
   - Hmisc
   - plotrix
   - png
   - RColorBrewer
   - tidyverse
   - wesanderson
   - viridis
   - GenVisR
   - GenomicRanges
   - tximport
   - biomaRt
 - Python 3 and packages including:
   - numpy
   - scipy
   - cython
   - pyfaidx
   - pybedtools
   - cyvcf2
   - pandas
   - pysam
   - seaborn
   - openpyxl
   - cruzdb
   - intervaltree_bio
   - multiqc
   - pyensembl
   - scikit-learn
   - svviz
   - vatools
 