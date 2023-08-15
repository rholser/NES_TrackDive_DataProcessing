# Eseal NetCDF

This repository contains the code used to process and quality control northern elephant seal diving and tracking data, combine processed tracks and dive statistics, and output the data for each instrument deployment into a netCDF (.nc) file. The code is built-to-purpose workflow for processing this particular data set. It could work with other species and data types but will likely require some modification, particularly regarding the parameters used to complete the zero-offset correction.

The script **DataProcessing.m** provides the primary workflow, with each processing step laid out in order, including intermediate metadata compilation steps required to move forward.

## Getting Started
*******
Before processing can begin, key metadata need to be compiled and some tags will create outputs that must be decoded by the manufacturers. We used a unique deployment identifier (TOPPID) developed for the TOPP project 51 to link animal and instrument data throughout our workflow. This ID is the start of the name of each data file in every step, and each netCDF output file. The TOPPID is a seven-digit number, for example, 2004001, where the first two digits designate the species (20 is northern elephant seal), digits 3-4 indicate the year (04 is 2004), and digits 5-7 are the deployment serial number (001 is the first deployment for a given year and species)

### MetaData

#### startstop.csv
This file contains the metadata for the deployment: TOPPID, trip (or season), and the date, time (UTC), and location (decimal latitude, decimal longitude, and 4-letter location code) of animal departure and arrival from the beach. Departure and arrival date/time are determined using either TDR data, PTT transmission, or visual observation (in order from most--> least accurate). This information is used to correctly trim the tracking and diving data to the length of the trip, which is particularly important if instruments were on the animal for extended periods before or after time at sea. Startstop also includes animal metadata: SealID, BirthYear, Sex, AgeClass, and and additional Comments.

#### tagmetadata.csv

This file contains information about the instruments deployed on each animal, again with TOPPID at the primary index.  If processing multiple TDR records for a single deployment, having tagmetadata appropriately filled out will be critical - the tag listed as TDR1 will be given highest priority if more than one record is present, then TDR2, then TDR3.  The user 
needs to decide which record to prioritize and populate this spreadsheet appropriately.

## Encountering Problems?
*******
If code is not working as expected, please post an issue [here] (https://github.com/rholser/NES_TrackDive_DataProcessing/issues). Please provide detail about the issue - what species and instrument type are you trying to work with, and what step of the process is not working.

## Acknowledgements
*******
The data collection and processing associated with this repository was supported by numerous funding partners, including:

* US Office of Naval Research (N00014-18-1-2822)

* US National Science Foundation (1644256)

* Alfred P. Sloan Foundation

* Gordon and Betty Moore Foundation

* David and Lucile Packard Foundation

* US DoD Strategic Environment Research and Development Program (RC20-C2-1284)

* Japan Society for the Promotion of Science
