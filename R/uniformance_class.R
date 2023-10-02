library(processx)
library(XML)
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
#' @examples
#' example <- Uniformance$new("MALSHW1")
#' @import R6
#' @import XML
#' @import processx
#' @export 
Uniformance <- R6Class("Uniformance",
private = list(
  m_Starttime =NULL,
  m_Endtime = NULL,
  m_tags = list(),
  m_phdexe = NULL
  
),
public = list(
  host= NULL,
  port= NULL,
  UserName= NULL,
  Password= NULL,
  
  #' @description
  #' Initialises instances of the uniformance class
  #' 
  initialize = function(host = NA, UserName='', Password='', Port=3000, Starttime="NOW-1D", Endtime="NOW"){
    
    self$host <- host
    self$UserName <- UserName
    self$Password <- Password
    self$Port <- Port
    self$m_Starttime <- Starttime
    self$m_Endtime <- Endtime
    package_location <- gsub("/","//",system.file(package = "UniformanceGrabber"))
    self$m_phdexe = paste(package_location, "//bin//phdapinetinterface.exe",sep="")
    
  },
  #' @description
  #' Checks if tag exists on server and adds to a list of tags that will be grabbed by get_data
  #' @param tag_name 'A.RL_AI7361.BATCH'

  add_tag = function(tag_name){
    
    tagcheck <- run(self$m_phdexe, c("checktag",
                                              paste("-h", self$Hostname, sep=""),
                                              paste("-P", self$Port, sep=""),
                                              paste("-u", self$Username, sep=""),
                                              paste("-p", self$Password, sep=""),
                                              paste("-t", tag_name, sep="")
    ))
    if (grepl("found\r\n$", tagcheck)) {
      self$m_tags <- append(self$m_tags, tag_name)
      print(paste(tag_name, "added to taglist"))
      
    } 
    else if (grepl("system\r\n$", tagcheck)) {
      print("Tagname was not found, check tagname and try again")
    } 
    else {
      print("Connection to PHD server failed. Check server details")
    }
  },
  #' @description
  #' Returns a dataframe of all data using currently set parameters and tags
  #' This method requires that tags have been added via add_tag()
  get_results = function(){
    if (length(tag) == 0) {
      stop("Tag list is empty")
    }
    for (element in tag) {
      xmloutput <- capture.output(r1 <- run(self$m_phdexe, c("getdata",
                                                      paste("-h", self$Hostname, sep=""),
                                                      paste("-P", self$Port, sep=""),
                                                      paste("-u", self$Username, sep=""),
                                                      paste("-p", self$Password, sep=""),
                                                      paste("-t", element, sep=""),
                                                      paste("-s", self$m_Starttime, sep=""),
                                                      paste("-e", self$m_Endtime, sep="")
                                                      )))
      dataframe.append(XML::xmlToDataFrame((xml <- XML::xmlParse(xmloutput))))
    }
    return(dataframe)
  }
)
)