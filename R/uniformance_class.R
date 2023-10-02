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
Uniformance <- R6Class("Uniformance", public = list(
  host= NULL,
  port= NULL,
  UserName= NULL,
  Password= NULL,
  tag=list(),
  Starttime= NULL,
  Endtime= NULL,
  #' @description
  #' Initalises instiances of the uniformance class
  #' 
  initialize = function(host = NA, UserName='', Password='', Port=3000, Starttime="NOW-1D", Endtime="NOW"){
    
    self$host <- host
    self$UserName <- UserName
    self$Password <- Password
    self$Port <- Port
    self$Starttime <- Starttime
    self$Endtime <- Endtime
  },
  #' @description
  #' Returns a dataframe of all data using currently set parameters and tags
  #' This method requires that tags have been added via add_tag()
  get_results = function(){
    
    if (length(tag) == 0) {
      stop("Tag list is empty")
    }
    
    for (element in tag) {
      xmloutput <- capture.output(r1 <- run(system, c("getdata",
                                                      paste("-h ", self$Hostname),
                                                      paste("-P ", self$Port),
                                                      paste("-u ", self$Username),
                                                      paste("-p ", self$Password),
                                                      paste("-t ", element),
                                                      paste("-s ", self$Starttime),
                                                      paste("-e", self$Endtime)
                                                      )))
      dataframe.append(XML::xmlToDataFrame((xml <- XML::xmlParse(xmloutput))))
    }
  }
)
)
system.file(package = "UniformanceGrabber",lib.loc = NULL)
