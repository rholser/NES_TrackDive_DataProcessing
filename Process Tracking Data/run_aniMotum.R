##Process elephant seal location data (Argos and GPS, if applicable)
##Written by Theresa Keates and Rachel Holser, last updated March 2025
##Change your directories :)

##Imports "pre_aniMotum" data (created by Matlab code "Prep_argos_and_GPS_for_aniMotum.m"), 
##runs state-space model using Ian Jonsen's aniMotum, 
##writes output csv, and generates map comparing input and output data for visual QC.
##Needs bathymetry netCDF file to run land filter.

##Current parameters:
##time step = 1 hour
##Some other options listed at end of code

##Input needs: id, date, lc, lon, lat, smaj, smin, eor (for Kalman filter output)
##or: id, date, lc, lon, lat (for Least-Squares model output w/out error ellipses)
##error ellipse for KF input data can have NAs, will be treated as Least-Squares based observation
##if some error ellipses = 0, will not run, remove those points (at the beginning of tracks sometimes - corrected below)

##to install aniMotum:
# install.packages("aniMotum", 
#                  repos = c("https://cloud.r-project.org",
#                            "https://ianjonsen.r-universe.dev"),
#                  dependencies = TRUE)


rm(list=ls())
setwd("D:/Dropbox/GitHub/NES-DataProcessing-MatFiles/Process Tracking Data/")

library(aniMotum)
library(dplyr)
library(ggplot2)
#library(rgeos)
library(tidyverse)
library(stringr)
library(ggspatial)
library(viridis)

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

#select model parameters:
minrows <- 10
mdl <- 'crw'

################# Define functions used in Main Loop ################################################
### Function to read and preprocess data
read_and_preprocess <- function(file_path, bathylats, bathylons, bathydepths, minrows, mdl) {
  setwd("E:/Tracking Diving 2004-2020/All Pre aniMotum/")
  argosdata <- read.csv(file_path)
  if (nrow(argosdata) < minrows) return(NULL)
  trackdata <- argosdata %>%
    mutate(
      date = case_when(
        # '%H:%M:%S %d-%b-%Y' format
        grepl("^\\d{2}:\\d{2}:\\d{2} \\d{2}-[A-Za-z]{3}-\\d{4}$", Date) ~ as.POSIXct(Date, tz = "GMT", format = '%H:%M:%S %d-%b-%Y'),
        
        # '%m/%d/%Y %H:%M:%S' format
        grepl("^\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2}$", Date) ~ as.POSIXct(Date, tz = "GMT", format = '%m/%d/%Y %H:%M:%S'),
        
        # '%d-%b-%Y %H:%M:%S' format
        grepl("^\\d{2}-[A-Za-z]{3}-\\d{4} \\d{2}:\\d{2}:\\d{2}$", Date) ~ as.POSIXct(Date, tz = "GMT", format = '%d-%b-%Y %H:%M:%S'),
        
        # '%m/%d/%Y %H:%M' format
        grepl("^\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}$", Date) ~ as.POSIXct(Date, tz = "GMT", format = '%m/%d/%Y %H:%M'),
        
        # '%Y-%m-%d %H:%M:%S' format
        grepl("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$", Date) ~ as.POSIXct(Date, tz = "GMT", format = '%Y-%m-%d %H:%M:%S'),
        
        # Default case for unexpected formats
        TRUE ~ NA_POSIXct_
      ),
      id = TOPPID,
      lc = LocationClass,
      lon = as.numeric(Longitude),
      lat = as.numeric(Latitude),
      smaj = as.numeric(SemiMajorAxis),
      smin = as.numeric(SemiMinorAxis),
      eor = as.numeric(EllipseOrientation)
    )%>%
    filter(!(mdl == 'mp' & lc == 'Z')) %>%
    filter(!is.nan(lat))
  trackdata<- trackdata %>%
    distinct(date, .keep_all = TRUE) # Remove duplicated rows based on date
  
  # If first row has 0 elipses, replace with NaN
  trackdata <- trackdata %>%
    mutate(smaj = ifelse(row_number() == 1 & smaj == 0, NaN, smaj),
           smin = ifelse(row_number() == 1 & smin == 0, NaN, smin),
           eor = ifelse(row_number() == 1 & eor == 0, NaN, eor))  
  
  # Land filter
  inocean <- vector()
  for (k in 1:nrow(trackdata)) {
    blats<-vector()
    blons<-vector()
    bdepths<-vector()
    bdepth<-vector()
    blats <- which(bathylats >= trackdata$lat[k] - 0.01 & bathylats <= trackdata$lat[k] + 0.01)
    blons <- which(bathylons >= trackdata$lon[k] - 0.01 & bathylons <= trackdata$lon[k] + 0.01)
    bdepths <- bathydepths[blons, blats]
    bdepth <- mean(bdepths, na.rm = TRUE)
    if (is.na(bdepth) & trackdata$lon[k] > -110 & trackdata$lon[k] < 150) {
      inocean[k] <- FALSE
    } else if (bdepth < 10 | is.na(bdepth)) {
      inocean[k] <- TRUE
    } else {
      inocean[k] <- FALSE
    }
  }
  trackdata<-trackdata[inocean,]
  trackdata$lc[trackdata$lc==""]<-NA
  trackdata<-trackdata[which(!is.na(trackdata$lc)),]
  
 
  trackdata<-trackdata %>%
    mutate(lon = ifelse(lon < 0, lon + 360, lon)) # Convert to 0-360 longitude to deal with dateline crossing
  
  return(trackdata)
}

