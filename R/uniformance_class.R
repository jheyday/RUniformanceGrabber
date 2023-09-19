library(R6)
library(rClr)
library(XML)


#' Uniformance Class
#' @description
#' Creates an instance of the Uniformance class, This class acts as a wrapper for the phdapinet.dll which is used to access honeywell PHD servers/
#' The class holds the server data and methods for grabbing data.
#' 
#' Methods can be accessed for a class by creating an instance of the class and then using the following format "instance"$"Method"
#' 
#' 
#' @param host This is the server where the tags you are interested in are, typically 'MALSHW1' or 'MBTSHW1'
#' @examples
#' example <- Uniformance$new("MALSHW1")
#' @import R6
#' @import rClr
#' @export 
Uniformance <- R6Class("Uniformance", public = list(
  host= NULL,
  phdclass=NULL,
  historianclass=NULL,
  tags=NULL,
  tag=NULL,
  #' @description
  #' Initalises instiances of the uniformance class
  initialize = function(host = NA){
    
    self$host <- host
    
    clrLoadAssembly('C:\\Program Files (x86)\\Common Files\\Honeywell\\Uniformance\\phdapinet.dll')
    self$phdclass <- clrNew("Uniformance.PHD.PHDServer")
    self$historianclass <- clrNew("Uniformance.PHD.PHDHistorian")
    self$tags <- clrNew("Uniformance.PHD.Tags")
    self$tag <- clrNew("Uniformance.PHD.Tag")
    
    clrCall(self$phdclass, "set_HostName", self$host)
    clrCall(self$phdclass, "set_Password", '')
    clrCall(self$historianclass, "set_DefaultServer", self$phdclass)
  },
  ##############################################################################
  # Parameters Functions
  ##############################################################################
  
  #Update time functions to use arrow to convert format
  
  
  #' @description
  #' Returns current Start time for data
  StartTime = function(){
    clrGet(self$historianclass, "StartTime")
  },
  
  #' @description
  #' Set start time for data
  #' Defaults to Now-1hour
  #' @param time 'DD/MM/YYYY HH:mm:ss' format
  Set_StartTime = function(time){
    #Add Function to convert to datetime
    tryCatch(clrCall(self$historianclass, "set_StartTime", time), 
             error=function(cond){
               message("Make sure date is in format DD/MM/YYYY HH:mm:ss and is provided as a string")
               message("Here is the original error:")
               message(cond)
             }
    )
  },
  #' @description
  #' Returns current end time for data
  EndTime = function(){
    clrGet(self$historianclass, "EndTime")
  },
  #' @description
  #' Set end time for data
  #' Defaults to Now
  #' @param time 'DD/MM/YYYY HH:mm:ss' format
  Set_EndTime = function(time){
    #Add Function to convert to datetime
    tryCatch(clrCall(self$historianclass, "set_EndTime", time), 
             error=function(cond){
               message("Make sure date is in format DD/MM/YYYY HH:mm:ss and is provided as a string")
               message("Here is the original error:")
               message(cond)
             }
    )
  },
  
  #' @description
  #' Returns current Sample Frequency for data
  Sample_Frequency  = function(){
    clrGet(self$historianclass, "SampleFrequency")
  },
  #CHECK IF THIS WORKS
  #' @description
  #' Set the Sample Frequency for data for data
  #' @param frequency Value should be in seconds
  Set_Sample_Frequency = function(frequency){
    #Add Function to convert to datetime
    clrCall(self$historianclass, "set_SampleFrequency", frequency)
  },
  
  ##############################################################################
  # Tag Functions
  ##############################################################################
  #' @description
  #' add tags to tag list that will be checked, tags should be provided as a string
  #' @param tag_name 'A.RL_AI7361.BATCH'

  add_tag = function(tag_name){
    #Check if tag is in historian
    test<- clrCall(self$historianclass, "GetPHDTagname", tag_name)
    if (test == ''){
      stop("Tag not found in Historian")
    }
    else{
      tag <- clrNew("Uniformance.PHD.Tag", tag_name)
      clrCall(self$tags, "Add", tag)
      print(paste(tag_name," added"))
    }
    
  },
  #' @description
  #' Returns a list of all the current tags  
  list_tags = function(){
    num_tags <- clrGet(self$tags, "Count")
    current_tags = list()
    if (num_tags == 0){
      print("No tags")
      return(current_tags)
    }
    
    for (x in seq(0,num_tags-1)){
      tag_data = clrCall(self$tags, "get_Item", as.integer(x))
      current_tags <- append(current_tags, clrGet(tag_data, "TagName"))
    }
    return(current_tags)
  },
  
  #' @description
  #' Removes all tags
  remove_all_tags = function(){
    clrCall(self$tags, "RemoveAll")
  },

  ##############################################################################
  # Result Functions
  ##############################################################################
  #' @description
  #' Returns a dataframe of all data using currently set parameters and tags
  #' This method requires that tags have been added via add_tag()
  get_results = function(){
    fetchrow <- clrCall(self$historianclass,"FetchRowData", self$tags)
    xmldata <- clrCall(fetchrow, "GetXml")
    dataframe <- XML::xmlToDataFrame((xml <- XML::xmlParse(xmldata)))
    dataframe
  },
  #' @description
  #' Returns a dataframe of all data using currently set parameters and tags
  #' This method requires that tags have been added via add_tag()
  get_results_split = function(){
    fetchrow <- clrCall(self$historianclass,"FetchRowData", self$tags)
    xmldata <- clrCall(fetchrow, "GetXml")
    dataframe <- XML::xmlToDataFrame((xml <- XML::xmlParse(xmldata)))
    if ("TagName" %in% colnames(dataframe)) {
      # Use the split function to split the dataframe into a list based on 'TagName'
      split_data <- split(dataframe, dataframe$TagName)
      return(split_data)
    } else {
      stop("The 'TagName' column does not exist in the dataframe.")
    }
    
  }
)
)
