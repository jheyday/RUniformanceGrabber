# RUniformanceGrabber
A Package for R that communicates with a Honeywell PHD Server via a seperate 32-bit executible written in .NETFramework and run via the package [processx](https://cran.r-project.org/web/packages/processx/index.html).

A 32-bit executible is used rather than directly using PHDAPINET.dll to allow avoid issues when using a 64-bit version of R and accessing a 32-bit DLL.
Data is passed between the executible and the package using XML and then parsed into a dataframe.


# Installation

Install devtools.
Devtools can be installed from CRAN.

``` R
#Install devtools
install.packages("devtools")
# Load devtools
library(devtools)
# Install uniformancegrabber
install_github("jheyday/RUniformanceGrabber")
```
# Dependancies

* [R6](https://cran.r-project.org/web/packages/R6/index.html)
* [xml2](https://cran.r-project.org/web/packages/xml2/index.html)
* [processx](https://cran.r-project.org/web/packages/processx/index.html)


# Use
A help file is avaliable within R after loading the library using 
``` R
?Uniformance
```
Example Getting data

``` R
u <- Uniformance$new('MALSHW1')
u$add_tag('A.RL_AI7361.BATCH')
u$add_tag('A.RL_AI7361.GRADE')
u$set_startime('NOW-3W')
u$set_endtime('NOW-1D')
data <- u$get_results()
```
