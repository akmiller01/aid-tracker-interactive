# Code to produce graphs needed for the live IATI COVID tracker page #


list.of.packages <- c("data.table", "anytime", "ggplot2", "scales", "bsts", "dplyr", "plyr","Hmisc","reshape2","splitstackshape","Cairo","svglite","extrafont","jsonlite","countrycode","openxlsx","english","stringr","tidyr","rstudioapi")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) # Setting working directory to the input. Check this is where you locally have this repository, else change it.
setwd(wd)
setwd("..")
setwd("input")

if(.Platform$OS.type == "unix") {
  home = "~/"
} else {
  home = "C:/"
}

all <- read.csv("donors_selected.csv")[,c("country","code","org_type","disbursements","commitments")] # Reading in manual donor quality checks. Binary: 1 = include, 0 = exclude.

#### DDW read-in ####

current_month <- month(Sys.Date()-75) # Note: This is the less than or equal to so if you want to include up to November, for example, this must say 11.
current_year <- year(Sys.Date()-75)
current_yyyymm <- format(Sys.Date()-75, "%Y%m") # Note: This must be preceded by a 0 if in the first nine months (i.e. 202105, not 20215)

choices <- c("commitments", "disbursements")

retrieval_reqd <- FALSE
retrieval_orgs <- c("XM-DAC-41122")
retrieval_date <- "251021"

##
options(timeout = 1000000)
##

