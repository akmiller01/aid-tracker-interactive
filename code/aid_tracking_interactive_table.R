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

donors <- fread("https://ddw.devinit.org/api/export/1254")

dat <- subset(dat,dat$`YYYYMM year and month`<=current_yyyymm)

dat$`Transaction Type` <- NA
dat$`Transaction Type`[which(dat$`Transaction Type Code` %in% c(3,4,7,8,"E","D","R","QP"))] <- "Disbursements"
dat$`Transaction Type`[which(dat$`Transaction Type Code` %in% c(2,"C"))] <- "Commitments"

dat <- dat[which(dat$`Transaction Type`%in%c("Commitments","Disbursements"))]

choices = c("Commitments","Disbursements")

for (this.choice in choices){
  data <- subset(dat,dat$`Transaction Type`==this.choice)
  data <- merge(data,donors,by.x="Reporting Organsation Reference",by.y="Reporting Organisation Reference Code",all=T)
  data$`Transaction Type` <- this.choice
  data$x_original_transaction_value_USDm_Sum[which(is.na(data$`YYYYMM year and month`))] <- ""
  data$`YYYYMM year and month`[which(is.na(data$`YYYYMM year and month`))] <- current_yyyymm
  assign(this.choice,data)
}

dat <- rbind(Commitments,Disbursements)

dat$usability <- NA
dat$usability[which(dat$`Transaction Type`=="Commitments")] <- dat$`Tracker Commit`[which(dat$`Transaction Type`=="Commitments")]
dat$usability[which(dat$`Transaction Type`=="Disbursements")] <- dat$`Tracker Spend`[which(dat$`Transaction Type`=="Disbursements")]
dat$usability_score <- dat$usability
dat$usability_score[which(is.na(dat$`Reporting Organisation Narrative`)&dat$usability=="Yes")] <- "Mid" 

dat$org_type[which(is.na(dat$org_type))] <- dat$`Organisation Type`[which(is.na(dat$org_type))]
dat$`Organisation Type` <- NULL
names(dat)[which(names(dat)=="org_type")] <- "Organisation Type"
dat$year_month = paste0(substr(dat$`YYYYMM year and month`,5,6),"-",substr(dat$`YYYYMM year and month`,1,4))

dat$x_original_transaction_value_USDm_Sum[which(is.na(dat$x_original_transaction_value_USDm_Sum))] <- ""

write.csv(dat,"usability.csv")
