#------------------------------------------------------------------------------
# Data manipulation of banding data to create m-arrays for band recovery models
#------------------------------------------------------------------------------
rm(list=ls())
# Read in dataset
raw<-read.csv("AMWO recoveries.csv")  #reading in CSV from GitHub-linked timberdoodle folder
tail(raw) #6897 records

########################################################################
#cleaning data
########################################################################

#only use status 3 birds
raw<-subset(raw,Status==3)                #6,879 records (18 excluded)

#only use how obtained category 1 (shot)  
raw<-subset(raw,How.Obt==1)               #5,911 records (968 excluded)

#only use B.Year from 1963 onwards
raw<-subset(raw,B.Year>=1963)             #5,516 records (395 excluded)

#subset B.Month between 4 and 9 to cover our 2 seasons
raw<-subset(raw,B.Month>=4&B.Month<=9)    #4,377 records (1139 excluded)

## TA modified, take out recoveries of birds shot in March through August (non-hunting season)
raw<-subset(raw,R.Month!=3)
raw<-subset(raw,R.Month!=4)
raw<-subset(raw,R.Month!=5)
raw<-subset(raw,R.Month!=6)
raw<-subset(raw,R.Month!=7)
raw<-subset(raw,R.Month!=8)               #4,367 records (10 excluded)

## TA added
# remove birds with ambiguous harvest season
raw<-subset(raw,R.Month!=99)
summary(raw$Species.Game.Birds..SPEC)      #4,364 records (3 excluded)

## TA added
# remove birds with ambiguous hunting seasons survived (uncertainty about encounter date when reported)
raw<-subset(raw,Hunt..Season.Surv.!=99)    #4,346 records (18 excluded)

## TA added
# remove radio transmitters (meta-analyses suggest survival and harvest effects)
raw<-subset(raw,Add.Info!=89)
raw<-subset(raw,Add.Info!=81)              #4,281 records (65 excluded)

# inspect remaining categories
summary(raw)

#bring in B.month, convert to season
clean<-matrix(NA,nrow=length(raw$B.Month),ncol=1)
clean<-data.frame(clean)
clean[raw$B.Month>=4&raw$B.Month<=6,]<-1  
clean[raw$B.Month>=7&raw$B.Month<=9,]<-2      # 2,225 spring (Apr-Jun), 2,056 summer (Jul-Sep)

#Bring in B.year
clean[,2]<-raw$B.Year  

#bring in recovery year and account for recoveries occurring in Jan-Feb
clean[,3]<-NA
clean[raw$R.Month>=4,3]<-raw[raw$R.Month>=4,"R.Year"]
clean[raw$R.Month<4,3]<-raw[raw$R.Month<4,"R.Year"]-1
#head(clean) ## TA properly accounts for Jan-Feb recoveries

#bring in B region
clean[,4]<-0
clean[raw$B.Flyway==1,4]<-1  ## Eastern region, U.S
clean[raw$B.Flyway%in%2:3,4]<-2  ## Central region, U.S
clean[raw$B.Flyway==6&raw$BRegion..STA%in%c("QC","NS","NB","PE","NF","PQ"),4]<-1 ## Add eastern Canada (165)
clean[raw$B.Flyway==6&raw$BRegion..STA%in%c("ONT","MB"),4]<-2  ## 19 from ONT, added Manitoba to code (no recoveries, but some bandings)
# 1,663 eastern recoveries, 2,618 central recoveries

#bring in R region, this is only to exlude region crossers
clean[,5]<-0 #specify different number from previous step to flag it in the next step
clean[raw$R.Flyway==1,5]<-1
clean[raw$R.Flyway%in%2:3,5]<-2
clean[raw$R.Flyway==6&raw$RRegion..STA%in%c("QC","NS","NB","PE","NF","PQ"),5]<-1
clean[raw$R.Flyway==6&raw$RRegion..STA%in%c("ONT", "MB"),5]<-2

# removes lines of region crossers
raw<-raw[clean$V4==clean$V5,]
clean<-clean[clean$V4==clean$V5,]
clean<-clean[,1:4] #remove R.state becuase it is redundant 
# 1,663 to 1595 eastern recoveries, 2,618 to 2604 central recoveries

## TA's independent tally, 68 Eastern pop harvested in Central, 14 Central harvested in Eastern (perfect match!)