### Function to apply specific issues filter
apply_specific_issues_filter <- function(trackdata, id) {
  if (id == "2004034") {
    return(trackdata[trackdata$date < as.POSIXct('2005-01-23', tz="GMT"), ])    
  } else if (id == "2005017") {
    return(trackdata[trackdata$lon >= 220, ])
  } else if (id == "2005044") {
    return(trackdata[trackdata$date < as.POSIXct('2005-10-14', tz="GMT"), ])
  } else if (id == "2005056") {
    return(trackdata[!(trackdata$lon<230 & trackdata$lat<36),])
  } else if (id == "2006054") {
    return(trackdata[!(trackdata$lon<230 & trackdata$lat<38), ])
  } else if (id == "2007042") {
    return(trackdata[trackdata$lon>=180, ])
  } else if (id == "2008044") { # still did not fix interpolation over land at end of track
    return(trackdata[trackdata$lon < 238, ])
  } else if (id == "2008047") {
    return(trackdata[trackdata$date < as.POSIXct('2009-03-07', tz="GMT"), ])
  } else if (id == "2009007") {
    #return(trackdata[trackdata$date <= as.POSIXct('2009-03-28', tz="GMT"), ])
    return(trackdata[trackdata$lon>210, ])    
  } else if (id == "2010013") {
    return(trackdata[!(trackdata$lon<220), ])
  } else if (id == "2010016") {
    return(trackdata[!(trackdata$lat>40 & trackdata$lon<210), ])
  } else if (id == "2010026") {
    return(trackdata[!(trackdata$lat>40 & trackdata$lon<221), ])
  } else if (id == "2011019") {
    return(trackdata[trackdata$lon <= 240, ])
  } else if (id == "2012010") {
    return(trackdata[trackdata$lat<= 40, ])
  } else if (id == "2012017") {
    return(trackdata[trackdata$lon >= 200, ])
  } else if (id == "2013019") {
    return(trackdata[trackdata$lat >= 35, ])
  } else if (id == "2013027") {
    return(trackdata[trackdata$lon >= 200, ])
  } else if (id == "2013026") {
    return(trackdata[trackdata$date < as.POSIXct('2013-12-25 18:00:00', tz="GMT"), ])
  } else if (id == "2013035") {
    return(trackdata[trackdata$lat <= 46, ])
  } else if (id == "2013048") {
    return(trackdata[trackdata$date <= as.POSIXct('2014-01-16', tz="GMT"), ])
  } else if (id == "2014010") {
    return(trackdata[trackdata$lon >= 220, ])
  } else if (id == "2014013") {
    return(trackdata[trackdata$lat >= 35, ])
  } else if (id == "2014014") {
    return(trackdata[!(trackdata$lat<40 & trackdata$lon<230), ])
  } else if (id == "2014015") {
    return(trackdata[!(trackdata$lon<220 & trackdata$lat<36), ])
  } else if (id == "2014018") {
    return(trackdata[!(trackdata$lon<230 & trackdata$lat<35), ])
  } else if (id == "2014024") {
    return(trackdata[trackdata$lat >= 36.5, ])
  } else if (id == "2015011") {
    return(trackdata[!(trackdata$lon>229 & trackdata$lat>44), ])
  } else if (id == "2015042") {
    return(trackdata[trackdata$date <= as.POSIXct('2015-12-28', tz="GMT"), ])
  } else if (id == "2017004") {
    return(trackdata[trackdata$lon >= 215, ])
  } else if (id == "2017005") {
    return(trackdata[!(trackdata$lon<210 & trackdata$lat<44), ])
  } else if (id == "2019027") {
    return(trackdata[!(trackdata$lon>230 & trackdata$lat>50), ])
  } else if (id == "2021013") {
    return(trackdata[trackdata$lon >= 210, ])
  } else {
    return(trackdata)
  }
}


