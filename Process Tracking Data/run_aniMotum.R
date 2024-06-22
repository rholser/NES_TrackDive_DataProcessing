##Process elephant seal location data (Argos and GPS, if applicable)
##Written by Theresa Keates, last updated by Rachel Holser June 2024
##Change your directories :)

##Imports "pre_aniMotum" data (created by Matlab code "prep_argos_and_gps_for_aniMotum.m"), 
##runs state-space model using Ian Jonsen's aniMotum, 
##writes output csv, and generates map comparing input and output data for visual QC.
##Needs bathymetry netCDF file to run land filter.

##Current parameters:
##time step = 3 hours
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
setwd("D:/Dropbox/MATLAB/Projects/Eseal NetCDF/Process Tracking Data/")

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
minrows <- 100
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
        !is.na(as.numeric(substr(Date, 4, 4))) ~ as.POSIXct(Date, tz = "GMT", format = '%m/%d/%Y %H:%M:%S'),
        TRUE ~ as.POSIXct(Date, tz = "GMT", format = '%d-%b-%Y %H:%M:%S'),
        is.na(date) ~ as.POSIXct(Date, tz = "GMT", format = '%m/%d/%Y %H:%M'),
        is.na(date) ~ as.POSIXct(Date, tz = "GMT", format = '%Y-%m-%d %H:%M:%S'),
        is.na(date) ~ as.POSIXct(Date, tz = "GMT", format = '%H:%M:%S %d-%b-%Y ')
      ),
      id = TOPPID,
      lc = LocationClass,
      lon = as.numeric(Longitude),
      lat = as.numeric(Latitude),
      smaj = as.numeric(SemiMajorAxis),
      smin = as.numeric(SemiMinorAxis),
      eor = as.numeric(EllipseOrientation)
    ) %>%
    filter(!(mdl == 'mp' & lc == 'Z')) %>%
    filter(!is.nan(lat)) %>%
    mutate(lon = ifelse(lon < 0, lon + 360, lon)) %>% # Convert to 0-360 longitude to deal with dateline crossing
    distinct(date, .keep_all = TRUE) # Remove duplicated rows based on date
  
  # If first row has 0 elipses, replace with NaN
  trackdata <- trackdata %>%
    mutate(smaj = ifelse(row_number() == 1 & smaj == 0, NaN, smaj),
           smin = ifelse(row_number() == 1 & smin == 0, NaN, smin),
           eor = ifelse(row_number() == 1 & eor == 0, NaN, eor))  
  
  # Land filter
  inocean <- vector()
  for (k in 1:nrow(trackdata)) {
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
  trackdata <- trackdata %>%
    filter(inocean) %>% #keep only data in ocean
    filter(lc != "") #remove rows with no location class

  return(trackdata)
}

