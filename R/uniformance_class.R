library(processx)
library(xml2)
library(R6)

#' Uniformance Class
#' @description
#' Creates an instance of the Uniformance class. This class acts as a wrapper for a 32-bit subprocess that accesses the honeywell Process Historian via honeywell's .NETFramework dll, phdapinet.dll.
#' 
#' The parameters (tag names, start, etc) are stored within the class, when requests for data the process is called with data being passed via an XML format.
#' 
#' Methods can be accessed for a class by creating an instance of the class and then using the following format "instance"$"Method"
#' 
#' 
#' @param host This is the server where the tags you are interested in are, typically 'MALSHW1' or 'MBTSHW1'
#' @param UserName Optional Parameter for 200 PHD Systems 
#' @param Password Optional Parameter for 200 PHD Systems
#' @param Port Default port is 3000
#' 
#' @examples
#' example <- Uniformance$new("MALSHW1")
#' @import R6
#' @import xml2
#' @import processx
#' @export 
Uniformance <- R6Class("Uniformance",
private = list(
  m_Starttime =NULL,
  m_Endtime = NULL,
  m_phdexe = NULL,
  m_SampleFrequency = NULL,
  m_SampleFrequencyType = NULL,
  m_UseSampleFrequency = NULL,
  m_ReductionType = NULL,
  m_ReductionFrequency = NULL,
  m_ReductionOffset = NULL,
  m_tags = list()
  
),
public = list(
  Hostname= NULL,
  Port= NULL,
  Username= NULL,
  Password= NULL,
  #' @description
  #' Initialises instances of the uniformance class
  #' 
  initialize = function(hostname = NA, username='', password='', port=3000){
    
    self$Hostname             <- hostname
    self$Username             <- username
    self$Password             <- password
    self$Port                 <- port
    private$m_Starttime       <- 'NOW-1D'
    private$m_Endtime         <- 'NOW'
    private$m_SampleFrequency <- 0
    private$m_SampleFrequencyType = "Raw"
    private$m_UseSampleFrequency = FALSE
    private$m_ReductionType = 'None'
    private$m_ReductionFrequency = 60
    private$m_ReductionOffset = 'Around'
    package_location <- gsub("/","//",system.file(package = 'UniformanceGrabber'))
    private$m_phdexe <- paste(package_location, '//bin//phdapinetinterface.exe',sep="")
    #private$m_phdexe <- "C:\\Users\\jheywoo\\Programming Projects\\R\\UniformanceGrabberPackage - Copy\\inst\\bin\\phdapinetinterface.exe"
    
  },
  
  ##############################################################################
  # Other Functions
  ##############################################################################
  #' @description
  #' Return a dataframe of all current parameters the first dataframe contains server parameters and the second contains details related to data to be acquired.
  show_parameters = function(){
    listofdataframes = list()
    
    serverdetails <- data.frame(Hostname = c(self$Hostname),
                                Port = c(self$Port),
                                Username = c(self$Username),
                                Password = c(self$Password)
    )
    
    Parameters <- data.frame(Tags = c(private$tags),
                             StartTime = c(private$m_Starttime),
                             EndTime = C(private$m_endtime),
                             UseSampleFrequency = c(private$m_UseSampleFrequency),
                             SampleFrequencyType = c(private$m_SampleFrequencyType),
                             SampleFrequency = c(private$m_SampleFrequency),
                             ReductionType = c(private$m_ReductionType),
                             ReductionFrequency = c(private$m_ReductionFrequency)
    )
  
    listofdataframes <- append(listofdataframes, list(serverdetails))
    listofdataframes <- append(listofdataframes, list(Parameters))
    return(listofdataframes)
  },
  ##############################################################################
  # Tag Functions
  ##############################################################################
  #' @description
  #' Checks if tag exists on server
  #' @param tag_name 'A.RL_AI7361.BATCH'
  check_tag = function(tag_name){
    commands <- c("checktag",
                  paste("-h", self$Hostname, sep=""),
                  paste("-P", self$Port, sep=""),
                  paste("-u", self$Username, sep=""),
                  paste("-p", self$Password, sep=""),
                  paste("-t", tag_name, sep="")
    )
    tagcheck <- run(private$m_phdexe, commands)
    #tagcheck <- run(exe, commands)
    if (endsWith(tagcheck$stdout, "found\r\n")) {
      print("Tag was found")
      return(0)
    } else if (endsWith(tagcheck$stdout, "system\r\n")) {
      print("Tagname was not found, check tagname and try again")
      return(1)
    } else {
      print("Connection to PHD server failed. Check server details")
      return(1)
    }
  },
  
  #' @description
  #' Checks if tag exists on server and adds to a list of tags that will be grabbed by get_data
  #' @param tag_name 'A.RL_AI7361.BATCH'
  add_tag = function(tag_name){
    if (tag_name %in% private$m_tags) {
      print(paste(tag_name, "is already in the taglist"))
      return(1)
    }
    checkresult <- self$check_tag(tag_name)
    if(checkresult == 0){
      private$m_tags <- append(private$m_tags, tag_name)
      return(0)
    }
    print("tag not added. Check errors.")
    return(1)
    
    
  },
  #' @description
  #' Shows taglist
  show_taglist = function(){
    print(private$m_tags)
  },
  #' @description
  #' Clears taglist
  clear_taglist = function(){
    private$m_tags = list()
  },
  #' @description
  #' Remove a given tag
  #' @param tag_name 
  remove_tag = function(tag_name){
    if (tag_name %in% private$m_tags) {
      private$m_tags <- private$m_tags[private$m_tags != tag_name]
      print(paste(tag_name, "was removed from the taglist.\n"))
    } else {
      print(paste(tag_name, "was not found in the taglist.\n"))
    }
  },
  
  ##############################################################################
  # Sampling Functions
  ##############################################################################
  #' @description
  #' Sets the sample Frequency, value is in seconds 
  #' @param SampleFrequency Default value is 0
  set_SampleFrequency = function(SampleFrequency){
    if (!(is.numeric(SampleFrequency))){
      print("Sample Frequency should be numeric")
      return(1)
    }
    private$m_SampleFrequency <- SampleFrequency
    if (private$m_UseSampleFrequency == FALSE){
      private$m_UseSampleFrequency = TRUE
      print("useSampleFrequency set to true, this can be disabled via set_useSampleFrequency")
    }
  },
  #' @description
  #' See current Sample Frequency 
  SampleFrequency = function(){
    return(private$m_SampleFrequency)
  },
  
  #' @description
  #' Sets the use sample frequency flag
  #' If True: The effective Reduction Frequency is the SampleFrequency.
  #' If False: The ReductionFrequency property specifies the Reduction Frequency.
  #' @param useSampleFrequency Default value is FALSE
  set_UseSampleFrequency = function(useSampleFrequency){
    if (useSampleFrequency == TRUE | useSampleFrequency == FALSE){
      private$m_UseSampleFrequency <- useSampleFrequency
      return(0)
    }
    print("Ensure useSampleFrequency is TRUE or FALSE")
    return(1)
  },
  #' @description
  #' Sees the use sample frequency flag 
  UseSampleFrequency = function(){
    return(private$m_UseSampleFrequency)
  },
  
  
  #' @description
  #' Sets the Sample Frequency Type Accepts:  Snapshot, Average, Resampled, Raw, InterpolatedRaw
  #' @param SampleType Default value is FALSE
  set_SampleFrequencyType = function(SampleType){
    enumtypes <- c("Snapshot", "Average", "Resampled", "Raw", "InterpolatedRaw")
    
    if(SampleType %in% enumtypes){
      private$m_SampleFrequencyType <- SampleType
      return(0)
    }
    print('Ensure type matches one of "Snapshot", "Average", "Resampled", "Raw", "InterpolatedRaw".')
    return(1)
  },
  #' @description
  #' Sees the use Sample Frequency Type 
  SampleFrequencyType = function(){
    return(private$SampleFrequencyType)
  },
  ##############################################################################
  #' @description
  #' Sets the Reduction Frequency
  #' @param ReductionFrequency Default value is 60
  set_ReductionFrequency = function(ReductionFrequency){
    if(is.numeric(ReductionFrequency)){
      private$m_ReductionFrequency
      return(0)
    }
    print('Value should be numeric')
    return(1)
  },
  #' @description
  #' Sees the use Reduction Frequency 
  ReductionFrequency = function(){
    return(private$ReductionFrequency)
  },
  
  #' @description
  #' Sets the Reduction Type Accepts:  "None", "Average", "Delta", "Minimum", "Maximum",
  #'"StandardDeviation", "RegressionSlope", "RegressionConstant",
  #'"RegressionDeviation","First", "Last"
  #' @param ReductionType Default value is FALSE
  set_ReductionType = function(ReductionType){
    enumtypes <- c("None", "Average", "Delta", "Minimum", "Maximum",
                   "StandardDeviation", "RegressionSlope", "RegressionConstant",
                   "RegressionDeviation","First", "Last")
    
    if(ReductionType %in% enumtypes){
      private$m_ReductionType <- ReductionType
      return(0)
    }
    print('Ensure Reduction Type matches one of "None", "Average", "Delta", "Minimum", "Maximum",
                   "StandardDeviation", "RegressionSlope", "RegressionConstant",
                   "RegressionDeviation","First", "Last".')
  },
    #' @description
  #' Sees the Reduction Type 
  ReductionType = function(){
    return(private$ReductionType)
  },
  #' @description
  #' Sets the Reduction Offset. Accepts: After, Around, Before
  #' @param set_ReductionOffset Default value is Around
  set_ReductionOffset = function(set_ReductionOffset){
    enumtypes <- c("After", "Around", "Before")
    
    if(set_ReductionOffset %in% enumtypes){
      private$m_ReductionOffset <- set_ReductionOffset
      return(0)
    }
    print('Ensure Reduction Type matches one of "After","Around", "Before".')
  },
  #' @description
  #' Sees the Reduction Type 
  ReductionOffset = function(){
    return(private$m_ReductionOffset)
  },
  
  ##############################################################################
  # Time  Functions
  ##############################################################################
  #' @description
  #' Sets the starttime to be passed to the results function.
  #' This takes either a date in either 'DD/MM/YYYY HH:mm:ss' or NOW-1d (d=day, w=week, y=year)
  #' @param starttime 'DD/MM/YYYY HH:mm:ss' format
  set_startime = function(starttime){
    private$m_Starttime <- starttime
  },
  #' @description
  #' Sets the Endtime to be passed to the results function 
  #' @param endtime 'DD/MM/YYYY HH:mm:ss' format
  #' This takes either a date in either 'DD/MM/YYYY HH:mm:ss' or NOW-1d (d=day, w=week, y=year)
  set_endtime = function(endtime){
    private$m_Endtime <- endtime
  },
  #' @description
  #' See current Starttime 
  #' @param starttime
  startime = function(){
    return(private$m_Starttime)
  },
  #' @description
  #' See current Endtime 
  #' @param endtime 
  endtime = function(){
    return(private$m_Endtime)
  },
  
  ##############################################################################
  # Result Functions
  ##############################################################################
  
  #' @description
  #' Returns a list of dataframes with current tags and parameters. 
  #' 
  #' This method requires that tags have been added via add_tag().
  get_results = function(){
    if (length(private$m_tags) == 0) {
      stop("Tag list is empty")
    }
    dataframe <- list()
    for (element in private$m_tags) {
      commands <- c("getdata",
                    paste("-h", self$Hostname, sep=" "),
                    paste("-P", self$Port, sep=" "),
                    paste("-u", self$Username, sep=" "),
                    paste("-p", self$Password, sep=" "),
                    paste("-t", element, sep=" "),
                    paste("-s", private$m_Starttime, sep=" "),
                    paste("-e", private$m_Endtime, sep=" "),
                    paste("-g", private$m_UseSampleFrequency, sep=" "),
                    paste("-f", private$m_SampleFrequency, sep=" "),
                    paste("-F", private$m_SampleFrequencyType, sep=" "),
                    paste("-r", private$m_ReductionFrequency, sep=" "),
                    paste("-R", private$m_ReductionType, sep=" "),
                    paste("-o", private$m_ReductionOffset, sep=" ")
      )
      commands <- c("getdata",
                    paste("-h", self$Hostname, sep=" "),
                    paste("-P", self$Port, sep=" "),
                    paste("-u", self$Username, sep=" "),
                    paste("-p", self$Password, sep=" "),
                    paste("-t", element, sep=" "),
                    paste("-s", private$m_Starttime, sep=" "),
                    paste("-e", private$m_Endtime, sep=" "),
                    paste("-g", private$m_UseSampleFrequency, sep=" "),
                    paste("-f", private$m_SampleFrequency, sep=" "),
                    paste("-F", private$m_SampleFrequencyType, sep=" "),
                    paste("-r", private$m_ReductionFrequency, sep=" "),
                    paste("-R", private$m_ReductionType, sep=" "),
                    paste("-o", private$m_ReductionOffset, sep=" ")
      )
      
      xmloutput <- run(private$m_phdexe, commands)
      #xmloutput <- run(exe, commands)
      
      rawdata   <-xml2::read_xml(xmloutput$stdout)
      tagname   <-c(xml_text(xml_find_all(rawdata, xpath = "//TagName")))
      timestamp <-c(xml_text(xml_find_all(rawdata, xpath = "//TimeStamp")))
      value     <-c(xml_text(xml_find_all(rawdata, xpath = "//Value")))
      confidence<-c(xml_text(xml_find_all(rawdata, xpath = "//Confidence")))
      hostname  <-c(xml_text(xml_find_all(rawdata, xpath = "//HostName")))
      units     <-c(xml_text(xml_find_all(rawdata, xpath = "//Units")))
      
      listoflists = list(tagname    = tagname,
                         Timestamp  = timestamp,
                         Value      = value,
                         Confidence = confidence,
                         Hostname   = hostname)
      
      df <- as.data.frame(do.call(cbind, listoflists))   
      dataframe <- append(dataframe, list(df))
    }
    return(dataframe)
  }
)
)



#exe
#u <- Uniformance$new('MALSHW1')
#u$set_ReductionFrequency(60)
#u$set_SampleFrequency(60)
#u$set_SampleFrequencyType('Snapshot')
#u$add_tag('A.RL_AI7361.BATCH')
#u$remo
#u$add_tag('A.RL_AI7361.GRADE')
#u$set_startime('NOW-3W')
#u$set_endtime('NOW-1D')
#u$startime()
#sand <- u$get_results()
#print(sand)
#sand