### Function to run state space model
run_ssm <- function(trackdata,mdl,mapfilename) {
  fitc <- aniMotum::fit_ssm(trackdata,
                            model = mdl,
                            time.step = 3,
                            vmax = 3,
                            control = ssm_control(verbose = 0))
  output <- grab(fitc, "p", as_sf = FALSE, normalise = TRUE)
  return(output)
}

### Function to create plot
create_plot <- function(world, output, trackdata, figfilename, mapfilename, toppid) {
  # Convert back to -180 to 180 longitude for plots
  trackdata$lon <- (trackdata$lon + 180) %% 360 - 180
  
  plot <- ggplot(data = world) +
    geom_sf() +
    coord_sf(xlim = c(-179, -115), ylim = c(25, 60), expand = FALSE) +
    geom_point(data = output, aes(x = lon, y = lat, color = date)) +
    geom_point(data = trackdata, aes(x = lon, y = lat), alpha = 0.25) +
    labs(y = "Latitude", x = "Longitude", title = toppid) +
    theme(legend.position = "none")
  ggsave(figfilename)
  
}

################################ MAIN LOOP ###################################################
setwd("E:/Tracking Diving 2004-2020/All Pre aniMotum/")

#import input data
inputfiles<-list.files(pattern="_pre_aniMotum.csv")
#order by name so it's easy to catch if there are multiple files for one TOPPID (very occasionally two PTTs were on the same seal)
inputfiles<-inputfiles[order(inputfiles)] 
#file_path <- inputfiles[216]

for (file_path in inputfiles) {
  trackdata <- read_and_preprocess(file_path, bathylats, bathylons, bathydepths, minrows, mdl)
  toppid<-str_sub(file_path,end=7)
  if (is.null(trackdata)) next
  trackdata <- apply_specific_issues_filter(trackdata, trackdata$id[1])
  trackdata <- trackdata[!duplicated(trackdata$date), ]
  tryCatch({
    output <- run_ssm(trackdata,mdl,mapfilename)
    #convert date to character retaining all HH:MM:SS. Otherwise, will lose the time stamp on midnight datetimes
    output$date<-as.character(format(output$date))
    
    csv2save <- paste('E:/Tracking Diving 2004-2020/aniMotum Output/',str_sub(as.character(file_path), end = -18), '_aniMotum_crw.csv', sep = '')
    write.csv(output,file=csv2save)

    figfilename <- paste('E:/Tracking Diving 2004-2020/aniMotum Output/',str_sub(as.character(file_path), end = -18), '_crw_vs_raw_locs.pdf', sep = '')
    create_plot(world, output, trackdata, figfilename, mapfilename, toppid)
  }, error = function(e) {
  }, warning = function(w) {
  })
  rm(list = c("output", "trackdata"))
}

### The following TOPPIDs throw a warning message from run_smm which aborts the tryCatch loop: 2009041, 2010027, 2015038, and 2015042.
### These tracks will run but need to be done manually as the code currently exists.
### Others that did not run for ABF on 5-Mar-2025: 2009042 (has exactly 10 rows of data in trackdata)

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