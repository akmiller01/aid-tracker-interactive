list.of.packages <- c("data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) # Setting working directory to the input. Check this is where you locally have this repository, else change it.
setwd(wd)
setwd("..")
setwd("input")

unearmarked = fread("https://ddw.devinit.org/api/export/1612")
earmarked = fread("https://ddw.devinit.org/api/export/1616")

unearmarked_tab = unearmarked[,.(unearmarked_value=sum(`USD Disbursement`, na.rm=T)), by=.(Year, `Donor Name`)]
setnames(unearmarked_tab, "Year", "year")
# CRS = Overall
donor_name_mapping = c(
  "Central Emergency Response Fund"="UNOCHA",
  "Global Alliance for Vaccines and Immunization"="Gavi, The Vaccine Alliance",
  "Global Fund"="Global Fund",
  "IFAD"="International Fund for Agricultural Development",
  "UNAIDS"="UNAIDS",
  "UNDP"="UNDP",
  # "UNFPA", # In unearmarked, but not IATI selected donors
  "UNICEF"="UNICEF",
  # "UNRWA", # In unearmarked, but not IATI selected donors
  "WFP"="World Food Programme"
)

unearmarked_tab$country = donor_name_mapping[unearmarked_tab$`Donor Name`]

overall = fread("../overall.csv")
overall = subset(
  overall,
  aggregate_type=="Specific donor" &
  flow_type=="ODA" &
  timeframe=="Yearly" &
  transaction_type=="Disbursements" &
  variable=="Volume"
)
overall = overall[,c("country", "year", "transaction_type", "flow_type", "value")]

overall = merge(overall, unearmarked_tab, by=c("country", "year"), all.x=T)

earmarked_tab = earmarked[,.(earmarked_value=sum(`USD Disbursement`, na.rm=T)), by=.(Year, `Channel Name`)]
setnames(earmarked_tab, "Year", "year")
# CRS = Overall
channel_name_mapping = c(
  "Central Emergency Response Fund"="UNOCHA",
  "Global Alliance for Vaccines and Immunization"="Gavi, The Vaccine Alliance",
  "Global Fund to Fight AIDS, Tuberculosis and Malaria"="Global Fund",
  "International Committee of the Red Cross"="International Committee of the Red Cross",
  "International Fund for Agricultural Development"="International Fund for Agricultural Development",
  "Joint United Nations Programme on HIV/AIDS"="UNAIDS",
  "United Nations Children\u0092s Fund"="UNICEF",
  "United Nations Development Programme"="UNDP",
  "United Nations Industrial Development Organisation"="UNIDO",
  "United Nations Office of Co-ordination of Humanitarian Affairs"="UNOCHA",
  # "United Nations Population Fund", # In earmarked, but not in IATI selected donors
  # "United Nations Relief and Works Agency for Palestine Refugees in the Near East", # In earmarked, but not in IATI selected donors
  "World Food Programme"="World Food Programme"
)

earmarked_tab$country = channel_name_mapping[earmarked_tab$`Channel Name`]
earmarked_tab = earmarked_tab[,.(earmarked_value=sum(earmarked_value, na.rm=T), `Channel Name`=first(`Channel Name`)), by=.(year, country)]

overall = merge(overall, earmarked_tab, by=c("country", "year"), all.x=T)
overall = overall[,c(1, 9, 6, 2:5, 7:8)]
overall = subset(overall, !is.na(`Donor Name`) | !is.na(`Channel Name`))
overall$earmarked_value[which(is.na(overall$earmarked_value))] = 0
overall$unearmarked_value[which(is.na(overall$unearmarked_value))] = 0
overall$earmarked_plus_unearmarked = overall$earmarked_value + overall$unearmarked_value
overall$diff_iati_and_both = overall$value - overall$earmarked_plus_unearmarked
overall$diff_percentage = (overall$diff_iati_and_both / overall$earmarked_plus_unearmarked) * 100
overall = overall[order(overall$country, overall$year),] 
fwrite(overall, "../crs_comparison.csv")