### Function to apply specific issues filter
apply_specific_issues_filter <- function(trackdata, id) {
  if (id == "2004034") {
    return(trackdata[trackdata$date < '2005-01-22', ])
  } else if (id == "2005017") {
    return(trackdata[trackdata$lon >= 220, ])
  } else if (id == "2005035") {
    return(trackdata[trackdata$date >='2005-06-26', ])
  } else if (id == "2005044") {
    return(trackdata[trackdata$date <='2005-10-13', ])
  } else if (id == "2005056") {
    return(trackdata[!(trackdata$lon<230 & trackdata$lat<36),])
  } else if (id == "2006054") {
    return(trackdata[!(trackdata$lon<230 & trackdata$lat<38), ])
  } else if (id == "2007042") {
    return(trackdata[trackdata$lon>=180, ])
  } else if (id == "2007043") {
    return(trackdata[trackdata$date <= '2007-11-15', ])
  } else if (id == "2008047") {
    return(trackdata[trackdata$date <= '2009-03-06', ])
  } else if (id == "2009007") {
    return(trackdata[trackdata$date <= '2009-03-28', ])
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
  } else if (id == "2013010") {
    return(trackdata[trackdata$date >= '2013-02-14', ])
  } else if (id == "2013019") {
    return(trackdata[trackdata$lat >= 35, ])
  } else if (id == "2013027") {
    return(trackdata[trackdata$lon >= 200, ])
  } else if (id == "2013035") {
    return(trackdata[trackdata$lat <= 46, ])
  } else if (id == "2013037") {
    return(trackdata[trackdata$date <= '2013-12-16', ])
  } else if (id == "2013046") {
    return(trackdata[trackdata$date >= '2013-09-11', ])
  } else if (id == "2013048") {
    return(trackdata[trackdata$date <= '2014-01-16', ])
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
  } else if (id == "2014034") {
    return(trackdata[trackdata$date <= '2014-10-23', ])
  } else if (id == "2015011") {
    return(trackdata[!(trackdata$lon>229 & trackdata$lat>44), ])
  } else if (id == "2015042") {
    return(trackdata[trackdata$date <= '2015-12-27', ])
  } else if (id == "2016031") {
    return(trackdata[trackdata$date >= '2016-07-02', ])
  } else if (id == "2016032") {
    return(trackdata[trackdata$date >= '2016-07-02', ])
  } else if (id == "2016039") {
    return(trackdata[trackdata$date >= '2016-07-02', ])
  } else if (id == "2017004") {
    return(trackdata[trackdata$lon >= 215, ])
  } else if (id == "2017005") {
    return(trackdata[!(trackdata$lon<210 & trackdata$lat<44), ])
  } else if (id == "2019005") {
    return(trackdata[trackdata$date <= '2019-04-29', ])
  } else if (id == "2019027") {
    return(trackdata[!(trackdata$lon>230 & trackdata$lat>50), ])
  } else if (id == "2020002") {
    return(trackdata[trackdata$date <= '2020-04-15', ])
  } else if (id == "2020012") {
    return(trackdata[trackdata$date <= '2020-05-04', ])
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
create_plot <- function(world, output, trackdata, figfilename) {
  # Convert back to -180 to 180 longitude for plots
  trackdata$lon <- (trackdata$lon + 180) %% 360 - 180
  
  plot <- ggplot(data = world) +
    geom_sf() +
    coord_sf(xlim = c(-179, -115), ylim = c(25, 60), expand = FALSE) +
    geom_point(data = output, aes(x = lon, y = lat, color = date)) +
    geom_point(data = trackdata, aes(x = lon, y = lat), alpha = 0.25) +
    labs(y = "Latitude", x = "Longitude", title = str_sub(figfilename, end = 7))
  ggsave(figfilename)
}

################################ MAIN LOOP ###################################################
setwd("E:/Tracking Diving 2004-2020/All Pre aniMotum/")

#import input data
inputfiles<-list.files(pattern="_pre_aniMotum.csv")
#order by name so it's easy to catch if there are multiple files for one TOPPID (very occasionally two PTTs were on the same seal)
inputfiles<-inputfiles[order(inputfiles)] 


for (file_path in inputfiles) {
  trackdata <- read_and_preprocess(file_path, bathylats, bathylons, bathydepths, minrows, mdl)
  if (is.null(trackdata)) next
  trackdata <- apply_specific_issues_filter(trackdata, trackdata$id[1])
  trackdata <- trackdata[!duplicated(trackdata$date), ]
  tryCatch({
    output <- run_ssm(trackdata,mdl,mapfilename)
    figfilename <- paste('E:/Tracking Diving 2004-2020/aniMotum Output/',str_sub(as.character(file_path), end = -18), '_crw_vs_raw_locs.pdf', sep = '')
    create_plot(world, output, trackdata, figfilename)
        #convert date format to retain 00:00:00 in output csv
    output$date<-format(output$date)
    csv2save <- paste('E:/Tracking Diving 2004-2020/aniMotum Output/',str_sub(as.character(file_path), end = -18), '_aniMotum_crw.csv', sep = '')
    write.csv(output,file=csv2save)
  }, error = function(e) {
  }, warning = function(w) {
  })
  rm(list = c("output", "trackdata"))
}

# ######################################################################
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