for(choice in choices){
  
  if (choice == "commitments"){
    filename <- paste0("Trends in IATI - Commitments ", format(Sys.Date(), "%d%m%y"))
    if(!(paste0(filename, ".RDS") %in% list.files())){
      if(!(paste0(filename, ".csv") %in% list.files())){
        message("Commitments file for today not found, downloading.")
        download.file("https://ddw.devinit.org/api/export/793", paste0(filename, ".csv"), method = "libcurl")
      }
      dat <- fread(paste0(filename, ".csv"))
      saveRDS(dat, paste0(filename, ".RDS"))
    }
    dat <- readRDS(paste0(filename, ".RDS"))
    #dat <- fread("Trends in IATI - Commitments September 18.csv")
    # Data read-in. These can be retrieved from the DDW, as explained in the ReadME on the repo page.
  }
  if (choice == "disbursements"){
    unused_large_columns = c(
      "Title.Narrative"
      ,"Description.Narrative"
      ,"Transaction.Description.Narrative"
      ,"IATI.Identifier"
      ,"Transaction.Reference"
      ,"Implementing.Organisation.Narrative"
      ,"Funding.Organisation.Narrative"
      ,"Extending.Organisation.Narrative"
      ,"Accountable.Organisation.Narrative"
      ,"Transaction.Provider.Organisation.Provider.Activity.ID"
      ,"Transaction.Provider.Organisation.Narrative"
      ,"Transaction.Provider.Organisation.Reference"
      ,"Transaction.Receiver.Organisation.Receiver.Activity.ID"
      ,"Transaction.Receiver.Organisation.Narrative"
      ,"Transaction.Receiver.Organisation.Reference"
      ,"IATI.Registry.Package.ID"
      ,"DAC.Policy.Marker.Code"
      ,"DAC.Policy.Marker.Significance"
      ,"Humanitarian.Scope.Narrative"
      ,"Humanitarian.Emergency.Code...Calculated"
      ,"Humanitarian.Appeal.Code...Calculated"
      ,"Tag.Narrative"
      ,"Tag.Code"
    )
    filename <- paste0("Trends in IATI - Disbursements - 2018 to 2020 ", format(Sys.Date(), "%d%m%y"))
    if(!(paste0(filename, ".RDS") %in% list.files())){
      if(!(paste0(filename, ".csv") %in% list.files())){
        message("Disbursements file for today not found, downloading.")
        download.file("https://ddw.devinit.org/api/export/1528", paste0(filename, ".csv"), method = "libcurl")
      }
      dat1 <- read.csv(paste0(filename, ".csv"))
      saveRDS(dat1, paste0(filename, ".RDS"))
    }
    dat1 <- readRDS(paste0(filename, ".RDS"))
    dat1[,unused_large_columns] = NULL
    gc()
    filename <- paste0("Trends in IATI - Disbursements - 2021 onwards ", format(Sys.Date(), "%d%m%y"))
    if(!(paste0(filename, ".RDS") %in% list.files())){
      if(!(paste0(filename, ".csv") %in% list.files())){
        message("Disbursements file for today not found, downloading.")
        download.file("https://ddw.devinit.org/api/export/1510", paste0(filename, ".csv"), method = "libcurl")
      }
      dat2 <- read.csv(paste0(filename, ".csv"))
      saveRDS(dat2, paste0(filename, ".RDS"))
    }
    dat2 <- readRDS(paste0(filename, ".RDS"))
    dat2[,unused_large_columns] = NULL
    gc()
    # dat <- fread("Trends in IATI - Disbursements September 18.csv")
    dat <- rbind(dat1, dat2)
    gc()
    rm(dat1, dat2)
    gc()
  }
  
  meta_columns <- read.csv("meta_columns.csv")
  
  #### END ####
  
  # Lines that make column names consistent for what comes below.
  
  names(dat) <- gsub("...", " - ", names(dat), fixed = TRUE)
  names(dat) <- gsub(".", " ", names(dat), fixed = TRUE)
  dictionary <- merge(data.frame(names(dat)),meta_columns[,c("col_alias","col_name")],by.x="names.dat.",by.y="col_alias",all.x=T)
  dictionary$col_name[which(is.na(dictionary$col_name))] <- dictionary$names.dat.[which(is.na(dictionary$col_name))]
  names(dat) <- mapvalues(names(dat), from=dictionary$names.dat.,to=dictionary$col_name)
  dat$last_modified <- as.character(dat$last_modified)
  if (retrieval_reqd & choice == "commitments"){
    append <- readRDS(paste0("Trends in IATI - Commitments ",retrieval_date,".RDS"))
    append <- subset(append,append$`Reporting Organsation Reference` %in% retrieval_orgs)
    names(append) <- gsub("...", " - ", names(append), fixed = TRUE)
    names(append) <- gsub(".", " ", names(append), fixed = TRUE)
    dictionary <- merge(data.frame(names(append)),meta_columns[,c("col_alias","col_name")],by.x="names.append.",by.y="col_alias",all.x=T)
    dictionary$col_name[which(is.na(dictionary$col_name))] <- dictionary$names.append.[which(is.na(dictionary$col_name))]
    names(append) <- mapvalues(names(append), from=dictionary$names.append.,to=dictionary$col_name)
    dat <- rbind(dat,append)
  }
  
  if (retrieval_reqd & choice == "disbursements"){
    names(dat)[1] <- "iati_identifier"
    append <- readRDS(paste0("Trends in IATI - Disbursements ",retrieval_date,".RDS"))
    append <- subset(append,append$`Reporting Organsation Reference` %in% retrieval_orgs)
    names(append) <- gsub("...", " - ", names(append), fixed = TRUE)
    names(append) <- gsub(".", " ", names(append), fixed = TRUE)
    dictionary <- merge(data.frame(names(append)),meta_columns[,c("col_alias","col_name")],by.x="names.append.",by.y="col_alias",all.x=T)
    dictionary$col_name[which(is.na(dictionary$col_name))] <- dictionary$names.append.[which(is.na(dictionary$col_name))]
    names(append) <- mapvalues(names(append), from=dictionary$names.append.,to=dictionary$col_name)
    dat <- rbind(dat,append)
  }
  
  filtered_iati <- dat
  rm(dat)
  
  agg_oda_filtered <- subset(filtered_iati, reporting_org_ref %in% all$code) # Filter by reporting organisations considered in the donors_selected.csv.
  rm(filtered_iati)
  
  assign(choice,agg_oda_filtered) # Name the dataframe either 'disbursements' or 'commitments', respectively.
  rm(agg_oda_filtered)
  
  gc()
  #### Further filter of dataset ####
  
  t = get(choice)
  t$year <- t$x_transaction_year
  t$month <- as.numeric(substr(t$x_yyyymm,5,6))
  t <- subset(t,x_yyyymm <= current_yyyymm)
  gc()
  memory.limit(1000000000)
  t <- merge(t,unique(all),by.x="reporting_org_ref",by.y="code") # Merge in name and 'country' title for multiple agencies.
  gc()
  
  t <- subset(t,t[[choice]]==1) # Filter by reporting organisations by whether they are included for commitments/disbursements.
  gc()
  
  t <- subset(t,t$x_finance_type != "GNI: Gross National Income") # Removing DAC artefacts which are not flows.
  gc()
  
  t <- subset(t,t$x_finance_type != 1)
  gc()
  
  t <- subset(t,t$x_finance_type != "Guarantees/insurance")
  gc()
  
  t <- subset(t,t$x_finance_type != 1100)
  gc()
  # Note: GNI is a DAC artefact so needs removal and Guarantees/insurance is conditional.
  
  # Flow and Finance type sorting
  
  t$x_flow_type_code[is.na(t$x_flow_type_code)] <- "Not specified"
  t$x_flow_type_code[t$x_flow_type_code=="10"] <- "ODA"
  t$x_flow_type_code[t$x_flow_type_code=="20"] <- "OOF"
  t$x_flow_type_code[t$x_flow_type_code=="21"] <- "Non-export credit OOF"
  t$x_flow_type_code[t$x_flow_type_code=="30"] <- "Private Development Finance"
  t$x_flow_type_code[t$x_flow_type_code=="35"] <- "Private Market"
  t$x_flow_type_code[t$x_flow_type_code=="40"] <- "Non flow"
  t$x_flow_type_code[t$x_flow_type_code=="50"] <- "Other flows"
  
  # Grouping flow types
  t$flow_type <- t$x_flow_type_code
  t$flow_type[which(t$x_flow_type_code %in% c("OOF","Non-export credit OOF"))] <- "OOF"
  t$flow_type[which(t$x_flow_type_code %in% c("Private Development Finance","Private Market","Non flow","Other flows"))] <- "Other flows"

  # Making two separate data frames, one for overall and one for sector detail, as detailed in the IATI use guide - Reach out to Bill if you can't find this.
  t <- t[which(!is.na(t$org_type)),]
  t.hold <- t
  t <- data.table(t)[x_recipient_number==1 & x_sector_number==1]
  gc()
  
  t$x_original_transaction_value_usd <- t$x_original_transaction_value_usd/1000000
  t.hold$x_transaction_value_usd <- t.hold$x_transaction_value_usd/1000000
  t.hold$x_recipient_transaction_value_usd <- t.hold$x_recipient_transaction_value_usd/1000000

  
  #### Flows tab ####
  
  t.months <- t[year>2017,.(total_spend=sum(x_original_transaction_value_usd, na.rm=T)),by=.(year,month,x_yyyymm,reporting_org_ref,country,org_type,flow_type)] # Sum by month, organisation and flow type.
  t.months$org_type[which(t.months$org_type == "ifi")] <- "IFI"
  substr(t.months$org_type, 1, 1) <- toupper(substr(t.months$org_type, 1, 1))
  names(t.months)[which(names(t.months)=="total_spend")] <- "Specific donor"
  t.months$transaction_type <- choice
  substr(t.months$transaction_type, 1, 1) <- toupper(substr(t.months$transaction_type, 1, 1))
  t.months$x_yyyymm <- NULL
  t.months$reporting_org_ref <- NULL
  
  t.months <- melt(t.months,id.vars=c("country","org_type","flow_type","transaction_type","year","month"))
  names(t.months)[which(names(t.months)=="variable")]<-"aggregate_type"
  
  store <- expand.grid(unique(t.months$country),unique(t.months$flow_type),unique(t.months$transaction_type),unique(t.months$year),unique(t.months$month)) # Ensure every combination has an entry for the JavaScript to run.
  names(store) <- c("country","flow_type","transaction_type","year","month")
  merger <- unique(t.months[,c("country","org_type")])
  store <- merge(store,merger,by="country")
  store$aggregate_type="Specific donor"
  t.months$org_type <- NULL
  t.months <- merge(t.months,store,by=c("country","flow_type","transaction_type","year","month","aggregate_type"),all.y=T) # Merge the data with the table that covered all combinations.
  
  t.months$quarter[which(t.months$month <= 12)] <- 4 # Assign the quarter number to each row.
  t.months$quarter[which(t.months$month <= 9)] <- 3
  t.months$quarter[which(t.months$month <= 6)] <- 2
  t.months$quarter[which(t.months$month <= 3)] <- 1
  
  t.months_donor <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,flow_type,transaction_type,aggregate_type)]  # Sum by month, organisation type and flow type.
  t.months_donor$aggregate_type = "Organisation type"
  t.months_donor$country <- NA
  t.months <- rbind(t.months,t.months_donor)
  
  # Create proportions as well as absolute values.
  
  t.months <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type,flow_type)]
  t.months <- data.table(t.months)[,Proportion:=value/sum(value,na.rm=T),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.months)[which(names(t.months)=="value")] <- "Volume"
  t.months <- melt(t.months,id.vars=c("country","org_type","flow_type","transaction_type","year","quarter","month","aggregate_type"))
  t.months$timeframe <- "Monthly"
  t.months$rollingyear <- NA
  
  t.quarters <- data.table(t.months)[variable=="Volume",.(value=sum(value,na.rm=T)),by=.(quarter,year,org_type,country,transaction_type,aggregate_type,flow_type)]
  t.quarters <- data.table(t.quarters)[,Proportion:=value/sum(value,na.rm=T),by=.(quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.quarters)[which(names(t.quarters)=="value")] <- "Volume"
  t.quarters <- melt(t.quarters,id.vars=c("country","org_type","flow_type","transaction_type","year","quarter","aggregate_type"))
  t.quarters$month <- NA
  t.quarters$rollingyear <- NA
  t.quarters$timeframe <- "Quarterly"
  
  t.years <- data.table(t.quarters)[,.(value=sum(value,na.rm=T)),by=.(year,org_type,country,transaction_type,aggregate_type,flow_type)]
  t.years <- data.table(t.years)[,Proportion:=value/sum(value,na.rm=T),by=.(year,org_type,country,transaction_type,aggregate_type)]
  names(t.years)[which(names(t.years)=="value")] <- "Volume"
  t.years <- melt(t.years,id.vars=c("country","org_type","flow_type","transaction_type","year","aggregate_type"))
  t.years$month <- NA
  t.years$quarter <- NA
  t.years$rollingyear <- NA
  t.years$timeframe <- "Yearly"
  
  t.yeartodate <- t.months
  t.yeartodate$monthnumber <- t.yeartodate$year*12+t.yeartodate$month
  threshold <- current_year*12+current_month
  if (current_month<10) {current_month_fill = paste0("0",current_month)}else{current_month_fill = current_month}
  t.yeartodate$rollingyear <- NA
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=threshold & t.yeartodate$monthnumber>(threshold-12))] <- paste0(current_year,"-",current_month_fill) # Separating out by most current year to date and then so onwards.
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-12) & t.yeartodate$monthnumber>(threshold-24))] <- paste0(current_year-1,"-",current_month_fill)
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-24) & t.yeartodate$monthnumber>(threshold-36))] <- paste0(current_year-2,"-",current_month_fill)
  t.yeartodate <- data.table(t.yeartodate)[,.(value=sum(value,na.rm=T)),by=.(rollingyear,org_type,country,transaction_type,aggregate_type,flow_type)]
  t.yeartodate <- data.table(t.yeartodate)[,Proportion:=value/sum(value,na.rm=T),by=.(rollingyear,org_type,country,transaction_type,aggregate_type)]
  names(t.yeartodate)[which(names(t.yeartodate)=="value")] <- "Volume"
  t.yeartodate <- melt(t.yeartodate,id.vars=c("country","org_type","flow_type","transaction_type","rollingyear","aggregate_type"))
  t.yeartodate$month <- NA
  t.yeartodate$quarter <- NA
  t.yeartodate$year <- NA
  t.yeartodate$timeframe <- "Year to date"
  
  t.quarters <- subset(t.quarters,(t.quarters$year == current_year-2 & t.quarters$quarter > floor(current_month/3)) |(t.quarters$year == current_year-1)| (t.quarters$year == current_year & t.quarters$quarter <= floor(current_month/3))) # Only show those quarters which are in the last two full years of data
  t.months <- subset(t.months,(t.months$year == current_year-1 & t.months$month > current_month) | (t.months$year == current_year & t.months$month <= current_month))
  if (current_month < 12){
    t.years <- subset(t.years,t.years$year < current_year) # Only show the years with complete data for years.
  }else {t.years <- subset(t.years,t.years$year <= current_year)}
  t.yeartodate <- subset(t.yeartodate,!(is.na(t.yeartodate$rollingyear))) # We only gave rolling years to those we wanted previously so simple subset if rolling year field exists.
  
  t.overall <- rbind(t.months,t.quarters,t.years,t.yeartodate)
  
  assign(paste0("t.overall","_",choice),t.overall)
  
  gc()
  #### Poverty tab ####
  
  # Read in income file from inputs and label fully.
  
  income_groups <- fread("income.csv",header =T,na.strings = "..")
  income_groups <- melt(income_groups,id.vars=c("iso3","country"))
  names(income_groups)[3:4] <- c("year","income_group")
  income_groups$year <- as.integer(as.character(income_groups$year))
  income_groups$income_group[income_groups$income_group=="L"] <- "Low-income"
  income_groups$income_group[income_groups$income_group=="LM"] <- "Lower middle-income"
  income_groups$income_group[income_groups$income_group=="UM"] <- "Upper middle-income"
  income_groups$income_group[income_groups$income_group=="H"] <- "High-income"
  
  # Add income group as column to the data frame.
  
  t.hold$iso3c <- countrycode(t.hold$x_country_code,"iso2c","iso3c")
  t.hold <- data.table(t.hold)
  t.hold[x_country_code=="XK"]$iso3c <- "XKX"
  t.hold <- merge(t.hold,income_groups[,c("iso3","year","income_group")],
                  by.x=c("iso3c","year"),by.y=c("iso3","year"),all.x=T)
  
  # Extend poverty estimates where needed. ***This could be updated***
  
  logitapprox <- function(x, y, xout){
    delta <- 10^-16
    y <- y[!is.na(y)]
    x <- x[!is.na(y)]
    y[y == 1] <- 1-delta
    y[y == 0] <- delta
    suppressWarnings(ylogit <- log(y/(1-y)))
    if(length(ylogit[!is.na(ylogit)]) > 1){
      yapprox <- approxExtrap(x, ylogit, xout)$y
      yout <- 1/(1+exp(-yapprox))
      yout[is.nan(yout)] <- 0
    } else {
      yout <- NA
    }
    yout[yout == 1-delta] <- 1
    yout[yout == delta] <- 0
    return(yout)
  }
  
  gc()
  
  povcalcuts <- fread("p20-p80 data.csv")
  povcalyears <- c(2015:2022)
  povcal_additional <- subset(povcalcuts,povcalcuts$RequestYear==2021)
  povcal_additional$RequestYear <- 2022
  povcalcuts <- rbind(povcalcuts,povcal_additional)
  povcalcuts <- povcalcuts[CoverageType %in% c("N", "A"),
                           .(RequestYear=povcalyears,
                             P20Headcount=logitapprox(RequestYear, p20, povcalyears),
                             ExtPovHC=logitapprox(RequestYear, EPL, povcalyears),
                             P80Headcount=logitapprox(RequestYear, p80, povcalyears)),
                           by=.(CountryCode, CountryName, CoverageType)]
  
  t.hold <- merge(t.hold,povcalcuts[,c("CountryCode","RequestYear","ExtPovHC")],
                  by.x=c("iso3c","year"),by.y=c("CountryCode","RequestYear"),all.x=T)
  t.hold$poverty_band <- "Not specified"
  t.hold[ExtPovHC<0.05]$poverty_band <- "Less than 5%"
  t.hold[ExtPovHC>=0.05&ExtPovHC<0.2]$poverty_band <- "5-20%"
  t.hold[ExtPovHC>=0.2]$poverty_band <- "Above 20%"
  
  gc()
  # Read in LDCs and add a yes/no column.
  
  ldc <- read.csv("LDC_lookup.csv")
  
  t.hold <- merge(t.hold,ldc,
                  by.x=c("iso3c"),by.y=c("iso3"),all.x=T)
  
  t.calc <- subset(t.hold,t.hold$income_group %in% c("High-income","Upper middle-income","Lower middle-income","Low-income")) # This removes all disbursements/commitments to entities which are not countries. It does, however, remove regional spend.
  t.calc <- t.calc[which(!is.na(income_group))]
  t.calc$ldc[which(is.na(t.calc$ldc))]<-0
  t.calc <- t.calc[which(x_sector_number==1),] # Use recipient value in this now, as detailed in the IATI use guide.
  gc()

  # Income #
  
  t.months <- t.calc[year>2017,.(total_spend=sum(x_recipient_transaction_value_usd, na.rm=T)),by=.(year,month,x_yyyymm,reporting_org_ref,country,org_type,income_group,poverty_band,ldc,flow_type)]
  t.months.total <- t.calc[year>2017,.(total_spend=sum(x_recipient_transaction_value_usd, na.rm=T)),by=.(year,month,x_yyyymm,reporting_org_ref,country,org_type,income_group,poverty_band,ldc)]
  t.months.total$flow_type <- "All flows"
  t.months <- rbind(t.months,t.months.total)
  t.months$org_type[which(t.months$org_type == "ifi")] <- "IFI"
  substr(t.months$org_type, 1, 1) <- toupper(substr(t.months$org_type, 1, 1))
  names(t.months)[which(names(t.months)=="total_spend")] <- "Specific donor"
  t.months$transaction_type <- choice
  substr(t.months$transaction_type, 1, 1) <- toupper(substr(t.months$transaction_type, 1, 1))
  t.months$x_yyyymm <- NULL
  t.months$reporting_org_ref <- NULL
  
  t.months <- t.months[year>2017,.(`Specific donor`=sum(`Specific donor`, na.rm=T)),by=.(year,month,country,org_type,income_group,transaction_type,flow_type)]
  t.months <- melt(t.months,id.vars=c("country","org_type","transaction_type","year","month","income_group","flow_type"))
  names(t.months)[which(names(t.months)=="variable")]<-"aggregate_type"
  
  store <- expand.grid(unique(t.months$country),unique(t.months$income_group),unique(t.months$transaction_type),unique(t.months$year),unique(t.months$month),unique(t.months$flow_type))
  names(store) <- c("country","income_group","transaction_type","year","month","flow_type")
  merger <- unique(t.months[,c("country","org_type")])
  store <- merge(store,merger,by="country")
  store$aggregate_type="Specific donor"
  t.months$org_type <- NULL
  t.months <- merge(t.months,store,by=c("country","income_group","transaction_type","year","month","aggregate_type","flow_type"),all.y=T)
  
  t.months$quarter[which(t.months$month <= 12)] <- 4
  t.months$quarter[which(t.months$month <= 9)] <- 3
  t.months$quarter[which(t.months$month <= 6)] <- 2
  t.months$quarter[which(t.months$month <= 3)] <- 1
  
  t.months_donor <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,income_group,transaction_type,aggregate_type,flow_type)]
  t.months_donor$aggregate_type = "Organisation type"
  t.months_donor$country <- NA
  t.months <- rbind(t.months,t.months_donor)
  
  t.months <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type,income_group,flow_type)]
  t.months <- data.table(t.months)[,Proportion:=value/sum(value,na.rm=T),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.months)[which(names(t.months)=="value")] <- "Volume"
  t.months <- melt(t.months,id.vars=c("country","org_type","income_group","transaction_type","year","quarter","month","aggregate_type","flow_type"))
  t.months$timeframe <- "Monthly"
  t.months$rollingyear <- NA
  
  t.quarters <- data.table(t.months)[variable=="Volume",.(value=sum(value,na.rm=T)),by=.(quarter,year,org_type,country,transaction_type,aggregate_type,income_group,flow_type)]
  t.quarters <- data.table(t.quarters)[,Proportion:=value/sum(value,na.rm=T),by=.(quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.quarters)[which(names(t.quarters)=="value")] <- "Volume"
  t.quarters <- melt(t.quarters,id.vars=c("country","org_type","income_group","transaction_type","year","quarter","aggregate_type","flow_type"))
  t.quarters$month <- NA
  t.quarters$rollingyear <- NA
  t.quarters$timeframe <- "Quarterly"
  
  t.years <- data.table(t.quarters)[,.(value=sum(value,na.rm=T)),by=.(year,org_type,country,transaction_type,aggregate_type,income_group,flow_type)]
  t.years <- data.table(t.years)[,Proportion:=value/sum(value,na.rm=T),by=.(year,org_type,country,transaction_type,aggregate_type)]
  names(t.years)[which(names(t.years)=="value")] <- "Volume"
  t.years <- melt(t.years,id.vars=c("country","org_type","income_group","transaction_type","year","aggregate_type","flow_type"))
  t.years$month <- NA
  t.years$quarter <- NA
  t.years$rollingyear <- NA
  t.years$timeframe <- "Yearly"
  
  t.yeartodate <- t.months
  t.yeartodate$monthnumber <- t.yeartodate$year*12+t.yeartodate$month
  threshold <- current_year*12+current_month
  if (current_month<10) {current_month_fill = paste0("0",current_month)}else{current_month_fill = current_month}
  t.yeartodate$rollingyear <- NA
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=threshold & t.yeartodate$monthnumber>(threshold-12))] <- paste0(current_year,"-",current_month_fill)
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-12) & t.yeartodate$monthnumber>(threshold-24))] <- paste0(current_year-1,"-",current_month_fill)
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-24) & t.yeartodate$monthnumber>(threshold-36))] <- paste0(current_year-2,"-",current_month_fill)
  t.yeartodate <- data.table(t.yeartodate)[,.(value=sum(value,na.rm=T)),by=.(rollingyear,org_type,country,transaction_type,aggregate_type,income_group,flow_type)]
  t.yeartodate <- data.table(t.yeartodate)[,Proportion:=value/sum(value,na.rm=T),by=.(rollingyear,org_type,country,transaction_type,aggregate_type)]
  names(t.yeartodate)[which(names(t.yeartodate)=="value")] <- "Volume"
  t.yeartodate <- melt(t.yeartodate,id.vars=c("country","org_type","income_group","flow_type","transaction_type","rollingyear","aggregate_type"))
  t.yeartodate$month <- NA
  t.yeartodate$quarter <- NA
  t.yeartodate$year <- NA
  t.yeartodate$timeframe <- "Year to date"
  
  t.quarters <- subset(t.quarters,(t.quarters$year == current_year-2 & t.quarters$quarter > floor(current_month/3)) |(t.quarters$year == current_year-1)| (t.quarters$year == current_year & t.quarters$quarter <= floor(current_month/3)))
  t.months <- subset(t.months,(t.months$year == current_year-1 & t.months$month > current_month) | (t.months$year == current_year & t.months$month <= current_month))
  if (current_month < 12){
    t.years <- subset(t.years,t.years$year < current_year)
  }else {t.years <- subset(t.years,t.years$year <= current_year)}
  t.yeartodate <- subset(t.yeartodate,!(is.na(t.yeartodate$rollingyear)))
  
  t.overall <- rbind(t.months,t.quarters,t.years,t.yeartodate)
  t.overall$measure <- "Country income"
  names(t.overall)[which(names(t.overall)=="flow_type")] <- "oda_oof_other"
  names(t.overall)[which(names(t.overall)=="income_group")] <- "flow_type"
  t.overall$value[which(t.overall$variable=="Proportion")] <- t.overall$value[which(t.overall$variable=="Proportion")]*2
  
  assign(paste0("t.income_",choice),t.overall)
  gc()
  
  # Poverty #
  
  t.months <- t.calc[year>2017,.(total_spend=sum(x_recipient_transaction_value_usd, na.rm=T)),by=.(year,month,x_yyyymm,reporting_org_ref,country,org_type,income_group,poverty_band,ldc,flow_type)]
  t.months.total <- t.calc[year>2017,.(total_spend=sum(x_recipient_transaction_value_usd, na.rm=T)),by=.(year,month,x_yyyymm,reporting_org_ref,country,org_type,income_group,poverty_band,ldc)]
  t.months.total$flow_type <- "All flows"
  t.months <- rbind(t.months,t.months.total)
  t.months$org_type[which(t.months$org_type == "ifi")] <- "IFI"
  substr(t.months$org_type, 1, 1) <- toupper(substr(t.months$org_type, 1, 1))
  names(t.months)[which(names(t.months)=="total_spend")] <- "Specific donor"
  t.months$transaction_type <- choice
  substr(t.months$transaction_type, 1, 1) <- toupper(substr(t.months$transaction_type, 1, 1))
  t.months$x_yyyymm <- NULL
  t.months$reporting_org_ref <- NULL
  
  t.months <- t.months[year>2017,.(`Specific donor`=sum(`Specific donor`, na.rm=T)),by=.(year,month,country,org_type,poverty_band,transaction_type,flow_type)]
  t.months <- melt(t.months,id.vars=c("country","org_type","transaction_type","year","month","poverty_band","flow_type"))
  names(t.months)[which(names(t.months)=="variable")]<-"aggregate_type"
  
  store <- expand.grid(unique(t.months$country),unique(t.months$poverty_band),unique(t.months$transaction_type),unique(t.months$year),unique(t.months$month),unique(t.months$flow_type))
  names(store) <- c("country","poverty_band","transaction_type","year","month","flow_type")
  merger <- unique(t.months[,c("country","org_type")])
  store <- merge(store,merger,by="country")
  store$aggregate_type="Specific donor"
  t.months$org_type <- NULL
  t.months <- merge(t.months,store,by=c("country","poverty_band","transaction_type","year","month","aggregate_type","flow_type"),all.y=T)
  
  t.months$quarter[which(t.months$month <= 12)] <- 4
  t.months$quarter[which(t.months$month <= 9)] <- 3
  t.months$quarter[which(t.months$month <= 6)] <- 2
  t.months$quarter[which(t.months$month <= 3)] <- 1
  
  t.months_donor <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,poverty_band,transaction_type,aggregate_type,flow_type)]
  t.months_donor$aggregate_type = "Organisation type"
  t.months_donor$country <- NA
  t.months <- rbind(t.months,t.months_donor)
  
  t.months <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type,poverty_band,flow_type)]
  t.months <- data.table(t.months)[,Proportion:=value/sum(value,na.rm=T),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.months)[which(names(t.months)=="value")] <- "Volume"
  t.months <- melt(t.months,id.vars=c("country","org_type","poverty_band","transaction_type","year","quarter","month","aggregate_type","flow_type"))
  t.months$timeframe <- "Monthly"
  t.months$rollingyear <- NA
  
  t.quarters <- data.table(t.months)[variable=="Volume",.(value=sum(value,na.rm=T)),by=.(quarter,year,org_type,country,transaction_type,aggregate_type,poverty_band,flow_type)]
  t.quarters <- data.table(t.quarters)[,Proportion:=value/sum(value,na.rm=T),by=.(quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.quarters)[which(names(t.quarters)=="value")] <- "Volume"
  t.quarters <- melt(t.quarters,id.vars=c("country","org_type","poverty_band","transaction_type","year","quarter","aggregate_type","flow_type"))
  t.quarters$month <- NA
  t.quarters$rollingyear <- NA
  t.quarters$timeframe <- "Quarterly"
  
  t.years <- data.table(t.quarters)[,.(value=sum(value,na.rm=T)),by=.(year,org_type,country,transaction_type,aggregate_type,poverty_band,flow_type)]
  t.years <- data.table(t.years)[,Proportion:=value/sum(value,na.rm=T),by=.(year,org_type,country,transaction_type,aggregate_type)]
  names(t.years)[which(names(t.years)=="value")] <- "Volume"
  t.years <- melt(t.years,id.vars=c("country","org_type","poverty_band","transaction_type","year","aggregate_type","flow_type"))
  t.years$month <- NA
  t.years$quarter <- NA
  t.years$rollingyear <- NA
  t.years$timeframe <- "Yearly"
  
  t.yeartodate <- t.months
  t.yeartodate$monthnumber <- t.yeartodate$year*12+t.yeartodate$month
  threshold <- current_year*12+current_month
  if (current_month<10) {current_month_fill = paste0("0",current_month)}else{current_month_fill = current_month}
  t.yeartodate$rollingyear <- NA
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=threshold & t.yeartodate$monthnumber>(threshold-12))] <- paste0(current_year,"-",current_month_fill)
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-12) & t.yeartodate$monthnumber>(threshold-24))] <- paste0(current_year-1,"-",current_month_fill)
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-24) & t.yeartodate$monthnumber>(threshold-36))] <- paste0(current_year-2,"-",current_month_fill)
  t.yeartodate <- data.table(t.yeartodate)[,.(value=sum(value,na.rm=T)),by=.(rollingyear,org_type,country,transaction_type,aggregate_type,poverty_band,flow_type)]
  t.yeartodate <- data.table(t.yeartodate)[,Proportion:=value/sum(value,na.rm=T),by=.(rollingyear,org_type,country,transaction_type,aggregate_type)]
  names(t.yeartodate)[which(names(t.yeartodate)=="value")] <- "Volume"
  t.yeartodate <- melt(t.yeartodate,id.vars=c("country","org_type","poverty_band","flow_type","transaction_type","rollingyear","aggregate_type"))
  t.yeartodate$month <- NA
  t.yeartodate$quarter <- NA
  t.yeartodate$year <- NA
  t.yeartodate$timeframe <- "Year to date"
  
  t.quarters <- subset(t.quarters,(t.quarters$year == current_year-2 & t.quarters$quarter > floor(current_month/3)) |(t.quarters$year == current_year-1)| (t.quarters$year == current_year & t.quarters$quarter <= floor(current_month/3)))
  t.months <- subset(t.months,(t.months$year == current_year-1 & t.months$month > current_month) | (t.months$year == current_year & t.months$month <= current_month))
  if (current_month < 12){
    t.years <- subset(t.years,t.years$year < current_year)
  }else {t.years <- subset(t.years,t.years$year <= current_year)}
  t.yeartodate <- subset(t.yeartodate,!(is.na(t.yeartodate$rollingyear)))
  
  t.overall <- rbind(t.months,t.quarters,t.years,t.yeartodate)
  t.overall$measure <- "Population in poverty"
  names(t.overall)[which(names(t.overall)=="flow_type")] <- "oda_oof_other"
  names(t.overall)[which(names(t.overall)=="poverty_band")] <- "flow_type"
  t.overall$value[which(t.overall$variable=="Proportion")] <- t.overall$value[which(t.overall$variable=="Proportion")]*2
  
  assign(paste0("t.poverty_",choice),t.overall)
  gc()
  
  # LDC #
  
  t.months <- t.calc[year>2017,.(total_spend=sum(x_recipient_transaction_value_usd, na.rm=T)),by=.(year,month,x_yyyymm,reporting_org_ref,country,org_type,income_group,poverty_band,ldc,flow_type)]
  t.months.total <- t.calc[year>2017,.(total_spend=sum(x_recipient_transaction_value_usd, na.rm=T)),by=.(year,month,x_yyyymm,reporting_org_ref,country,org_type,income_group,poverty_band,ldc)]
  t.months.total$flow_type <- "All flows"
  t.months <- rbind(t.months,t.months.total)
  t.months$org_type[which(t.months$org_type == "ifi")] <- "IFI"
  substr(t.months$org_type, 1, 1) <- toupper(substr(t.months$org_type, 1, 1))
  names(t.months)[which(names(t.months)=="total_spend")] <- "Specific donor"
  t.months$transaction_type <- choice
  substr(t.months$transaction_type, 1, 1) <- toupper(substr(t.months$transaction_type, 1, 1))
  t.months$x_yyyymm <- NULL
  t.months$reporting_org_ref <- NULL
  
  t.months <- t.months[year>2017,.(`Specific donor`=sum(`Specific donor`, na.rm=T)),by=.(year,month,country,org_type,ldc,transaction_type,flow_type)]
  t.months <- melt(t.months,id.vars=c("country","org_type","transaction_type","year","month","ldc","flow_type"))
  names(t.months)[which(names(t.months)=="variable")]<-"aggregate_type"
  
  store <- expand.grid(unique(t.months$country),unique(t.months$ldc),unique(t.months$transaction_type),unique(t.months$year),unique(t.months$month),unique(t.months$flow_type))
  names(store) <- c("country","ldc","transaction_type","year","month","flow_type")
  merger <- unique(t.months[,c("country","org_type")])
  store <- merge(store,merger,by="country")
  store$aggregate_type="Specific donor"
  t.months$org_type <- NULL
  t.months <- merge(t.months,store,by=c("country","ldc","transaction_type","year","month","aggregate_type","flow_type"),all.y=T)
  
  t.months$quarter[which(t.months$month <= 12)] <- 4
  t.months$quarter[which(t.months$month <= 9)] <- 3
  t.months$quarter[which(t.months$month <= 6)] <- 2
  t.months$quarter[which(t.months$month <= 3)] <- 1
  
  t.months_donor <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,ldc,transaction_type,aggregate_type,flow_type)]
  t.months_donor$aggregate_type = "Organisation type"
  t.months_donor$country <- NA
  t.months <- rbind(t.months,t.months_donor)
  
  t.months <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type,ldc,flow_type)]
  t.months <- data.table(t.months)[,Proportion:=value/sum(value,na.rm=T),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.months)[which(names(t.months)=="value")] <- "Volume"
  t.months <- melt(t.months,id.vars=c("country","org_type","ldc","transaction_type","year","quarter","month","aggregate_type","flow_type"))
  t.months$timeframe <- "Monthly"
  t.months$rollingyear <- NA
  
  t.quarters <- data.table(t.months)[variable=="Volume",.(value=sum(value,na.rm=T)),by=.(quarter,year,org_type,country,transaction_type,aggregate_type,ldc,flow_type)]
  t.quarters <- data.table(t.quarters)[,Proportion:=value/sum(value,na.rm=T),by=.(quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.quarters)[which(names(t.quarters)=="value")] <- "Volume"
  t.quarters <- melt(t.quarters,id.vars=c("country","org_type","ldc","transaction_type","year","quarter","aggregate_type","flow_type"))
  t.quarters$month <- NA
  t.quarters$rollingyear <- NA
  t.quarters$timeframe <- "Quarterly"
  
  t.years <- data.table(t.quarters)[,.(value=sum(value,na.rm=T)),by=.(year,org_type,country,transaction_type,aggregate_type,ldc,flow_type)]
  t.years <- data.table(t.years)[,Proportion:=value/sum(value,na.rm=T),by=.(year,org_type,country,transaction_type,aggregate_type)]
  names(t.years)[which(names(t.years)=="value")] <- "Volume"
  t.years <- melt(t.years,id.vars=c("country","org_type","ldc","transaction_type","year","aggregate_type","flow_type"))
  t.years$month <- NA
  t.years$quarter <- NA
  t.years$rollingyear <- NA
  t.years$timeframe <- "Yearly"
  
  t.yeartodate <- t.months
  t.yeartodate$monthnumber <- t.yeartodate$year*12+t.yeartodate$month
  threshold <- current_year*12+current_month
  if (current_month<10) {current_month_fill = paste0("0",current_month)}else{current_month_fill = current_month}
  t.yeartodate$rollingyear <- NA
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=threshold & t.yeartodate$monthnumber>(threshold-12))] <- paste0(current_year,"-",current_month_fill)
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-12) & t.yeartodate$monthnumber>(threshold-24))] <- paste0(current_year-1,"-",current_month_fill)
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-24) & t.yeartodate$monthnumber>(threshold-36))] <- paste0(current_year-2,"-",current_month_fill)
  t.yeartodate <- data.table(t.yeartodate)[,.(value=sum(value,na.rm=T)),by=.(rollingyear,org_type,country,transaction_type,aggregate_type,ldc,flow_type)]
  t.yeartodate <- data.table(t.yeartodate)[,Proportion:=value/sum(value,na.rm=T),by=.(rollingyear,org_type,country,transaction_type,aggregate_type)]
  names(t.yeartodate)[which(names(t.yeartodate)=="value")] <- "Volume"
  t.yeartodate <- melt(t.yeartodate,id.vars=c("country","org_type","ldc","flow_type","transaction_type","rollingyear","aggregate_type"))
  t.yeartodate$month <- NA
  t.yeartodate$quarter <- NA
  t.yeartodate$year <- NA
  t.yeartodate$timeframe <- "Year to date"
  
  t.quarters <- subset(t.quarters,(t.quarters$year == current_year-2 & t.quarters$quarter > floor(current_month/3)) |(t.quarters$year == current_year-1)| (t.quarters$year == current_year & t.quarters$quarter <= floor(current_month/3)))
  t.months <- subset(t.months,(t.months$year == current_year-1 & t.months$month > current_month) | (t.months$year == current_year & t.months$month <= current_month))
  if (current_month < 12){
    t.years <- subset(t.years,t.years$year < current_year)
  }else {t.years <- subset(t.years,t.years$year <= current_year)}
  t.yeartodate <- subset(t.yeartodate,!(is.na(t.yeartodate$rollingyear)))
  
  t.overall <- rbind(t.months,t.quarters,t.years,t.yeartodate)
  t.overall$measure <- "LDC status"
  names(t.overall)[which(names(t.overall)=="flow_type")] <- "oda_oof_other"
  names(t.overall)[which(names(t.overall)=="ldc")] <- "flow_type"
  t.overall$flow_type[which(t.overall$flow_type==1)] <- "LDC"
  t.overall$flow_type[which(t.overall$flow_type==0)] <- "Non-LDC"
  t.overall$value[which(t.overall$variable=="Proportion")] <- t.overall$value[which(t.overall$variable=="Proportion")]*2
  
  assign(paste0("t.ldc_",choice),t.overall)
  gc()
  
  #### Sector tab ####
  
  full_list <- read.xlsx("sector_mapping.xlsx",sheet="Sector mapping",startRow=3)[,c("DESCRIPTION","Aggregate")] # General mapping
  full_list <- full_list[!is.na(full_list$DESCRIPTION),]
  names(full_list) <- c("sector","category")
  full_list <- full_list[!duplicated(full_list),]
  
  full_itep_list <- read.xlsx("sector_mapping.xlsx",sheet="ITEP mapping")[,c("ITEP","DAC3")] # ITEP mapping
  names(full_itep_list) <- c("ITEP","sector")
  full_itep_list$sector <- as.character(full_itep_list$sector)
  
  
  t.sector <- subset(t.hold,x_sector_vocabulary %in% c("1","2",""))
  t.sector <- merge(t.sector,full_list,by.x="x_dac3_sector",by.y="sector",all.x=T) 
  t.sector <- merge(t.sector,full_itep_list,by.x="x_dac3_sector",by.y="sector",all.x=T)
  
  t.sector$ITEP <- gsub("&","and",t.sector$ITEP) # Communications change.
  
  t.months <- data.table(t.sector)[year>2017,.(total_spend=sum(x_transaction_value_usd, na.rm=T)),by=.(year,month,x_yyyymm,reporting_org_ref,country,org_type,flow_type,ITEP)]
  t.months.total <- data.table(t.sector)[year>2017,.(total_spend=sum(x_transaction_value_usd, na.rm=T)),by=.(year,month,x_yyyymm,reporting_org_ref,country,org_type,ITEP)]
  t.months.total$flow_type <- "All flows"
  t.months <- rbind(t.months,t.months.total)
  t.months$org_type[which(t.months$org_type == "ifi")] <- "IFI"
  substr(t.months$org_type, 1, 1) <- toupper(substr(t.months$org_type, 1, 1))
  names(t.months)[which(names(t.months)=="total_spend")] <- "Specific donor"
  t.months$transaction_type <- choice
  substr(t.months$transaction_type, 1, 1) <- toupper(substr(t.months$transaction_type, 1, 1))
  t.months$x_yyyymm <- NULL
  t.months$reporting_org_ref <- NULL
  
  t.months <- melt(t.months,id.vars=c("country","org_type","flow_type","transaction_type","year","month","ITEP"))
  names(t.months)[which(names(t.months)=="variable")]<-"aggregate_type"
  
  store <- expand.grid(unique(t.months$country),unique(t.months$flow_type),unique(t.months$transaction_type),unique(t.months$year),unique(t.months$month),unique(t.months$ITEP))
  names(store) <- c("country","flow_type","transaction_type","year","month","ITEP")
  merger <- unique(t.months[,c("country","org_type")])
  store <- merge(store,merger,by="country")
  store$aggregate_type="Specific donor"
  t.months$org_type <- NULL
  t.months <- merge(t.months,store,by=c("country","flow_type","transaction_type","year","month","ITEP","aggregate_type"),all.y=T)
  
  t.months$quarter[which(t.months$month <= 12)] <- 4
  t.months$quarter[which(t.months$month <= 9)] <- 3
  t.months$quarter[which(t.months$month <= 6)] <- 2
  t.months$quarter[which(t.months$month <= 3)] <- 1
  
  t.months_donor <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,flow_type,transaction_type,aggregate_type,ITEP)]
  t.months_donor$aggregate_type = "Organisation type"
  t.months_donor$country <- NA
  t.months <- rbind(t.months,t.months_donor)
  
  t.months <- data.table(t.months)[,.(value=sum(value,na.rm=T)),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type,ITEP,flow_type)]
  t.months <- data.table(t.months)[,Proportion:=value/sum(value,na.rm=T),by=.(month,quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.months)[which(names(t.months)=="value")] <- "Volume"
  t.months <- melt(t.months,id.vars=c("country","org_type","ITEP","transaction_type","year","quarter","month","aggregate_type","flow_type"))
  t.months$timeframe <- "Monthly"
  t.months$rollingyear <- NA
  
  t.quarters <- data.table(t.months)[variable=="Volume",.(value=sum(value,na.rm=T)),by=.(quarter,year,org_type,country,transaction_type,aggregate_type,ITEP,flow_type)]
  t.quarters <- data.table(t.quarters)[,Proportion:=value/sum(value,na.rm=T),by=.(quarter,year,org_type,country,transaction_type,aggregate_type)]
  names(t.quarters)[which(names(t.quarters)=="value")] <- "Volume"
  t.quarters <- melt(t.quarters,id.vars=c("country","org_type","ITEP","transaction_type","year","quarter","aggregate_type","flow_type"))
  t.quarters$month <- NA
  t.quarters$rollingyear <- NA
  t.quarters$timeframe <- "Quarterly"
  
  t.years <- data.table(t.quarters)[,.(value=sum(value,na.rm=T)),by=.(year,org_type,country,transaction_type,aggregate_type,ITEP,flow_type)]
  t.years <- data.table(t.years)[,Proportion:=value/sum(value,na.rm=T),by=.(year,org_type,country,transaction_type,aggregate_type)]
  names(t.years)[which(names(t.years)=="value")] <- "Volume"
  t.years <- melt(t.years,id.vars=c("country","org_type","ITEP","transaction_type","year","aggregate_type","flow_type"))
  t.years$month <- NA
  t.years$quarter <- NA
  t.years$rollingyear <- NA
  t.years$timeframe <- "Yearly"
  
  t.yeartodate <- t.months
  t.yeartodate$monthnumber <- t.yeartodate$year*12+t.yeartodate$month
  threshold <- current_year*12+current_month
  if (current_month<10) {current_month_fill = paste0("0",current_month)}else{current_month_fill = current_month}
  t.yeartodate$rollingyear <- NA
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=threshold & t.yeartodate$monthnumber>(threshold-12))] <- paste0(current_year,"-",current_month_fill)
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-12) & t.yeartodate$monthnumber>(threshold-24))] <- paste0(current_year-1,"-",current_month_fill)
  t.yeartodate$rollingyear[which(t.yeartodate$monthnumber<=(threshold-24) & t.yeartodate$monthnumber>(threshold-36))] <- paste0(current_year-2,"-",current_month_fill)
  t.yeartodate <- data.table(t.yeartodate)[,.(value=sum(value,na.rm=T)),by=.(rollingyear,org_type,country,transaction_type,aggregate_type,ITEP,flow_type)]
  t.yeartodate <- data.table(t.yeartodate)[,Proportion:=value/sum(value,na.rm=T),by=.(rollingyear,org_type,country,transaction_type,aggregate_type)]
  names(t.yeartodate)[which(names(t.yeartodate)=="value")] <- "Volume"
  t.yeartodate <- melt(t.yeartodate,id.vars=c("country","org_type","ITEP","flow_type","transaction_type","rollingyear","aggregate_type"))
  t.yeartodate$month <- NA
  t.yeartodate$quarter <- NA
  t.yeartodate$year <- NA
  t.yeartodate$timeframe <- "Year to date"
  
  t.quarters <- subset(t.quarters,(t.quarters$year == current_year-2 & t.quarters$quarter > floor(current_month/3)) |(t.quarters$year == current_year-1)| (t.quarters$year == current_year & t.quarters$quarter <= floor(current_month/3)))
  t.months <- subset(t.months,(t.months$year == current_year-1 & t.months$month > current_month) | (t.months$year == current_year & t.months$month <= current_month))
  if (current_month < 12){
    t.years <- subset(t.years,t.years$year < current_year)
  }else {t.years <- subset(t.years,t.years$year <= current_year)}
  t.yeartodate <- subset(t.yeartodate,!(is.na(t.yeartodate$rollingyear)))
  
  t.overall <- rbind(t.months,t.quarters,t.years,t.yeartodate)
  
  names(t.overall)[which(names(t.overall)=="flow_type")] <- "oda_oof_other"
  names(t.overall)[which(names(t.overall)=="ITEP")] <- "flow_type"
  t.overall$value[which(t.overall$variable=="Proportion")] <- t.overall$value[which(t.overall$variable=="Proportion")]*2
  
  assign(paste0("t.","sector_",choice),t.overall)
  
  keep_env = c(
    "home",
    "all",
    "filename",
    "t.sector_commitments",
    "t.sector_disbursements",
    "t.income_commitments",
    "t.income_disbursements",
    "t.ldc_commitments",
    "t.ldc_disbursements",
    "t.poverty_commitments",
    "t.poverty_disbursements",
    "t.overall_commitments",
    "t.overall_disbursements",
    "current_month",
    "current_year",
    "current_yyyymm",
    "choice",
    "choices",
    "retrieval_reqd",
    "retrieval_orgs",
    "retrieval_date"
  )
  drop_env = setdiff(ls(), keep_env)
  rm(list=drop_env)
  gc()
  if(choice == "commitments"){
    save(
      t.sector_commitments,
      t.income_commitments,
      t.ldc_commitments,
      t.poverty_commitments,
      t.overall_commitments,
      file=paste0("commitments_processed_",format(Sys.Date(), "%d%m%y"),".RData")
    )
    rm(t.sector_commitments,
       t.income_commitments,
       t.ldc_commitments,
       t.poverty_commitments,
       t.overall_commitments)
    gc()
  }
  if(choice == "disbursements"){
    save(
      t.sector_disbursements,
      t.income_disbursements,
      t.ldc_disbursements,
      t.poverty_disbursements,
      t.overall_disbursements,
      file=paste0("disbursements_processed_",format(Sys.Date(), "%d%m%y"),".RData")
    )
  }
}
#### Combination and CSV production ####
load(paste0("commitments_processed_",format(Sys.Date(), "%d%m%y"),".RData"))
setwd(
  paste0(home, "git/aid-tracker-interactive")
)
sector <- rbind(t.sector_commitments,t.sector_disbursements)
sector$org_type[which(sector$aggregate=="Specific donor")] <- sector$country[which(sector$aggregate=="Specific donor")] # Make the org_type be the country field in all 'specific donor' entries.
sector$flow_type <- tolower(sector$flow_type)
substr(sector$flow_type,1,1) <- toupper(substr(sector$flow_type,1,1))
write.csv(sector,"sector.csv")

poverty <- rbind(t.income_commitments,t.income_disbursements,t.ldc_commitments,t.ldc_disbursements,t.poverty_commitments,t.poverty_disbursements)
poverty$org_type[which(poverty$aggregate=="Specific donor")] <- poverty$country[which(poverty$aggregate=="Specific donor")]
write.csv(poverty,"poverty.csv")  

overall <- rbind(t.overall_commitments,t.overall_disbursements)
overall$org_type[which(overall$aggregate=="Specific donor")] <- overall$country[which(overall$aggregate=="Specific donor")]
write.csv(overall,"overall.csv")


