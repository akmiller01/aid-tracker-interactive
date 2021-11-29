# Code to produce graphs needed for the live IATI COVID tracker page #

{
  list.of.packages <- c("data.table", "anytime", "ggplot2", "scales", "bsts", "dplyr", "plyr","Hmisc","reshape2","splitstackshape","Cairo","svglite","extrafont","jsonlite","countrycode","openxlsx","english","stringr","tidyr","rstudioapi")
  new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
  if(length(new.packages)) install.packages(new.packages)
  lapply(list.of.packages, require, character.only=T)
  
  wd <- dirname(getActiveDocumentContext()$path) # Setting working directory to the input. Check this is where you locally have this repository, else change it.
  setwd(wd)
  setwd("..")
}
#### DDW read-in ####

current_month <- month(Sys.Date()-75) # Note: This is the less than or equal to so if you want to include up to November, for example, this must say 11.
current_yyyymm <- format(Sys.Date()-75, "%Y%m") # Note: This must be preceded by a 0 if in the first nine months (i.e. 202105, not 20215)

choices <- c("Commitments", "Disbursements")
sheets <- c("overall","poverty","sector")
types <- c("data_old_","data_")

##
options(timeout = 1000)
##

for (sheet in sheets){
  
  data <- read.csv(paste0(sheet,".csv"))
  data_old <- read.csv(paste0(sheet,"_old.csv"))
    
  for(choice in choices){
  
    data_by_type <- subset(data,transaction_type==choice)
    data_old_by_type <- subset(data_old,transaction_type==choice)
    
    for (type in types) {
      publishers <- unique(get(paste0(type,"by_type"))[,"country"])
      assign(paste0(type,"publishers"),publishers)
    }

    if (!(length(setdiff(data_old_publishers,data_publishers))==0 && length(setdiff(data_publishers,data_old_publishers))==0)){
      print(choice)
      print(sheet)
      print(paste0("We're missing ",paste0(setdiff(data_old_publishers,data_publishers),collapse=", "), " from before and we have added ", paste0(setdiff(data_publishers,data_old_publishers),collapse=", ")," in ",choice, " - ", sheet))
    }
    
    
  }
}
