# Code to produce graphs needed for the live IATI COVID tracker page #


list.of.packages <- c("data.table", "anytime", "ggplot2", "scales", "bsts", "dplyr", "plyr","Hmisc","reshape2","splitstackshape","Cairo","svglite","extrafont","jsonlite","countrycode","openxlsx","english","stringr","tidyr","rstudioapi")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) # Setting working directory to the input. Check this is where you locally have this repository, else change it.
setwd(wd)
setwd("..")
setwd("input")

all <- read.csv("donors_selected.csv")[,c("country","code","org_type","disbursements","commitments")] # Reading in manual donor quality checks. Binary: 1 = include, 0 = exclude.

one <- read.csv("Trends in IATI - Disbursements - 2018 to 2020 251022.csv")
two <- read.csv("Trends in IATI - Disbursements - 2021 onwards 251022.csv")

write <- rbind(one,two)

saveRDS(write, "Trends in IATI - Disbursements 251022.RDS")
