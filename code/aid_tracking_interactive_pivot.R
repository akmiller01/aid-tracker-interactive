# Code to produce graphs needed for the live IATI COVID tracker page #

{
  list.of.packages <- c("data.table", "anytime", "ggplot2", "scales", "bsts", "dplyr", "plyr","Hmisc","reshape2","splitstackshape","Cairo","svglite","extrafont","jsonlite","countrycode","openxlsx","english","stringr","tidyr","rstudioapi")
  new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
  if(length(new.packages)) install.packages(new.packages)
  lapply(list.of.packages, require, character.only=T)
  
  wd <- dirname(getActiveDocumentContext()$path) # Setting working directory to the input. Check this is where you locally have this repository, else change it.
  setwd(wd)
  setwd("..")
  
  all <- read.csv("input/donors_selected.csv")[,c("country","code","org_type","disbursements","commitments")] # Reading in manual donor quality checks. Binary: 1 = include, 0 = exclude.
}

overall <- read.csv("overall.csv")

overall <- subset(overall,timeframe=="Monthly"&variable=="Volume"&aggregate_type=="Specific donor")[c("country","transaction_type","year","month","value")]

overall <- data.table(overall)[,.(value=sum(value,na.rm=T)),by=.(country,transaction_type,year,month)]

mymonths <- c("Jan","Feb","Mar",
              "Apr","May","Jun",
              "Jul","Aug","Sep",
              "Oct","Nov","Dec")

overall$monthname = mymonths[overall$month]

overall$yyyymm <- paste0(overall$monthname,"-",overall$year)

oveall$value <- overall$value/1000

names(overall)[which(names(overall)=="value")]="Value US$bn"

donors <- read.csv("input/donors_selected.csv")

overall <- merge(overall,unique(donors[c("country","org_type")]),by="country")

overall$org_type[which(overall$org_type=="bilateral")]="Bilateral"
overall$org_type[which(overall$org_type=="multilateral")]="Multilateral"
overall$org_type[which(overall$org_type=="ifi")]="IFI"

write.csv(overall,"overall_pivot.csv",row.names = FALSE)
