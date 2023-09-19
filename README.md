# RUniformanceGrabber
A Package for R that communicates with a Honeywell PHD Server via the rClr and phdapinet.dll
# Installation
Install devtools and rClr.
Devtools can be installed from CRAN, rClr should be installed as a seperate zip. 

[rClr](https://github.com/rdotnet/rClr) hasn't been updated for some time, a fork is avaliable that makes it work with [current version of R](https://github.com/Open-Systems-Pharmacology/rClr/releases)

``` R
#Install devtools
install.packages("devtools")
# Install rClr
install.packages("C:/Users/<Username>/Downloads/rClr_0.9.1.zip", repos = NULL, type = "win.binary")
# Load devtools
library(devtools)
# Install uniformancegrabber
install_github("jheyday/RUniformanceGrabber")
```
# Use
A help file is avaliable within R after loading the library using 
``` R
?Uniformance
```
Example Getting data

``` R
library(UniformanceGrabber)
u <- Uniformance$new("SeverName")
u$add_tag("tag name")
data <- u$get_results()
```
