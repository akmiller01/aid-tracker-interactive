# Code to produce table needed for the live IATI COVID tracker page #

list.of.packages <- c("rstudioapi","data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)
  
wd <- dirname(getActiveDocumentContext()$path) # Setting working directory to the input. Check this is where you locally have this repository, else change it.
setwd(wd)
setwd("..")

#### DDW read-in ####

current_month <- month(Sys.Date()-75) # Note: This is the less than or equal to so if you want to include up to November, for example, this must say 11.
current_year <- year(Sys.Date()-75)
current_yyyymm <- format(Sys.Date()-75, "%Y%m") # Note: This must be preceded by a 0 if in the first nine months (i.e. 202105, not 20215)

dat <- fread("https://ddw.devinit.org/api/export/1250")

dat <- subset(dat,dat$`YYYYMM year and month`<=current_yyyymm)

dat$`Transaction Type` <- NA
dat$`Transaction Type`[which(dat$`Transaction Type Code` %in% c(3,4,7,8,"E","D","R","QP"))] <- "Disbursements"
dat$`Transaction Type`[which(dat$`Transaction Type Code` %in% c(2,"C"))] <- "Commitments"

dat <- dat[which(dat$`Transaction Type`%in%c("Commitments","Disbursements"))]

dat$usability <- NA
dat$usability[which(dat$`Transaction Type`=="Commitments")] <- dat$tracker_commit[which(dat$`Transaction Type`=="Commitments")]
dat$usability[which(dat$`Transaction Type`=="Disbursements")] <- dat$tracker_spend[which(dat$`Transaction Type`=="Disbursements")]

names(dat)[which(names(dat)=="org_type")] <- "Organisation Type"

write.csv(dat,"usability.csv")
