##Process elephant seal location data (Argos and GPS, if applicable)
##Written by Theresa Keates, last updated August 2022
##Change your directories :)

##Imports "pre_foieGras" data (created by Matlab code "Prep_argos_raw_with_error_ellipses_for_foieGras_with_GPS_TRK.m"), 
##runs state-space model using Ian Jonsen's foieGras, 
##writes output csv, and generates map comparing input and output data for visual QC.
##Needs bathymetry netCDF file to run land filter.

##Current parameters:
##time step = 1 hour
##Some other options listed at end of code

##Input needs: id, date, lc, lon, lat, smaj, smin, eor (for Kalman filter output)
##or: id, date, lc, lon, lat (for Least-Squares model output w/out error ellipses)
##error ellipse for KF input data can have NAs, will be treated as Least-Squares based observation
##if some error ellipses = 0, will not run, remove those points (at the beginning of tracks sometimes - corrected below)

##to install foieGras:
#install.packages("foieGras", 
#                 repos = c("https://cloud.r-project.org",
#                           "https://ianjonsen.r-universe.dev"),
#                 dependencies = "Suggests")


rm(list=ls())
setwd("D:/Dropbox/MATLAB/Projects/Eseal Data Processing - NetCDF/Process Tracking Data/")

library(aniMotum)
library(dplyr)
library(ggplot2)
library(rgeos)
library(tidyverse)
library(stringr)
library(ggspatial)

#data to map
library(rnaturalearth)
library(rnaturalearthdata)
world <- ne_countries(scale = "medium", returnclass = "sf")

#bathymetry data for land filter
library(ncdf4)
bathydata<-nc_open('usgsCeSS111_074f_a9d5_7b24.nc')
bathylats<-ncvar_get(bathydata,"latitude")
bathylons<-ncvar_get(bathydata,"longitude")
bathydepths<-ncvar_get(bathydata,"topo")

setwd("H:/Tracking Diving 2004-2020/All Pre aniMotum/")

#import input data
inputfiles<-list.files(pattern="_pre_aniMotum.csv")

#inputfiles<-list.files(pattern="RawArgos.csv")

inputfiles<-inputfiles[order(inputfiles)] #order by name so it's easy to catch if there are multiple files for one TOPPID (very occasionally two PTTs were on the same seal)


