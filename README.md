# docker-genomic-analysis
Basic docker image for ad-hoc genomic analyses - combines a lot of the tools that are handy for exploring data on a ubuntu base image.

### Notes:
- Python 2 and 3 are both installed (using conda)
  - For python 3.6, you'll use `python`.  
  - For python2.7, run `source activate python2`, then `python`
  
- R 3.4 and some basic packages are installed. For convenience, it can be useful to set up a specific folder in which to keep your own library installs for testing. This will keep them persistent across sessions. Add something like this to your .Rprofile:
    ```
    devlib <- paste('/gscuser/cmiller/usr/lib/R',paste(R.version$major,R.version$minor,sep="."),sep="")
    if (!file.exists(devlib))
    dir.create(devlib)
    x <- .libPaths()
    .libPaths(c(devlib,x))
    rm(x,devlib)```
    
This is great for quickly prototyping, but don't forget that if you're sharing code with others, you'll need to create a new container with the proper libraries installed so they can also use it.
