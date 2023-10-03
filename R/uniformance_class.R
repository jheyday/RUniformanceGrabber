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
  m_samplefrequency = NULL,
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
    private$m_samplefrequency <- 0
    package_location <- gsub("/","//",system.file(package = 'UniformanceGrabber'))
    private$m_phdexe <- paste(package_location, '//bin//phdapinetinterface.exe',sep="")
    
  },
  
  ##############################################################################
  # Parameters Functions
  ##############################################################################
  #' @description
  #' Checks if tag exists on server and adds to a list of tags that will be grabbed by get_data
  #' @param tag_name 'A.RL_AI7361.BATCH'
  add_tag = function(tag_name){
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
      private$m_tags <- append(private$m_tags, tag_name)
      print(paste(tag_name, "added to taglist"))
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
  #' Sets the starttime to be passed to the results function 
  #' @param starttime 'DD/MM/YYYY HH:mm:ss' format
  set_startime = function(starttime){
    private$m_Starttime <- starttime
  },
  #' @description
  #' Sets the Endtime to be passed to the results function 
  #' @param endtime 'DD/MM/YYYY HH:mm:ss' format
  set_endtime = function(endtime){
    private$m_Endtime <- endtime
  },
  #' @description
  #' Sets the sample Frequency, value is in seconds 
  #' @param samplefrequency Default value is 0
  set_samplefrequency = function(samplefrequency){
    private$m_samplefrequency <- samplefrequency
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
  #' @description
  #' See current Sample Frequency 
  #' @param samplefrequency
  samplefrequency = function(){
    return(private$m_samplefrequency)
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
      #xmloutput <- run(exe, c("getdata",
      #                                                       paste("-h", self$Hostname, sep=""),
      #                                                       paste("-P", self$Port, sep=""),
      #                                                       paste("-u", self$Username, sep=""),
      #                                                       paste("-p", self$Password, sep=""),
      #                                                       paste("-t", element, sep=""),
      #                                                       paste("-s", private$m_Starttime, sep=""),
      #                                                       paste("-e", private$m_Endtime, sep=""),
      #                                                       paste("-f", private$m_samplefrequency, sep="")
      #))

      commands <- c("getdata",
                    paste("-h", self$Hostname, sep=""),
                    paste("-P", self$Port, sep=""),
                    paste("-p", self$Password, sep=""),
                    paste("-t", element, sep=""),
                    paste("-u", self$Username, sep=""),
                    paste("-s", private$m_Starttime, sep=""),
                    paste("-e", private$m_Endtime, sep=""),
                    paste("-f", private$m_samplefrequency, sep="")
      )
      
      xmloutput <- run(private$m_phdexe, commands)
      
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


#u <- Uniformance$new('MALSHW1')
#u$add_tag('A.RL_AI7361.BATCH')
#u$add_tag('A.RL_AI7361.GRADE')
#u$set_startime('NOW-3W')
#u$set_endtime('NOW-1D')
#u$startime()
#u$samplefrequency()
#sand <- u$get_results()
#print(sand)
#sand