#bring in age
# local = 1, hatch year = 2, adult = 3
clean[,5]<-NA
clean[raw$Age..VAGE=="After Hatch Year",5]<-3
clean[raw$Age..VAGE=="After Second Year",5]<-3
clean[raw$Age..VAGE=="After Third Year",5]<-3
clean[raw$Age..VAGE=="Second Year",5]<-3
clean[raw$Age..VAGE=="Unknown",5]<-NA     ##delete 39 unknown age at banding
clean[raw$Age..VAGE=="Hatch Year",5]<-2
clean[raw$Age..VAGE=="Local",5]<-1
#remove unknowns
raw<-raw[!is.na(clean[,5]),]
clean<-clean[!is.na(clean[,5]),]      ## 1530 locals, 1504 HY, 1126 adults

# get rid of hatch years in months 4, 5 and 6
clean <- clean[!(raw$Age..VAGE=="Hatch Year"&raw$B.Month%in%c(4:6)),]
raw <- raw[!(raw$Age..VAGE=="Hatch Year"&raw$B.Month%in%c(4:6)),]

## there are also 2 locals banded in month 7
clean <- clean[!(raw$Age..VAGE=="Local"&raw$B.Month%in%c(7:9)),]
raw <- raw[!(raw$Age..VAGE=="Local"&raw$B.Month%in%c(7:9)),]      ## 1528 locals, 1350 HY, 1126 adults

#bring in sex and convert to age class so this is more like a sex-age class column
# 1=local, 2=juv, 3=male, 4=female
clean[,6]<-NA
clean[clean[,5]%in%1:2,6]<-clean[clean[,5]%in%1:2,5]     

#convert 2 juvenile ages to a single class           ##(SS edit 13 Feb)
#now: 1=juv (both local and HY), 2=male, 3=female   ##SS edit
clean[clean[,6]%in%1:2,6]<-1

### Sex from subsequent encounter means unknown at time of banding (== unknown if not recovered)
### So treat these as unknown and if marked as unknown-sex adult they get deleted (but probably all marked as local or HY)
clean[raw$Sex..VSEX%in%c("Male")&clean[,5]==3,6]<-2
clean[raw$Sex..VSEX%in%c("Female")&clean[,5]==3,6]<-3
# 465 males, 640 females, 2899 unknown

#remove unknown adults for now--only losing 21 individuals if we don't include them
raw<-raw[!(is.na(clean[,6])&clean[,5]==3),]
clean<-clean[!(is.na(clean[,6])&clean[,5]==3),]
# 465 males, 640 females, 2878 unknown

#adding dummy column to use sum function below for marray
clean[,7]<-1
colnames(clean)<-c("bSeason","bYear","rYear","region","age","class","dummy")

########################################################################
#create the marray
########################################################################
Year<-unique(clean$bYear)
Year<-sort(Year)          #SS sorted
NYear<-length(Year)
Season<-unique(clean$bSeason)
NSeason<-length(Season)
Class<-unique(clean$class)
Class<-sort(Class)        #SS sorted
NClass<-length(Class)
Region<-unique(clean$region)
Region<-sort(Region)       #SS sorted
NRegion<-length(Region)

awc<-array(NA,dim=c(NYear,NYear,NSeason,NClass,NRegion),
           dimnames =list(Year, Year, c("spring","not_spring"),
                       c("Juvenile","Adult_Male","Adult_Female"),
                       c("Eastern","Central")))
for (s in 1:NSeason){
  for (cc in 1:NClass){
    for (i in 1:NRegion){
      for (b in 1:NYear){
        for (r in 1:NYear){
                awc[b,r,s,cc,i]<-sum(clean[clean$bYear==Year[b]&clean$rYear==Year[r]&clean$bSeason==Season[s]&clean$class==Class[cc]&clean$region==Region[i],7])
                }}}}}

#take a look at subset of giant marray--basically this is 12 marrays
#essentially 12 matrices total: 2 banding periods * 3 age-sex classes * 2 regions
#organized as 53 banding yrs by 53 recovery yrs by 2 seasons by 3 age classes (1 juv; 2 male; 3 female) by 2 regions

#juvenile m-arrays
awc[1:10,1:10,1,1,1] # spring, juv (locals only), eastern
awc[1:10,1:10,1,1,2] # spring, juv (locals only), central
awc[1:10,1:10,2,1,1] # summer, juv (HY only), eastern
awc[1:10,1:10,2,1,2] # summer, juv (HY only), central 

# adult m-arrays
awc[1:10,1:10,1,2,1] # spring, adult males, eastern
awc[1:10,1:10,1,2,2] # spring, adult males, central
awc[1:10,1:10,2,2,1] # summer, adult males, eastern
awc[1:10,1:10,2,2,2] # summer, adult males, central

awc[1:10,1:10,1,3,1] # spring, adult females, eastern
awc[1:10,1:10,1,3,2] # spring, adult females, central
awc[1:10,1:10,2,3,1] # summer, adult females, eastern
awc[1:10,1:10,2,3,2] # summer, adult females, central

