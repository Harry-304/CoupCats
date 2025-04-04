#------------------------------------------------------------------------------------------------#
#Front-end stuff
#------------------------------------------------------------------------------------------------#  

#Building international-related variables

#Priority vars:
#regional dummies - COMPLETED
#trade
#cold war dummy - COMPLETED
#ongoing interstate war
#regional contagion
#FDI

#Secondary variables:
#foreign military training (McLauchlin/Seymour/Martel J. Peace Research 2022)
#international signals
#rivalries (Bak/Chavez/Rider J. Conflict Resolution 2019)
#defensive alliances (Boutton Intl Studies Quarterly 2019)
#peacekeeping (Banini/Powell/Yekple African Security 2020)

#1. clear all
rm(list = ls())
#2. set working directory
#setwd("~/R/coupcats") # Set working file. 
#setwd("C:/Users/clayt/OneDrive - University of Kentucky/elements/current_research/coupcats") #Clay at home
setwd("C:/Users/clthyn2/OneDrive - University of Kentucky/elements/current_research/coupcats") #clay at work
#3. install packages
#source("https://raw.githubusercontent.com/thynec/CoupCats/refs/heads/main/packages.R") 
#4. load libraries
#source("https://raw.githubusercontent.com/thynec/CoupCats/refs/heads/main/libraries.R") 
#5. build baseline
source("https://raw.githubusercontent.com/thynec/CoupCats/refs/heads/main/1.building_baseline.R")

#------------------------------------------------------------------------------------------------#
#add cold war dummy
#------------------------------------------------------------------------------------------------#  

base_data <- base_data %>%
  mutate(cold=ifelse(year<=1989, 1, 0))

#------------------------------------------------------------------------------------------------#
#add regions
#------------------------------------------------------------------------------------------------#  

#get regions from WDI
df <- WDI(indicator = c("CC.EST", "CC.PER.RNK"), country = "all", start = 1960, end = 2023, extra = TRUE)
df <- df %>%
  select(country, region) %>%
  distinct() 
ccodes2 <- ccodes %>%
  select(-year) %>%
  distinct()
df <- df %>%
  left_join(ccodes2, by=c("country"))
rm(ccodes2)
check <- df %>%
  filter(is.na(ccode))
table(check$country) #add Turkey=ccode=640
df <- df %>%
  mutate(ccode=ifelse(country=="Turkiye", 640, ccode))
check <- df %>%
  filter(is.na(ccode))
table(check$country) #all good
rm(check)
df <- df %>%
  select(-country) %>%
  distinct()
df <- df %>%
  rename(wdi_region=region) %>%
  mutate(e_asia_pacific=ifelse(wdi_region=="East Asia & Pacific", 1, 0)) %>%
  mutate(euro_cent_asia=ifelse(wdi_region=="Europe & Central Asia", 1, 0)) %>%
  mutate(LA_carrib=ifelse(wdi_region=="Latin America & Caribbean", 1, 0)) %>%
  mutate(MENA=ifelse(wdi_region=="Middle East & North Africa", 1, 0)) %>%
  mutate(N_america=ifelse(wdi_region=="North America", 1, 0)) %>%
  mutate(S_asia=ifelse(wdi_region=="South Asia", 1, 0)) %>%
  mutate(Sub_africa=ifelse(wdi_region=="Sub-Saharan Africa", 1, 0)) %>%
  set_variable_labels(
    e_asia_pacific="East Asia & Pacific",
    euro_cent_asia="Europe & Central Asia",
    LA_carrib="Latin America & Caribbean",
    MENA="Middle East & North Africa",
    N_america="North America",
    S_asia="South Asia",
    Sub_africa="Sub-Saharan Africa") %>%
  select(-wdi_region)
base <- base_data %>%
  left_join(df, by=c("ccode"))
check <- base %>%
  filter(is.na(MENA))
