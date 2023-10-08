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
## Creating Class Instance
Parameters that aren't set will use their default values.
```R
#Load the Library 
library(UniformanceGrabber)
#Create instance of the Uniformance class, this a hostname, username, password and port
# Username and password default to "" and port defaults to 3000.
u <- Uniformance$new('hostname', 'username', 'password', 'port')
# All currently set parameters can be viewed using
u$show_parameters()
```


## Sample Time Controls
``` R
#Starttime default to NOW-1D, this takes either a string with relative date such as NOW-1D or 'DD/MM/YYYY HH:mm:ss' format
# If the format isn't compatible it will create errors when using $get_results()
u$set_Startime('NOW-3W')
#Starttime default to NOW, this takes either a string with relative date such as NOW-1D or 'DD/MM/YYYY HH:mm:ss' format
#Endtime must be after starttime.
u$set_Endtime('NOW')

#These values can be checked with the following commands
u$Startime
u$Endtime
```

## Sample Frequency
``` R
# Sets the sample frequency, in seconds. Setting this will set UseSampleFrequency to True. Requires a Sampling type to be something other than Raw.
u$set_SampleFrequency(60)
#UseSampleFrequency can be manually set
u$set_UseSampleFrequency(TRUE)
#Several sampling methods can be set Average, Resampled, Interpolated Raw, Raw and Snapshot
u$set_SampleFrequencyType('Snapshot')
# These can each be individually checked with the following:
u$SampleFrequency()
u$UseSampleFrequency()
u$SampleFrequencyType()
```

## Reduction Frequency
``` R
# Sets the reduction frequency. This setting requires UseSampleFrequency to False. and requires a valid ReductionType, Defaults to 60.
u$set_ReductionFrequency(60)
#The reduction type can be any of the following, Defaults to None: None, Average, Delta,
#Minimum, Maximum, StandardDeviation, RegressionSlope, RegressionCOnstant, RegressionDeviation, First, Last 
u$set_ReductionType('None')
#The reduction offset can be any of the following, Defaults to Around: After, Around, Before
u$set_ReductionOffset('Around')
# These can each be individually checked with the following:
u$ReductionFrequency()
u$ReductionFrequencyType()
u$ReductionFrequencyOffset()
```

## Adding Tags and Getting Results
```R
#Tags can be added either individually or as a list.
u$add_tag('A.RL_AI7361.BATCH')
u$add_tag('A.RL_AI7361.GRADE')
#same as:
u$add_tag(c('A.RL_AI7361.BATCH', 'A.RL_AI7361.GRADE'))

# The taglist can either be cleared completely or individual tags can be removed.
u$remove_tag('A.RL_AI7361.GRADE')
#or the entire taglist can be emptied
u$clear_taglist()

#Data can then be fetched with the following
#This returns a list of dataframes, where each dataframe is one tag
data <- u$get_results()
#Shows progress by tag
> data <- u$get_results()
[1] "Current Tag: A.RL_AI7361.BATCH   1  of  2"
[1] "Current Tag: A.RL_AI7361.GRADE   2  of  2"
```