str(awc)
dim(awc)   #53 banding yrs, 53 recovery yrs, 2 banding seasons, 3 sex-age classes, 2 regions
head(awc)

#save(awc, file="AMWO_Marray.rda")

#---------------------------------------------------------------------------
#need to add last column of unrecovered individuals to marray
#---------------------------------------------------------------------------
#bring in bandings file
bands<-read.csv("AMWO bandings.csv")   #43,914 records

#need to summarize bandings according to: banding year, region, class, season

#only use status 3 birds
bands<-subset(bands,Status==3)                #43,351 records (563 excluded)

#only use B.Year from 1963 onwards
bands<-subset(bands,B.Year>=1963)             #40,734 (2617 excluded)

#subset B.Month between 4 and 9 to cover our 2 seasons
bands<-subset(bands,B.Month>=4&B.Month<=9)    #34,251 records (6483 excluded)

## TA added
# remove radio transmitters (meta-analyses suggest survival and harvest effects)
bands<-subset(bands,Add.Info!=89)
bands<-subset(bands,Add.Info!=80)    #SS and TA added this line to get rid of satellite transmitters (3 birds)
bands<-subset(bands,Add.Info!=81)              #32,824 records (1427 excluded)

#bring in B.month, convert to season
clean.bands<-matrix(NA,nrow=length(bands$B.Month),ncol=1)
clean.bands<-data.frame(clean.bands)
clean.bands[bands$B.Month>=4&bands$B.Month<=6,]<-1  
clean.bands[bands$B.Month>=7&bands$B.Month<=9,]<-2      # 19,589 spring (Apr-Jun), 13,238 summer (Jul-Sep)

#Bring in B.year
clean.bands[,2]<-bands$B.Year  

#bring in B region
clean.bands[,3]<-0
clean.bands[bands$B.Flyway==1,3]<-1  ## Eastern region, U.S
clean.bands[bands$B.Flyway%in%2:3,3]<-2  ## Central region, U.S
clean.bands[bands$B.Flyway==6&bands$Region..State %in%c("Quebec","Nova Scotia","New Brunswick","Newfoundland and Labrador and St. Pierre et Miquelon"),3]<-1 ## Add eastern Canada (165)
clean.bands[bands$B.Flyway==6&bands$Region..State %in%c("Ontario","Manitoba"),3]<-2  ## 19 from ONT, added Manitoba to code (no recoveries, but some bandings)
# 13054 in Eastern, 19770 in Central = 32,824

#bring in age
# local = 1, hatch year = 2, adult = 3
#if an error is happening in this section, it's because the accent on Quebec above (line 223) is turning into a weird character.
#Make sure it's the correct accent over the e, then re-run if necessary.
clean.bands[,4]<-NA
clean.bands[bands$Age..VAGE=="After Hatch Year",4]<-3
clean.bands[bands$Age..VAGE=="After Second Year",4]<-3
clean.bands[bands$Age..VAGE=="After Third Year",4]<-3
clean.bands[bands$Age..VAGE=="Second Year",4]<-3
clean.bands[bands$Age..VAGE=="Unknown",4]<-NA     ##delete unknown age at banding
clean.bands[bands$Age..VAGE=="Hatch Year",4]<-2
clean.bands[bands$Age..VAGE=="Local",4]<-1
#remove unknowns
bands<-bands[!is.na(clean.bands[,4]),]
clean.bands<-clean.bands[!is.na(clean.bands[,4]),]      
#32,139 individuals 

# get rid of hatch years in months 4, 5 and 6
clean.bands <- clean.bands[!(bands$Age..VAGE=="Hatch Year"&bands$B.Month%in%c(4:6)),]
bands <- bands[!(bands$Age..VAGE=="Hatch Year"&bands$B.Month%in%c(4:6)),]

## there are also 2 locals banded in month 7
clean.bands <- clean.bands[!(bands$Age..VAGE=="Local"&bands$B.Month%in%c(7:9)),]
bands <- bands[!(bands$Age..VAGE=="Local"&bands$B.Month%in%c(7:9)),]      
#Now 30,846 inds 

#bring in sex and convert to age class so this is more like a sex-age class column
# 1=local, 2=juv, 3=male, 4=female
clean.bands[,5]<-NA
clean.bands[clean.bands[,4]%in%1:2,5]<-clean.bands[clean.bands[,4]%in%1:2,4]     

#convert 2 juvenile ages to a single class           ##(SS edit 13 Feb)
#now: 1=juv (both local and HY), 2=male, 3=female   ##SS edit
clean.bands[clean.bands[,5]%in%1:2,5]<-1