table(check$country) #got problems; WDI not recognizing old names; easy to fix manually
rm(check)
#fix missing
base <- base %>%
  mutate(euro_cent_asia=ifelse(country=="Czech Republic", 1, euro_cent_asia)) %>%
  mutate(euro_cent_asia=ifelse(country=="Czechoslovakia", 1, euro_cent_asia)) %>%
  mutate(euro_cent_asia=ifelse(country=="German Democratic Republic", 1, euro_cent_asia)) %>%
  mutate(euro_cent_asia=ifelse(country=="German Federal Republic", 1, euro_cent_asia)) %>%
  mutate(e_asia_pacific=ifelse(country=="Republic of Vietnam", 1, e_asia_pacific)) %>%
  mutate(e_asia_pacific=ifelse(country=="Taiwan", 1, e_asia_pacific)) %>%
  mutate(e_asia_pacific=ifelse(country=="Vietnam", 1, e_asia_pacific)) %>%
  mutate(Sub_africa=ifelse(country=="Zanzibar", 1, Sub_africa)) %>%
  mutate(MENA=ifelse(country=="Yemen Arab Republic", 1, MENA)) %>%
  mutate(MENA=ifelse(country=="Yemen People's Republic", 1, MENA))
check <- base %>%
  filter(is.na(e_asia_pacific)) %>%
  filter(is.na(MENA)) %>%
  filter(is.na(euro_cent_asia)) %>%
  filter(is.na(LA_carrib)) %>%
  filter(is.na(N_america)) %>%
  filter(is.na(S_asia)) %>%
  filter(is.na(Sub_africa))
table(check$country) #looks good
rm(check)
base <- base %>%
  mutate(across(everything(), ~ replace_na(.x, 0)))
base_data <- base
rm(base, df)

###############################################################################################
#Checked through above and ready to produce .csv and upload to github
#clean up if needed and export
#write.csv(base_data, gzfile("2.e.base_data.csv.gz"), row.names = FALSE)
#Now push push the file that was just written to the working directory to github
###############################################################################################  




#------------------------------------------------------------------------------------------------#
#add trade
#------------------------------------------------------------------------------------------------#  

#Start with COW; monadic
  url <- "https://correlatesofwar.org/wp-content/uploads/COW_Trade_4.0.zip"
  download.file(url, "data.zip")
  unzip("data.zip", exdir="data")
  cow <- read_csv("data/COW_Trade_4.0/National_COW_4.0.csv")
  unlink("data.zip")
  unlink("data", recursive=TRUE)
  rm(url)
cow <- cow %>%
  mutate(year=year+1) %>% #just lagged
  mutate(imports=ifelse(is.na(imports), 0, imports)) %>%
  mutate(exports=ifelse(is.na(exports), 0, exports)) %>%
  mutate(trade=(imports+exports)) %>%
  mutate(ltrade=log(trade+1)) %>%
  select(ccode, statename, year, trade, ltrade)

#Add WDI; monadic
  indicators <- c("NE.EXP.GNFS.CD", "NE.IMP.GNFS.CD")
  wdi <- WDI(indicator = indicators, start = 1960, end = 2025, extra = TRUE)
  rm(indicators)
  
df <- wdi %>%
  select(country, year, NE.EXP.GNFS.CD, NE.IMP.GNFS.CD) %>%
  rename(exports = NE.EXP.GNFS.CD) %>%
  rename(imports = NE.IMP.GNFS.CD) %>%
  mutate(imports=ifelse(is.na(imports), 0, imports)) %>%
  mutate(exports=ifelse(is.na(exports), 0, exports)) %>%
  mutate(year=year+1) %>%
  mutate(wdi_trade=(imports+exports)) %>%
  mutate(wdi_ltrade=log(wdi_trade+1)) %>%
  left_join(ccodes, by=c("country", "year"))
check <- df %>%
  filter(is.na(ccode))
table(check$country)


%>%
  select
  
  
#------------------------------------------------------------------------------------------------#
#alliances
#------------------------------------------------------------------------------------------------#  


url <- "http://www.atopdata.org/uploads/6/9/1/3/69134503/atop_5.1__.csv_.zip"
download.file (url, "atop.zip")#Downloads the dataset and saves it as data.zip in working directory.
unzip ("atop.zip", exdir = "atop") #Extracts the contents of the ZIP file into a folder named data.
atop <- read_csv("atop/ATOP 5.1 (.csv)/atop5_1m.csv")
rm(url)
unlink("atop.zip", recursive = TRUE )

atop <- atop %>%
  dplyr::select(member, yrent, moent, dayent, yrexit, moexit, dayexit) %>% 
  filter(yrexit >= 1950) %>%  #removing alliances that ended before 1950
  rename(ccode = member)


