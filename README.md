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
# Dependencies

* [R6](https://cran.r-project.org/web/packages/R6/index.html)
* [xml2](https://cran.r-project.org/web/packages/xml2/index.html)
* [processx](https://cran.r-project.org/web/packages/processx/index.html)


# Use
A help file is avaliable within R after loading the library using 
``` R
?Uniformance
```
Example Getting data

```R
#Load the Library 
library(UniformanceGrabber)
#Create instance of the Uniformance class, this a hostname, username, password and port
# Username and password default to "" and port defaults to 3000, these don't need to be changed.
u <- Uniformance$new('MALSHW1')
#Add tags, current these need to be added one by one.
u$add_tag('A.RL_AI7361.BATCH')
u$add_tag('A.RL_AI7361.GRADE')
# A tag can be removed either individually
u$remove_tag('A.RL_AI7361.GRADE')
#or the entire taglist can be emptied
u$clear_taglist()
#Starttime default to NOW-1D, this takes either a string like NOW-1D or 
# DD/MM/YYYY HH:mm:ss
# This value isn't error checked currently can will cause issues with $get_results()
# if the format isn't convertible
u$set_startime('NOW-3W')
#Endtime default to NOW-1D, this takes either a string like NOW-1D or 
# DD/MM/YYYY HH:mm:ss
#This value isn't error checked currently can will cause issues with $get_results()
# if the format isn't convertible
u$set_endtime('NOW-1D')

#These values can be checked with
u$startime
u$endtime
#Data can then be grabbed using the $get_results() method.
#This returns a list of dataframes, where each dataframe is one tag
data <- u$get_results()
```