for (i in 1:length(inputfiles)){
  setwd("H:/Tracking Diving 2004-2020/All Pre aniMotum/")
  argosdata<-read.csv(inputfiles[i])
    if (nrow(argosdata)<10){
    next}
  
    trackdata=vector()
    trackdata$id=argosdata$TOPPID
    #issues reading in dates from csv:
    if (is.na(as.numeric(substr(argosdata$Date[1],4,4)))){ #see if there are letters in here. 4th element of the string will be within the letter month if it exists, this will be TRUE if as.numeric gives an NA. Brute force coding right here.
      trackdata$date=as.POSIXct(argosdata$Date,tz="GMT",format='%d-%b-%Y %H:%M:%S') #month as letters
    } else {
      trackdata$date=as.POSIXct(argosdata$Date,tz="GMT",format='%m/%d/%Y %H:%M:%S') #month as numbers
    }
    if (is.na(trackdata$date[1])){
      trackdata$date=as.POSIXct(argosdata$Date,tz="GMT",format='%m/%d/%Y %H:%M')
    }
    if (is.na(trackdata$date[1])){
      trackdata$date=as.POSIXct(argosdata$Date,tz="GMT",format='%Y-%m-%d %H:%M:%S')
    }
    if (is.na(trackdata$date[1])){
      trackdata$date=as.POSIXct(argosdata$Date,tz="GMT",format='%H:%M:%S %d-%b-%Y ') #time before date, month as letters
    }
    trackdata$lc=argosdata$LocationClass
    trackdata$lon=as.numeric(argosdata$Longitude)
    trackdata$lat=as.numeric(argosdata$Latitude)
    trackdata$smaj=as.numeric(argosdata$SemiMajorAxis)
    trackdata$smin=as.numeric(argosdata$SemiMinorAxis)
    trackdata$eor=as.numeric(argosdata$EllipseOrientation)
    trackdata=as.data.frame(trackdata)


    #sometimes first row has zeros for error ellipse; should be missing, not a zero.
    if (!is.nan(trackdata$smaj[1])){
    if (trackdata$smaj[1]==0){
      trackdata$smaj[1]=NaN
      trackdata$smin[1]=NaN
      trackdata$eor[1]=NaN
     
    }
    }
    rm(argosdata)
    
    #There are some very rare occasions where one deployment has multiple PTTs. 
    #Check if there is another file of tracking data matching this PTT:
    if (i<length(inputfiles)){
    nextfile<-inputfiles[i+1]
    if (str_detect(nextfile,as.character(trackdata$id[1]))){
      argosdata<-read.csv(nextfile)
      if (nrow(argosdata)<30){
        next}
      trackdata2=vector()
      trackdata2$id=argosdata$TOPPID
      trackdata2$date=as.POSIXct(argosdata$Date,tz="GMT",format='%m/%d/%Y %H:%M:%S')
      trackdata2$lc=argosdata$LocationClass
      trackdata2$lon=as.numeric(argosdata$Longitude)
      trackdata2$lat=as.numeric(argosdata$Latitude)
      trackdata2$smaj=as.numeric(argosdata$SemiMajorAxis)
      trackdata2$smin=as.numeric(argosdata$SemiMinorAxis)
      trackdata2$eor=as.numeric(argosdata$EllipseOrientation)
      trackdata2=as.data.frame(trackdata)
      
      #sometimes first row has zeros for error ellipse; should be missing, not a zero.
      if (!is.nan(trackdata2$smaj[1])){
        if (trackdata2$smaj[1]==0){
          trackdata2$smaj[1]=NaN
          trackdata2$smin[1]=NaN
          trackdata2$eor[1]=NaN
          
        }
      }
      trackdata<-rbind(trackdata,trackdata2)
      trackdata<-trackdata[order(date),]
      rm(trackdata2)
      i=i+1 #continue with next file
    }
    }
    
     trackdata<-trackdata[which(!is.nan(trackdata$lat)),]

     #Land Filter
     inocean<-vector()
     for (k in 1:nrow(trackdata)){
       blats<-vector()
       blons<-vector()
       bdepths<-vector()
       bdepth<-vector()
       blats<-which(bathylats>=trackdata$lat[k]-0.01 & bathylats<=trackdata$lat[k]+0.01)
       blons<-which(bathylons>=trackdata$lon[k]-0.01 & bathylons<=trackdata$lon[k]+0.01)
       bdepths<-bathydepths[blons,blats]
       bdepth<-mean(bdepths)
       if (is.na(bdepth) & trackdata$lon[k]>-110 & trackdata$lon[k]<150){#in case so far on land I did not even get bathymetry for it
         inocean[k]<-FALSE
       }else if (bdepth<10 | is.na(bdepth)){ #a little generous 10 m elevation and if previous reason for na did not apply
         inocean[k]<-TRUE
       }else{
         inocean[k]<-FALSE
       }
     }
     trackdata<-trackdata[inocean,]
     trackdata$lc[trackdata$lc==""]<-NA
     trackdata<-trackdata[which(!is.na(trackdata$lc)),]
     

     #convert to 0-360 longitude to deal with dateline crossing
     for (x in 1:nrow(trackdata)){
       if (trackdata$lon[x]<0){
         trackdata$lon[x]=trackdata$lon[x]+360
       }}
     
     #specific issues in tracks (visual QC, when issues persisted):
     if (trackdata$id[1]==2004034){
       trackdata<-trackdata[-c(which(trackdata$date>='2005-01-22')),]
     }
     if (trackdata$id[1]==2005017){
       trackdata<-trackdata[-c(which(trackdata$lon<220)),]
     }
     if (trackdata$id[1]==2005035){
       trackdata<-trackdata[-c(which(trackdata$date<'2005-06-26')),]
     }
     if (trackdata$id[1]==2005044){
       trackdata<-trackdata[-c(which(trackdata$date>'2005-10-13')),]
     }  
     if (trackdata$id[1]==2005056){
       trackdata<-trackdata[-c(which(trackdata$lon<230 & trackdata$lat<36)),]
     }
     if (trackdata$id[1]==2006054){
       trackdata<-trackdata[-c(which(trackdata$lon<230 & trackdata$lat<38)),]
     }
     if (trackdata$id[1]==2007042){
       trackdata<-trackdata[-c(which(trackdata$lon<180)),]
     }
     if (trackdata$id[1]==2007043){
       trackdata<-trackdata[-c(which(trackdata$date>'2007-11-15')),]
     }     
     if (trackdata$id[1]==2008047){
       trackdata<-trackdata[-c(which(trackdata$date>'2009-03-06')),]
     }
     if (trackdata$id[1]==2009007){
       trackdata<-trackdata[-c(which(trackdata$date>'2009-03-28')),]
     }
     if (trackdata$id[1]==2010016){
       trackdata<-trackdata[-c(which(trackdata$lat>40 & trackdata$lon<210)),]
     }
     if (trackdata$id[1]==2010026){
       trackdata<-trackdata[-c(which(trackdata$lat>40 & trackdata$lon<221)),]
     }
     if (trackdata$id[1]==2011019){
       trackdata<-trackdata[-c(which(trackdata$lon>240)),]
     }    
     if (trackdata$id[1]==2012010){
  trackdata<-trackdata[-c(which(trackdata$lat>40)),]
     }
     if (trackdata$id[1]==2012017){
       trackdata<-trackdata[-c(which(trackdata$lon<200)),]
     }
     if (trackdata$id[1]==2013010){
       trackdata<-trackdata[-c(which(trackdata$date<'2013-02-14')),]
     }
     if (trackdata$id[1]==2013019){
       trackdata<-trackdata[-c(which(trackdata$lat<35)),]
     }
     if (trackdata$id[1]==2013027){
       trackdata<-trackdata[-c(which(trackdata$lon<200)),]
     }
     if (trackdata$id[1]==2013035){
       trackdata<-trackdata[-c(which(trackdata$lat>46)),]
     }
     if (trackdata$id[1]==2013037){
       trackdata<-trackdata[-c(which(trackdata$date>'2013-12-16')),]
     }
     if (trackdata$id[1]==2013046){
       trackdata<-trackdata[-c(which(trackdata$date<'2013-09-11')),]
     }
     if (trackdata$id[1]==2013048){
       trackdata<-trackdata[-c(which(trackdata$date>'2014-01-16')),]
     }
     if (trackdata$id[1]==2014010){
       trackdata<-trackdata[-c(which(trackdata$lon<220)),]
     }
     if (trackdata$id[1]==2014013){
       trackdata<-trackdata[-c(which(trackdata$lat<35)),]
     }
     if (trackdata$id[1]==2014014){
       trackdata<-trackdata[-c(which(trackdata$lat<40 & trackdata$lon<230)),]
     }
     if (trackdata$id[1]==2014015){
       trackdata<-trackdata[-c(which(trackdata$lon<220 & trackdata$lat<36)),]
     }
     if (trackdata$id[1]==2014018){
       trackdata<-trackdata[-c(which(trackdata$lon<230 & trackdata$lat<35)),]
     }
     if (trackdata$id[1]==2014024){
       trackdata<-trackdata[-c(which(trackdata$lat<36.5)),]
     }  
     if (trackdata$id[1]==2014034){
       trackdata<-trackdata[-c(which(trackdata$date>'2014-10-23')),]
     }     
     if (trackdata$id[1]==2015011){
       trackdata<-trackdata[-c(which(trackdata$lon>229 & trackdata$lat>44)),]
     }   
     if (trackdata$id[1]==2015042){
       trackdata<-trackdata[-c(which(trackdata$date>'2015-12-27')),]
     }  

     if (trackdata$id[1]==2016031){
        trackdata<-trackdata[-c(which(trackdata$date<'2016-07-02')),]
     }  
     if (trackdata$id[1]==2016032){
       trackdata<-trackdata[-c(which(trackdata$date<'2016-07-02')),]
     }  
     if (trackdata$id[1]==2016039){
       trackdata<-trackdata[-c(which(trackdata$date<'2016-07-02')),]
     }  
     if (trackdata$id[1]==2017004){
       trackdata<-trackdata[-c(which(trackdata$lon<215)),]
     }
     if (trackdata$id[1]==2017005){
       trackdata<-trackdata[-c(which(trackdata$lon<210 & trackdata$lat<44)),]
     }
     if (trackdata$id[1]==2019005){
      trackdata<-trackdata[-c(which(trackdata$date>'2019-04-29')),]
     }
     if (trackdata$id[1]==2019027){
       trackdata<-trackdata[-c(which(trackdata$lon>230 & trackdata$lat>50)),]
     }
     if (trackdata$id[1]==2020002){
       trackdata<-trackdata[-c(which(trackdata$date>'2020-04-15')),]
     }
     if (trackdata$id[1]==2020012){
       trackdata<-trackdata[-c(which(trackdata$date>'2020-05-04')),]
     }
     if (trackdata$id[1]==2021013){
       trackdata<-trackdata[-c(which(trackdata$lon<210)),]
     }

     trackdata<-trackdata[!duplicated(trackdata$date),] 
    
    #run state space model - correlated random walk:
    fitc<-aniMotum::fit_ssm(trackdata,
                            model='crw',
                            time.step=3,
                            vmax=3,
                            control = ssm_control(verbose = 0))
    
    output<-grab(fitc,"p",as_sf=FALSE)
   
    setwd("H:/Tracking Diving 2004-2020/aniMotum Output/")

    newfilename=str_sub(as.character(inputfiles[i]),end=-18)
    csv2save <- paste(newfilename,'_aniMotum_crw.csv',sep='')
    write.csv(output,file=csv2save)
    
    figfilename=str_sub(as.character(inputfiles[i]),end=-18)
    figfilename=paste(figfilename,'crw_vs_raw_locs.pdf',sep="_")
    #convert back to -180 longitude for plots
    for (x in 1:nrow(trackdata)){
      if (trackdata$lon[x]>180){
        trackdata$lon[x]=trackdata$lon[x]-360
      }}

    ggplot(data=world)+geom_sf()+coord_sf(xlim=c(-179,-115),ylim=c(25,60),expand=FALSE)+geom_point(data=output,aes(x=lon,y=lat,color=date))+labs(y="Latitude",x="Longitude",title=str_sub(figfilename,end=7))+     geom_point(data=trackdata,aes(x=lon,y=lat),alpha=0.25)
    ggsave(figfilename)
    
    rm(list=c("output","newfilename","csv2save","trackdata","fitc"))
    
}


# ######################################################################
# 
# 
# #ssm model = can run correlated random walk (crw) or simple random walk (rw)
# #time.step = time step in hours
# 
# #other optional parameters:
#   #vmax = max travel rate in m/s
#   #ang = angles of outlier location "spikes"
#   #distlim = lengths of outlier location "spikes"
#   #spdf = turn argosfilter::sdafilter on or off (default = TRUE)
#   #min.dt = minimum allowable time diff btw observations (anything shorter will be ignored)
#   #pf = if TRUE, just prefilter the data, do not fit SMM (default = FALSE)
#   #emf = optionally supplied data.frame of error multiplication factors for Argos location quality classes. Default behaviour is to use the factors supplied in foieGras::emf()
#   #map = a named list of parameters that are to be fixed during estimation
#   #parameters = 
#   #verbose = 0 for no progress report during, 1 for progress bar, 2 for minimizer trace but not progress bar
#   #some others...