atop <- atop %>%
  rowwise() %>%
  mutate(
    # Generate a sequence of years from yrent to yrexit (or 2025 if yrexit is NA or 0)
    years = list(seq(yrent, ifelse(is.na(yrexit) | yrexit == 0, 2025, yrexit))),
    months = list(1:12)  # Always consider all months
  ) %>%
  unnest(years) %>%  # Expand the years
  unnest(months) %>%  # Expand the months
  filter(
    # Include only valid months: started in yrent/moent and hasn't ended yet
    (years > yrent | (years == yrent & months >= moent)) &  # Entry condition
      # Exit condition considering dayexit is NA or missing (means alliance ended at month-end)
      (is.na(yrexit) | yrexit == 0 | years < yrexit | (years == yrexit & months < moexit) | 
         (years == yrexit & months == moexit & (is.na(dayexit) | dayexit == 0)) |
         # Specifically handle alliances still in effect as of December 31, 2018
         (yrexit == 0 & moexit == 0 & dayexit == 0))
  ) %>%
  rename(year = years, month = months) %>%
  mutate(
    # Add a column indicating whether the country had an alliance (1) or not (0)
    alliance_active = 1  # All rows in this expanded data set are valid alliances
  ) %>%
  dplyr::select(ccode, year, month, alliance_active)

# Merge expanded atop with base_data
base_data <- base_data %>%
  left_join(atop, by = c("ccode", "year", "month")) %>%
  mutate(
    # If no alliance, mark as 0
    alliance_active = replace_na(alliance_active, 0)
  )
rm(atop)

#### Important note about alliances data: The ATOP dataset treats alliances that were still valid as of December 31, 2018 (they use yrexit==0), as ongoing. This means that if an alliance ended after 2018, it is still considered ongoing and will be marked as active in the dataset. 









# -------------------------- Int Signals ----------------------------- #

# 1. WEIS DATA
# 1.1. Getting the data
url <- "https://github.com/thynec/CoupCats/raw/refs/heads/data/weis.fromlai.1966-93.dta" #bringing in the data
weis <- read_dta(url)
rm(url)

# 1.2. Cleaning
weis <- weis %>% 
  dplyr::select(year,targcc, mo, gscale) %>% #selecting important variables
  rename(
    target = targcc,  
    month = mo   
  ) %>% 
  mutate("z_variable" = scale(weis$gscale)) #getting the z score

weis <- weis %>% 
  dplyr::select(year,target, month, z_variable)

# 2. COPDAB DATA
# 2.1. Getting the data
library(haven) # we needed this for copdab
url <- "https://www.uky.edu/~clthyn2/copdab.dta"
copdab <- read_dta(url(url, "rb"))
rm(url)

# 2.2. Cleaning and Fixing year
copdab <- copdab %>% 
  dplyr::select(year,target, month, value) %>% #selecting important variables
  filter(target != 4)

copdab <- copdab %>%
  mutate(year = 1900 + year)

# 2.3. Turning values into something meaningful 
copdab <- copdab %>%
  mutate(weight = case_when(
    value == 15 ~ -102,
    value == 14 ~ -65,
    value == 13 ~ -50,
    value == 12 ~ -44,
    value == 11 ~ -29,
    value == 10 ~ -16,
    value == 9 ~ -6,    # Negative for values from 15 to 9
    value == 8 ~ 1,
    value == 7 ~ 6,
    value == 6 ~ 10,
    value == 5 ~ 14,
    value == 4 ~ 27,
    value == 3 ~ 31,
    value == 2 ~ 47,
    value == 1 ~ 92,
    TRUE ~ NA_real_ # Ensures NA for any value outside the expected range
  )) %>% 
  select(-value)

copdab <-  copdab %>% 
  mutate("z_variable" = scale(copdab$weight))  # getting the z score

copdab <-  copdab %>% 
  dplyr::select(year,target, month, z_variable)

# 3. Merging both
int_signals <- weis %>%
  full_join(copdab, by=c("target", "year", "month", "z_variable"))

int_signals <-int_signals %>% 
  group_by(year, target, month) %>% 
  mutate(z= mean(z_variable))

int_signals <-int_signals %>% 
  select(-z_variable)

int_signals <- distinct(int_signals) 

base_data <- base_data %>% 
  left_join(int_signals, by = c("ccode" = "target", "year" = "year", "month" = "month"))

base_data <- base_data %>% 
  mutate(z = replace_na(z, 0)) %>%  #turning NAs to zeros
  rename(int_signal = z) 


###############################################################################################
#Checked through above and ready to produce .csv and upload to github
#clean up if needed and export
write.csv(base_data, gzfile("2.e.base_data.csv.gz"), row.names = FALSE)
#Now push push the file that was just written to the working directory to github
###############################################################################################  