### Sex from subsequent encounter means unknown at time of banding (== unknown if not recovered)
### So treat these as unknown and if marked as unknown-sex adult they get deleted (but probably all marked as local or HY)
clean.bands[bands$Sex..VSEX%in%c("Male")&clean.bands[,4]==3,5]<-2
clean.bands[bands$Sex..VSEX%in%c("Female")&clean.bands[,4]==3,5]<-3

#remove unknown adults for now--only losing 21 individuals if we don't include them
bands<-bands[!(is.na(clean.bands[,5])&clean.bands[,4]==3),]
clean.bands<-clean.bands[!(is.na(clean.bands[,5])&clean.bands[,4]==3),]
# 30176 inds : 6533 females, 6127 males, 17516 juvs

#adding column to use sum function below for marray. Each line of data can include multiple bandings, so need to account
#for that with Count.of.Birds column from data instead of a dummy column of 1's.
clean.bands[,6]<-bands$Count.of.Birds
colnames(clean.bands)<-c("bSeason","bYear","region","age","class","dummy")

#Sorting for the addition to the m-array
Year.bands<-unique(clean.bands$bYear)
Year.bands<-sort(Year.bands)          #SS sorted
NYear.bands<-length(Year.bands)
Season.bands<-unique(clean.bands$bSeason)
NSeason.bands<-length(Season.bands)
Class.bands<-unique(clean.bands$class)
Class.bands<-sort(Class.bands)        #SS sorted
NClass.bands<-length(Class.bands)
Region.bands<-unique(clean.bands$region)
Region.bands<-sort(Region.bands)       #SS sorted
NRegion.bands<-length(Region.bands)

## Create m-array for total number of bandings each year
awc.bands<-array(NA,dim=c(NYear,1,NSeason,NClass,NRegion),
           dimnames =list(Year, "Banded", c("spring","not_spring"),
                          c("Juvenile","Adult_Male","Adult_Female"),
                          c("Eastern","Central")))

for (s in 1:NSeason.bands){
  for (cc in 1:NClass.bands){
    for (i in 1:NRegion.bands){
      for (b in 1:NYear.bands){
          awc.bands[b,,s,cc,i]<-sum(clean.bands[clean.bands$bYear==Year.bands[b]&clean.bands$bSeason==Season.bands[s]&clean.bands$class==Class.bands[cc]&clean.bands$region==Region.bands[i],6])
      }}}}


## Create m-array for total number Not Recovered each year
awc.nonrecov<-array(NA,dim=c(NYear,1,NSeason,NClass,NRegion),
                 dimnames =list(Year, "Not Recovered", c("spring","not_spring"),
                                c("Juvenile","Adult_Male","Adult_Female"),
                                c("Eastern","Central")))

for (s in 1:NSeason.bands){
  for (cc in 1:NClass.bands){
    for (i in 1:NRegion.bands){
      for (b in 1:NYear.bands){
        awc.nonrecov[b,,s,cc,i]<- awc.bands[b,,s,cc,i] - sum(awc[b,,s,cc,i])
}}}}


## Combine awc.nonrecov as final column with awc
marrayAMWO<-array(NA,dim=c(NYear,NYear+1,NSeason,NClass,NRegion),
           dimnames =list(Year, c(Year,"NR"), c("spring","not_spring"),
                          c("Juvenile","Adult_Male","Adult_Female"),
                          c("Eastern","Central")))
relAMWO<-array(NA,dim=c(NYear,NSeason,NClass,NRegion),
               dimnames =list(Year, c("spring","not_spring"),
                              c("Juvenile","Adult_Male","Adult_Female"),
                              c("Eastern","Central")))

for (s in 1:NSeason){
  for (cc in 1:NClass){
    for (i in 1:NRegion){
      for (b in 1:NYear){
        for (r in 1:(NYear+1)){
          if(r <= NYear){
            marrayAMWO[b,r,s,cc,i] <- awc[b,r,s,cc,i]
          }else{
            marrayAMWO[b,r,s,cc,i] <- awc.nonrecov[b,,s,cc,i]
          }
          relAMWO[b,s,cc,i] <- sum(marrayAMWO[b,,s,cc,i])
           }}}}}

#Above is the final version of the m-array including column of total individuals never recovered as final column
#marrayAMWO is 53 by 54 by 2 by 3 by 2 dimensions.

save(marrayAMWO, file="marrayAMWO.rda")
save(relAMWO, file="relAMWO.rda")
dim(marrayAMWO)[]
dim(relAMWO)[]
marrayAMWO[,54,1,1,1]
relAMWO[,1,1,1]
