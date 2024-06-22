%Compiles northern elephant seal tracking and diving data into netCDF files.
%
%Requires filename indexes for each data type to be compiled and uses
%TOPPID 
%
% V1.1
% Created by: Rachel Holser (rholser@ucsc.edu)
% Created on: 18-Aug-2022
%
% Modified: 31-Oct-2022
% Removed Curated Subsampled TDR data
%
% V2.1
% Created by: Rachel Holser
% Created on: 16-Nov-2022
%
% Creates netCDF files for each animal's processed data. 
%
% V.2.2
% 04-Dec-2022 - Changed variable naming to remove redundant identifiers
% 05-Jan-2023 - fixed putAtt and putVar command code
%               Removed Raw and Curated parent groups - only one level of organization now
% 06-Jan-2023 - Additions and adjustments to global attributes
% 17-Mar-2023 - Additions and adjustments to global attributes
% 19-Jul-2023 - Split Level 1/2 and Level 3 file generation into separate scripts; added metadata to
%               global attributes section
% 05-Aug-2023 - Change _SUB to _8S and duplicate 8second full-res data to
%               _8S structures.
% 06-Aug-2023 - Added global attriubute
% 14-Aug-2023 - Modified global attributes
% 02-Jun-2024 - Changed from using "string" to "cellstr" for converting Date from TDRs (unexplained
%               error with 2015018 that this change resolved).

clear
load('MetaData.mat');
folder=uigetdir('C:\','File Output Folder');

tic
for i=1:size(TagMetaDataAll,1)
    
    load('All_Filenames.mat');

    TOPPID=TagMetaDataAll.TOPPID(i)

    %find indices for current deployment in other metadata structures
    j=find(MetaDataAll.TOPPID==TOPPID);
    
    %Set netCDF format
    oldFormat = netcdf.setDefaultFormat('NC_FORMAT_NETCDF4');
   
%% Create level 3 netCDF file, groups, and global attributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %Define filename and set to overwrite pre-existing files
    filename=[folder '\' num2str(TOPPID) '_TrackTDR_Processed.nc'];
    ncid=netcdf.create(filename,'CLOBBER');

    %Create Data Groups
    TDR1GrpID=netcdf.defGrp(ncid,'TDR1');
    TDR1SubGrpID=netcdf.defGrp(ncid,'TDR1_8S');
    TDR2GrpID=netcdf.defGrp(ncid,'TDR2');
    TDR2SubGrpID=netcdf.defGrp(ncid,'TDR2_8S');
    TDR3GrpID=netcdf.defGrp(ncid,'TDR3');
    TDR3SubGrpID=netcdf.defGrp(ncid,'TDR3_8S');
    AniMotumGrpID=netcdf.defGrp(ncid,'TRACK');

    %Global Attributes
    %%%%% Creation/versions/permissions
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  'File_Creation_Date',string(datetime("now")));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "File_MATLAB_Version", version);
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "File_R_Version", '4.2.1');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "File_aniMotum_Version", '1.1-04');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "File_IKNOS_DA-ZOC_Version", '2.3/1.2');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "File_Contents", ...
        ['This file contains processed biologging data from one deployment (single individual,' ...
        'single trip). Both tracking data (processed with aniMotum) and dive statistics' ...
        '(processed with custom code) are provided if available. Dive statistics from the ' ...
        'native sampling rate of the instrument (e.g. TDR1) and at 8 second (or 0.125 Hz) sampling ' ...
        'intervals (TDR1_8S) are provided. For additional processing details please see the ' ...
        'associated paper (Costa et al., 2023).' ...
        'Raw data are also available at https://doi.org/10.7291/D10D61']);
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_Owner", 'Daniel Costa');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_Public",...
        ['Yes: data can be used freely as long as data owner is properly cited. We strongly ' ...
        'recommend reaching out to the data owner or another of the coauthors ' ...
        '(D.Crocker, R.Holser, P.Robinson) for additional information about the study system. ' ...
        'Offers of coauthorship would be appreciated, especially given the unique natural history ' ...
        'of this organism and the considerable effort required to collect these data.']);
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Citation_Paper", ['Costa, D.P., Holser, R.R., et al. (2024), '...
        'Two Decades of Three-Dimensional Movement Data from Adult Female Northern Elephant Seals. Scientific Data.']);
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Citation_Paper_DOI", '');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Citation_Dataset", ['Costa, D.P., Holser, R.R., et al. (2024), ' ...
        'Northern Elephant Seal Tracking and Diving Data - Processed, Dryad, Dataset, https://doi.org/10.7291/D18D7W']);
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Citation_Dataset_DOI", '10.7291/D18D7W');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_Type", 'Tracking and diving time-series data');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_Assembly_By", 'UCSC/Rachel Holser');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_Timezone", 'UTC');

    %%%%% Animal MetaData    
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Animal_ID", string(MetaDataAll.FieldID(j)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Animal_Species", 'Mirounga angustirostris');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Animal_Species_CommonName", 'northern elephant seal');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Animal_Sex", string(MetaDataAll.Sex(j)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Animal_AgeClass", string(MetaDataAll.AgeClass(j)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Animal_BirthYear", MetaDataAll.BirthYear(j));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Animal_HadPup", MetaDataAll.HadPup(j));

    %Create list of TOPP IDs for other deployments on same animal
    rows=find(strcmp(MetaDataAll.FieldID(j),MetaDataAll.FieldID));
    AllDeployments=strjoin(string(MetaDataAll.TOPPID(rows,1)));
    clear rows
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Animal_OtherDeployments", AllDeployments);

    %%%%% Deployment MetaData
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_ID",TOPPID);
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Year", year(MetaDataAll.DepartDate(j)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Trip", string(MetaDataAll.Season(j)));
    if isnat(MetaDataAll.ArriveDate(j))
        netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_InstrumentsRecovered?", 'N');
    else
        netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_InstrumentsRecovered?", 'Y');
    end
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Manipulation?", string(MetaDataAll.Manipulation(j)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_ManipulationType", string(MetaDataAll.ManipulationType(j)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Departure_Location", string(MetaDataAll.DepartLoc(j)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Departure_Lat", MetaDataAll.DepartLat(j));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Departure_Lon", MetaDataAll.DepartLon(j));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Departure_Datetime", string(MetaDataAll.DepartDate(j)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Arrival_Location", string(MetaDataAll.ArriveLoc(j)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Arrival_Lat", MetaDataAll.ArriveLat(j));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Arrival_Lon", MetaDataAll.ArriveLon(j));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Deployment_Arrival_Datetime", string(MetaDataAll.ArriveDate(j))); 
    
    %%%%%Data Quality
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_Track_QCFlag",TagMetaDataAll.SatTagQC(i));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_TDR1_QCFlag",TagMetaDataAll.TDR1QC(i));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_TDR2_QCFlag",TagMetaDataAll.TDR2QC(i));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_TDR3_QCFlag",TagMetaDataAll.TDR3QC(i));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_TDR1_SamplingFrequency_Hz", 1/(60/TagMetaDataAll.TDR1_Freq(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_TDR1_DepthResolution_m",TagMetaDataAll.TDR1_Res(i));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_TDR2_SamplingFrequency_Hz", 1/(60/TagMetaDataAll.TDR2_Freq(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_TDR2_DepthResolution_m",TagMetaDataAll.TDR2_Res(i));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_TDR3_SamplingFrequency_Hz", 1/(60/TagMetaDataAll.TDR3_Freq(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Data_TDR3_DepthResolution_m",TagMetaDataAll.TDR3_Res(i));

    %%%%%Instrument MetaData
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_SatTag_Manufacturer", string(TagMetaDataAll.SatTagManufacturer(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_SatTag_Model", string(TagMetaDataAll.SatTagType(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_SatTag_ID", string(TagMetaDataAll.SatTagID(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_PTT", TagMetaDataAll.SatTagPTT(i));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_SatTag_Comments", TagMetaDataAll.SatTagComment(i));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR1_Manufacturer", string(TagMetaDataAll.TDR1Manufacturer(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR1_Model", string(TagMetaDataAll.TDR1Type(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR1_ID", string(TagMetaDataAll.TDR1ID(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR1_Comments", string(TagMetaDataAll.TDR1Comments(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR2_Manufacturer", string(TagMetaDataAll.TDR2Manufacturer(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR2_Model", string(TagMetaDataAll.TDR2Type(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR2_ID", string(TagMetaDataAll.TDR2ID(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR2_Comments", string(TagMetaDataAll.TDR2Comments(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR3_Manufacturer", string(TagMetaDataAll.TDR3Manufacturer(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR3_Model", string(TagMetaDataAll.TDR3Type(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR3_ID", string(TagMetaDataAll.TDR3ID(i)));
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Tags_TDR3_Comments", string(TagMetaDataAll.TDR3Comment(i)));

%% Primary Variables

    % TDR1 DiveStat
    %load DiveStat file
    try
        data=readtable(strcat(TDRDiveStatFiles.folder(TDRDiveStatFiles.TOPPID==MetaDataAll.TOPPID(j)),...
        '\',strtok(TDRDiveStatFiles.filename(TDRDiveStatFiles.TOPPID==MetaDataAll.TOPPID(j)),'.'),'_QC.csv'));
        data.Time=datetime(data.JulDate,"ConvertFrom","datenum");
    end
    %Create a 1-D variable (length of divestat x 1) for each column of the
    %DiveStat file and populate each from the loaded file
    netcdf.reDef(ncid);
    if exist('data','var')==1
        TDR1dimid=netcdf.defDim(TDR1GrpID,'NumDives',size(data,1));
    else
        TDR1dimid=netcdf.defDim(TDR1GrpID,'NumDives',0);
    end

    TDR1Date=netcdf.defVar(TDR1GrpID,'DATE',"NC_STRING",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1Date,"Description","Date and time at of the start of the dive")
    netcdf.putAtt(TDR1GrpID,TDR1Date,'Time Zone','UTC');
    TDR1Depth=netcdf.defVar(TDR1GrpID,'MAXDEPTH',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1Depth,'Description','Maximum depth recorded during dive');
    netcdf.putAtt(TDR1GrpID,TDR1Depth,'Units','meters');
    TDR1Dur=netcdf.defVar(TDR1GrpID,'DURATION',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1Dur,'Description','Total duration of the dive');
    netcdf.putAtt(TDR1GrpID,TDR1Dur,'Units','seconds');
    TDR1DTime=netcdf.defVar(TDR1GrpID,'DESC_TIME',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1DTime,'Description','Time spent in descent phase of dive');
    netcdf.putAtt(TDR1GrpID,TDR1DTime,'Units','seconds');
    TDR1BTime=netcdf.defVar(TDR1GrpID,'BOTT_TIME',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1BTime,'Description','Time spent in bottom phase of dive');
    netcdf.putAtt(TDR1GrpID,TDR1BTime,'Units','seconds');
    TDR1ATime=netcdf.defVar(TDR1GrpID,'ASC_TIME',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1ATime,'Description','Time spent in ascent phase of dive');
    netcdf.putAtt(TDR1GrpID,TDR1ATime,'Units','seconds');
    TDR1DRate=netcdf.defVar(TDR1GrpID,'DESC_RATE',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1DRate,'Description','Average rate of descent');
    netcdf.putAtt(TDR1GrpID,TDR1DRate,'Units','meters per second');
    TDR1ARate=netcdf.defVar(TDR1GrpID,'ASC_RATE',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1ARate,'Description','Average rate of ascent');
    netcdf.putAtt(TDR1GrpID,TDR1ARate,'Units','meters per second');
    TDR1PDI=netcdf.defVar(TDR1GrpID,'PDI',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1PDI,"Description","Post-Dive Interval (surface time after the dive)");
    netcdf.putAtt(TDR1GrpID,TDR1PDI,'Units','seconds');
    TDR1DWigD=netcdf.defVar(TDR1GrpID,'WIGGLES_DESC',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1DWigD,'Description',"Number of vertical inflections detected during descent" + ...
        " phase");
    netcdf.putAtt(TDR1GrpID,TDR1DWigD,'Units',"Count");
    TDR1DWigB=netcdf.defVar(TDR1GrpID,'WIGGLES_BOTT',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1DWigB,'Description',"Number of vertical inflections detected during bottom" + ...
        " phase");
    netcdf.putAtt(TDR1GrpID,TDR1DWigB,'Units',"Count");
    TDR1DWigA=netcdf.defVar(TDR1GrpID,'WIGGLES_ASC',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1DWigA,'Description',"Number of vertical inflections detected during ascent" + ...
        " phase");
    netcdf.putAtt(TDR1GrpID,TDR1DWigA,'Units',"Count");
    TDR1TotVertDist=netcdf.defVar(TDR1GrpID,'TOT_VERT_DIST_BOTT',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1TotVertDist,"Description","Sum of all of the depth changes during the" + ...
        " bottom phase of the dive");
    netcdf.putAtt(TDR1GrpID,TDR1TotVertDist,"Units","meters");
    TDR1BottRng=netcdf.defVar(TDR1GrpID,'BOTT_RANGE',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1BottRng,"Description","Difference between max and min depth of the bottom phase");
    netcdf.putAtt(TDR1GrpID,TDR1BottRng,"Units","meters");
    TDR1Eff=netcdf.defVar(TDR1GrpID,'EFFICIENCY',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1Eff,"Description","Ratio of bottom time to dive cycle (Duration + PDI)")
    netcdf.putAtt(TDR1GrpID,TDR1Eff,"Units","")
    TDR1IDZ=netcdf.defVar(TDR1GrpID,'IDZ',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1IDZ,"Description","Intra-Depth Zone: a binary (0,1) indicator of whether" + ...
        " the max depth of the dive is within 20% of the max depth of the previous dive (see Tremblay" + ...
        " & Cherel, 2000)")
    netcdf.putAtt(TDR1GrpID,TDR1IDZ,"Units","")
    TDR1SolarEl=netcdf.defVar(TDR1GrpID,'SOLAR_EL',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1SolarEl,"Description","Angle of the sun relative to the horizon line" + ...
        " (-90\circ - 90 \circ) calculated from lat, lon, date, and time.");
    netcdf.putAtt(TDR1GrpID,TDR1SolarEl,"Units","\circ");
    TDR1Lat=netcdf.defVar(TDR1GrpID,'LAT',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1Lat,"Description","Decimal latitude at the start of the dive")
    TDR1Lon=netcdf.defVar(TDR1GrpID,'LON',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1Lon,"Description","Decimal longitude at the start of the dive")
    TDR1LatSE=netcdf.defVar(TDR1GrpID,'LAT_SE_KM',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1LatSE,"Description","Latitude error")
    netcdf.putAtt(TDR1GrpID,TDR1LatSE,"Units","km")
    TDR1LonSE=netcdf.defVar(TDR1GrpID,'LON_SE_KM',"NC_DOUBLE",TDR1dimid);
    netcdf.putAtt(TDR1GrpID,TDR1LonSE,"Description","Longitude error")
    netcdf.putAtt(TDR1GrpID,TDR1LonSE,"Units","km")
    TDR1Year=netcdf.defVar(TDR1GrpID,'YEAR',"NC_DOUBLE",TDR1dimid);
    TDR1Month=netcdf.defVar(TDR1GrpID,'MONTH',"NC_DOUBLE",TDR1dimid);
    TDR1Day=netcdf.defVar(TDR1GrpID,'DAY',"NC_DOUBLE",TDR1dimid);
    TDR1Hour=netcdf.defVar(TDR1GrpID,'HOUR',"NC_DOUBLE",TDR1dimid);
    TDR1Min=netcdf.defVar(TDR1GrpID,'MIN',"NC_DOUBLE",TDR1dimid);
    TDR1Sec=netcdf.defVar(TDR1GrpID,'SEC',"NC_DOUBLE",TDR1dimid);
    netcdf.endDef(TDR1GrpID);

    if exist('data','var')==1
        netcdf.putVar(TDR1GrpID,TDR1Date,cellstr(data.Time));
        netcdf.putVar(TDR1GrpID,TDR1Depth,data.Maxdepth);
        netcdf.putVar(TDR1GrpID,TDR1Dur,data.Dduration);
        netcdf.putVar(TDR1GrpID,TDR1DTime,data.DescTime);
        netcdf.putVar(TDR1GrpID,TDR1BTime,data.Botttime);
        netcdf.putVar(TDR1GrpID,TDR1ATime,data.AscTime);
        netcdf.putVar(TDR1GrpID,TDR1DRate,data.DescRate);
        netcdf.putVar(TDR1GrpID,TDR1ARate,data.AscRate);
        netcdf.putVar(TDR1GrpID,TDR1PDI,data.PDI);
        netcdf.putVar(TDR1GrpID,TDR1DWigD,data.DWigglesDesc);
        netcdf.putVar(TDR1GrpID,TDR1DWigB,data.DWigglesBott);
        netcdf.putVar(TDR1GrpID,TDR1DWigA,data.DWigglesAsc);
        netcdf.putVar(TDR1GrpID,TDR1TotVertDist,data.TotVertDistBot);
        netcdf.putVar(TDR1GrpID,TDR1BottRng,data.BottRange);
        netcdf.putVar(TDR1GrpID,TDR1IDZ,data.IDZ);
        netcdf.putVar(TDR1GrpID,TDR1SolarEl,data.SolarEl);
        netcdf.putVar(TDR1GrpID,TDR1Lat,data.Lat);
        netcdf.putVar(TDR1GrpID,TDR1Lon,data.Lon);
        netcdf.putVar(TDR1GrpID,TDR1LatSE,data.Lat);
        netcdf.putVar(TDR1GrpID,TDR1LonSE,data.Lat);
        netcdf.putVar(TDR1GrpID,TDR1Year,data.Year);
        netcdf.putVar(TDR1GrpID,TDR1Month,data.Month);
        netcdf.putVar(TDR1GrpID,TDR1Day,data.Day);
        netcdf.putVar(TDR1GrpID,TDR1Hour,data.Hour);
        netcdf.putVar(TDR1GrpID,TDR1Min,data.Min);
        netcdf.putVar(TDR1GrpID,TDR1Sec,data.Sec);
    end
    clear data
    
    % TDR2 DiveStat
    %load DiveStat file
    try
        data=readtable(strcat(TDR2DiveStatFiles.folder(TDR2DiveStatFiles.TOPPID==MetaDataAll.TOPPID(j)),...
            '\',strtok(TDR2DiveStatFiles.filename(TDR2DiveStatFiles.TOPPID==MetaDataAll.TOPPID(j)),'.'),'_QC.csv'));
        data.Time=datetime(data.JulDate,"ConvertFrom","datenum");
    end
    %Create a 1-D variable (length of divestat x 1) for each column of the
    %DiveStat file and populate each from the loaded file
    netcdf.reDef(ncid);
    if exist('data','var')==1
        TDR2dimid=netcdf.defDim(TDR2GrpID,'NumDives',size(data,1));
    else
        TDR2dimid=netcdf.defDim(TDR2GrpID,'NumDives',0);
    end

    TDR2Date=netcdf.defVar(TDR2GrpID,'DATE',"NC_STRING",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2Date,"Description","Date and time at of the start of the dive")
    netcdf.putAtt(TDR2GrpID,TDR2Date,'Time Zone','UTC');
    TDR2Depth=netcdf.defVar(TDR2GrpID,'MAXDEPTH',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2Depth,'Description','Maximum depth recorded during dive');
    netcdf.putAtt(TDR2GrpID,TDR2Depth,'Units','meters');
    TDR2Dur=netcdf.defVar(TDR2GrpID,'DURATION',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2Dur,'Description','Total duration of the dive');
    netcdf.putAtt(TDR2GrpID,TDR2Dur,'Units','seconds');
    TDR2DTime=netcdf.defVar(TDR2GrpID,'DESC_TIME',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2DTime,'Description','Time spent in descent phase of dive');
    netcdf.putAtt(TDR2GrpID,TDR2DTime,'Units','seconds');
    TDR2BTime=netcdf.defVar(TDR2GrpID,'BOTT_TIME',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2BTime,'Description','Time spent in bottom phase of dive');
    netcdf.putAtt(TDR2GrpID,TDR2BTime,'Units','seconds');
    TDR2ATime=netcdf.defVar(TDR2GrpID,'ASC_TIME',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2ATime,'Description','Time spent in ascent phase of dive');
    netcdf.putAtt(TDR2GrpID,TDR2ATime,'Units','seconds');
    TDR2DRate=netcdf.defVar(TDR2GrpID,'DESC_RATE',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2DRate,'Description','Average rate of descent');
    netcdf.putAtt(TDR2GrpID,TDR2DRate,'Units','meters per second');
    TDR2ARate=netcdf.defVar(TDR2GrpID,'ASC_RATE',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2ARate,'Description','Average rate of ascent');
    netcdf.putAtt(TDR2GrpID,TDR2ARate,'Units','meters per second');
    TDR2PDI=netcdf.defVar(TDR2GrpID,'PDI',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2PDI,"Description","Post-Dive Interval (surface time after the dive)");
    netcdf.putAtt(TDR2GrpID,TDR2PDI,'Units','seconds');
    TDR2DWigD=netcdf.defVar(TDR2GrpID,'WIGGLES_DESC',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2DWigD,'Description',"Number of vertical inflections detected during descent" + ...
        " phase")
    netcdf.putAtt(TDR2GrpID,TDR2DWigD,'Units',"Count")
    TDR2DWigB=netcdf.defVar(TDR2GrpID,'WIGGLES_BOTT',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2DWigB,'Description',"Number of vertical inflections detected during bottom" + ...
        " phase")
    netcdf.putAtt(TDR2GrpID,TDR2DWigB,'Units',"Count")
    TDR2DWigA=netcdf.defVar(TDR2GrpID,'WIGGLES_ASC',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2DWigA,'Description',"Number of vertical inflections detected during ascent" + ...
        " phase")
    netcdf.putAtt(TDR2GrpID,TDR2DWigA,'Units',"Count")
    TDR2TotVertDist=netcdf.defVar(TDR2GrpID,'TOT_VERT_DIST_BOTT',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2TotVertDist,"Description","Sum of all of the depth changes during the" + ...
        " bottom phase of the dive")
    netcdf.putAtt(TDR2GrpID,TDR2TotVertDist,"Units","meters")
    TDR2BottRng=netcdf.defVar(TDR2GrpID,'BOTT_RANGE',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2BottRng,"Description","Difference between max and min depth of the bottom phase")
    netcdf.putAtt(TDR2GrpID,TDR2BottRng,"Units","meters")
    TDR2Eff=netcdf.defVar(TDR2GrpID,'EFFICIENCY',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2Eff,"Description","Ratio of bottom time to dive cycle (Duration + PDI)")
    netcdf.putAtt(TDR2GrpID,TDR2Eff,"Units","")
    TDR2IDZ=netcdf.defVar(TDR2GrpID,'IDZ',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2IDZ,"Description","Intra-Depth Zone: a binary (0,1) indicator of whether" + ...
        " the max depth of the dive is within 20% of the max depth of the previous dive (see Tremblay" + ...
        " & Cherel, 2000)")
    netcdf.putAtt(TDR2GrpID,TDR2IDZ,"Units","")
    TDR2SolarEl=netcdf.defVar(TDR2GrpID,'SOLAR_EL',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2SolarEl,"Description","Angle of the sun relative to the horizon line" + ...
        " (-90\circ - 90 \circ) calculated from lat, lon, date, and time.")
    netcdf.putAtt(TDR2GrpID,TDR2SolarEl,"Units","\circ")
    TDR2Lat=netcdf.defVar(TDR2GrpID,'LAT',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2Lat,"Description","Decimal latitude at the start of the dive")
    TDR2Lon=netcdf.defVar(TDR2GrpID,'LON',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2Lon,"Description","Decimal longitude at the start of the dive")
    TDR2LatSE=netcdf.defVar(TDR2GrpID,'LAT_SE_KM',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2LatSE,"Description","Latitude error")
    netcdf.putAtt(TDR2GrpID,TDR2LatSE,"Units","km")
    TDR2LonSE=netcdf.defVar(TDR2GrpID,'LON_SE_KM',"NC_DOUBLE",TDR2dimid);
    netcdf.putAtt(TDR2GrpID,TDR2LonSE,"Description","Longitude error")
    netcdf.putAtt(TDR2GrpID,TDR2LonSE,"Units","km")
    TDR2Year=netcdf.defVar(TDR2GrpID,'YEAR',"NC_DOUBLE",TDR2dimid);
    TDR2Month=netcdf.defVar(TDR2GrpID,'MONTH',"NC_DOUBLE",TDR2dimid);
    TDR2Day=netcdf.defVar(TDR2GrpID,'DAY',"NC_DOUBLE",TDR2dimid);
    TDR2Hour=netcdf.defVar(TDR2GrpID,'HOUR',"NC_DOUBLE",TDR2dimid);
    TDR2Min=netcdf.defVar(TDR2GrpID,'MIN',"NC_DOUBLE",TDR2dimid);
    TDR2Sec=netcdf.defVar(TDR2GrpID,'SEC',"NC_DOUBLE",TDR2dimid);
    netcdf.endDef(ncid);

    if exist('data','var')==1
        netcdf.putVar(TDR2GrpID,TDR2Date,cellstr(data.Time));
        netcdf.putVar(TDR2GrpID,TDR2Depth,data.Maxdepth);
        netcdf.putVar(TDR2GrpID,TDR2Dur,data.Dduration);
        netcdf.putVar(TDR2GrpID,TDR2DTime,data.DescTime);
        netcdf.putVar(TDR2GrpID,TDR2BTime,data.Botttime);
        netcdf.putVar(TDR2GrpID,TDR2ATime,data.AscTime);
        netcdf.putVar(TDR2GrpID,TDR2DRate,data.DescRate);
        netcdf.putVar(TDR2GrpID,TDR2ARate,data.AscRate);
        netcdf.putVar(TDR2GrpID,TDR2PDI,data.PDI);
        netcdf.putVar(TDR2GrpID,TDR2DWigD,data.DWigglesDesc);
        netcdf.putVar(TDR2GrpID,TDR2DWigB,data.DWigglesBott);
        netcdf.putVar(TDR2GrpID,TDR2DWigA,data.DWigglesAsc);
        netcdf.putVar(TDR2GrpID,TDR2TotVertDist,data.TotVertDistBot);
        netcdf.putVar(TDR2GrpID,TDR2BottRng,data.BottRange);
        netcdf.putVar(TDR2GrpID,TDR2IDZ,data.IDZ);
        netcdf.putVar(TDR2GrpID,TDR2SolarEl,data.SolarEl);
        netcdf.putVar(TDR2GrpID,TDR2Lat,data.Lat);
        netcdf.putVar(TDR2GrpID,TDR2Lon,data.Lon);
        netcdf.putVar(TDR2GrpID,TDR2LatSE,data.Lat);
        netcdf.putVar(TDR2GrpID,TDR2LonSE,data.Lat);
        netcdf.putVar(TDR2GrpID,TDR2Year,data.Year);
        netcdf.putVar(TDR2GrpID,TDR2Month,data.Month);
        netcdf.putVar(TDR2GrpID,TDR2Day,data.Day);
        netcdf.putVar(TDR2GrpID,TDR2Hour,data.Hour);
        netcdf.putVar(TDR2GrpID,TDR2Min,data.Min);
        netcdf.putVar(TDR2GrpID,TDR2Sec,data.Sec);
    end
    clear data

    % TDR3 DiveStat
    %load DiveStat file
    try
        data=readtable(strcat(TDR3DiveStatFiles.folder(TDR3DiveStatFiles.TOPPID==TOPPID),...
            '\',strtok(TDR3DiveStatFiles.filename(TDR3DiveStatFiles.TOPPID==TOPPID),'.'),'_QC.csv'));
        data.Time=datetime(data.JulDate,"ConvertFrom","datenum");
    end
    %Create a 1-D variable (length of divestat x 1) for each column of the
    %DiveStat file and populate each from the loaded file
    netcdf.reDef(ncid);
    if exist('data','var')==1
        TDR3dimid=netcdf.defDim(TDR3GrpID,'NumDives',size(data,1));
    else
        TDR3dimid=netcdf.defDim(TDR3GrpID,'NumDives',0);
    end

    TDR3Date=netcdf.defVar(TDR3GrpID,'DATE',"NC_STRING",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3Date,"Description","Date and time at of the start of the dive")
    netcdf.putAtt(TDR3GrpID,TDR3Date,'Time Zone','UTC');
    TDR3Depth=netcdf.defVar(TDR3GrpID,'MAXDEPTH',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3Depth,'Description','Maximum depth recorded during dive');
    netcdf.putAtt(TDR3GrpID,TDR3Depth,'Units','meters');
    TDR3Dur=netcdf.defVar(TDR3GrpID,'DURATION',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3Dur,'Description','Total duration of the dive');
    netcdf.putAtt(TDR3GrpID,TDR3Dur,'Units','seconds');
    TDR3DTime=netcdf.defVar(TDR3GrpID,'DESC_TIME',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3DTime,'Description','Time spent in descent phase of dive');
    netcdf.putAtt(TDR3GrpID,TDR3DTime,'Units','seconds');
    TDR3BTime=netcdf.defVar(TDR3GrpID,'BOTT_TIME',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3BTime,'Description','Time spent in bottom phase of dive');
    netcdf.putAtt(TDR3GrpID,TDR3BTime,'Units','seconds');
    TDR3ATime=netcdf.defVar(TDR3GrpID,'ASC_TIME',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3ATime,'Description','Time spent in ascent phase of dive');
    netcdf.putAtt(TDR3GrpID,TDR3ATime,'Units','seconds');
    TDR3DRate=netcdf.defVar(TDR3GrpID,'DESC_RATE',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3DRate,'Description','Average rate of descent');
    netcdf.putAtt(TDR3GrpID,TDR3DRate,'Units','meters per second');
    TDR3ARate=netcdf.defVar(TDR3GrpID,'ASC_RATE',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3ARate,'Description','Average rate of ascent');
    netcdf.putAtt(TDR3GrpID,TDR3ARate,'Units','meters per second');
    TDR3PDI=netcdf.defVar(TDR3GrpID,'PDI',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3PDI,"Description","Post-Dive Interval (surface time after the dive)");
    netcdf.putAtt(TDR3GrpID,TDR3PDI,'Units','seconds');
    TDR3DWigD=netcdf.defVar(TDR3GrpID,'WIGGLES_DESC',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3DWigD,'Description',"Number of vertical inflections detected during " + ...
        "descent phase")
    netcdf.putAtt(TDR3GrpID,TDR3DWigD,'Units',"Count")
    TDR3DWigB=netcdf.defVar(TDR3GrpID,'WIGGLES_BOTT',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3DWigB,'Description',"Number of vertical inflections detected during " + ...
        "bottom phase")
    netcdf.putAtt(TDR3GrpID,TDR3DWigB,'Units',"Count")
    TDR3DWigA=netcdf.defVar(TDR3GrpID,'WIGGLES_ASC',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3DWigA,'Description',"Number of vertical inflections detected during " + ...
        "ascent phase")
    netcdf.putAtt(TDR3GrpID,TDR3DWigA,'Units',"Count")
    TDR3TotVertDist=netcdf.defVar(TDR3GrpID,'TOT_VERT_DIST_BOTT',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3TotVertDist,"Description","Sum of all of the depth changes during the " + ...
        "bottom phase of the dive")
    netcdf.putAtt(TDR3GrpID,TDR3TotVertDist,"Units","meters")
    TDR3BottRng=netcdf.defVar(TDR3GrpID,'BOTT_RANGE',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3BottRng,"Description","Difference between max and min depth of the " + ...
        "bottom phase")
    netcdf.putAtt(TDR3GrpID,TDR3BottRng,"Units","meters")
    TDR3Eff=netcdf.defVar(TDR3GrpID,'EFFICIENCY',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3Eff,"Description","Ratio of bottom time to dive cycle (Duration + PDI)")
    netcdf.putAtt(TDR3GrpID,TDR3Eff,"Units","")
    TDR3IDZ=netcdf.defVar(TDR3GrpID,'IDZ',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3IDZ,"Description","Intra-Depth Zone: a binary (0,1) indicator of whether" + ...
        " the max depth of the dive is within 20% of the max depth of the previous dive (see " + ...
        "Tremblay & Cherel, 2000)")
    netcdf.putAtt(TDR3GrpID,TDR3IDZ,"Units","")
    TDR3SolarEl=netcdf.defVar(TDR3GrpID,'SOLAR_EL',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3SolarEl,"Description","Angle of the sun relative to the horizon line" + ...
        " (-90\circ - 90 \circ) calculated from lat, lon, date, and time.")
    netcdf.putAtt(TDR3GrpID,TDR3SolarEl,"Units","\circ")
    TDR3Lat=netcdf.defVar(TDR3GrpID,'LAT',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3Lat,"Description","Decimal latitude at the start of the dive")
    TDR3Lon=netcdf.defVar(TDR3GrpID,'LON',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3Lon,"Description","Decimal longitude at the start of the dive")
    TDR3LatSE=netcdf.defVar(TDR3GrpID,'LAT_SE_KM',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3LatSE,"Description","Latitude error")
    netcdf.putAtt(TDR3GrpID,TDR3LatSE,"Units","km")
    TDR3LonSE=netcdf.defVar(TDR3GrpID,'LON_SE_KM',"NC_DOUBLE",TDR3dimid);
    netcdf.putAtt(TDR3GrpID,TDR3LonSE,"Description","Longitude error")
    netcdf.putAtt(TDR3GrpID,TDR3LonSE,"Units","km")
    TDR3Year=netcdf.defVar(TDR3GrpID,'YEAR',"NC_DOUBLE",TDR3dimid);
    TDR3Month=netcdf.defVar(TDR3GrpID,'MONTH',"NC_DOUBLE",TDR3dimid);
    TDR3Day=netcdf.defVar(TDR3GrpID,'DAY',"NC_DOUBLE",TDR3dimid);
    TDR3Hour=netcdf.defVar(TDR3GrpID,'HOUR',"NC_DOUBLE",TDR3dimid);
    TDR3Min=netcdf.defVar(TDR3GrpID,'MIN',"NC_DOUBLE",TDR3dimid);
    TDR3Sec=netcdf.defVar(TDR3GrpID,'SEC',"NC_DOUBLE",TDR3dimid);
    netcdf.endDef(ncid);

    if exist('data','var')==1
        netcdf.putVar(TDR3GrpID,TDR3Date,cellstr(data.Time));
        netcdf.putVar(TDR3GrpID,TDR3Depth,data.Maxdepth);
        netcdf.putVar(TDR3GrpID,TDR3Dur,data.Dduration);
        netcdf.putVar(TDR3GrpID,TDR3DTime,data.DescTime);
        netcdf.putVar(TDR3GrpID,TDR3BTime,data.Botttime);
        netcdf.putVar(TDR3GrpID,TDR3ATime,data.AscTime);
        netcdf.putVar(TDR3GrpID,TDR3DRate,data.DescRate);
        netcdf.putVar(TDR3GrpID,TDR3ARate,data.AscRate);
        netcdf.putVar(TDR3GrpID,TDR3PDI,data.PDI);
        netcdf.putVar(TDR3GrpID,TDR3DWigD,data.DWigglesDesc);
        netcdf.putVar(TDR3GrpID,TDR3DWigB,data.DWigglesBott);
        netcdf.putVar(TDR3GrpID,TDR3DWigA,data.DWigglesAsc);
        netcdf.putVar(TDR3GrpID,TDR3TotVertDist,data.TotVertDistBot);
        netcdf.putVar(TDR3GrpID,TDR3BottRng,data.BottRange);
        netcdf.putVar(TDR3GrpID,TDR3IDZ,data.IDZ);
        netcdf.putVar(TDR3GrpID,TDR3SolarEl,data.SolarEl);
        netcdf.putVar(TDR3GrpID,TDR3Lat,data.Lat);
        netcdf.putVar(TDR3GrpID,TDR3Lon,data.Lon);
        netcdf.putVar(TDR3GrpID,TDR3LatSE,data.Lat);
        netcdf.putVar(TDR3GrpID,TDR3LonSE,data.Lat);
        netcdf.putVar(TDR3GrpID,TDR3Year,data.Year);
        netcdf.putVar(TDR3GrpID,TDR3Month,data.Month);
        netcdf.putVar(TDR3GrpID,TDR3Day,data.Day);
        netcdf.putVar(TDR3GrpID,TDR3Hour,data.Hour);
        netcdf.putVar(TDR3GrpID,TDR3Min,data.Min);
        netcdf.putVar(TDR3GrpID,TDR3Sec,data.Sec);
    end
    clear data

    % TDR1 Subset DiveStat
    %load DiveStat file
    try
        %if TDR full-resolution sampling frequency is every 8 seconds, use
        %main DiveStat file here
        if TagMetaDataAll.TDR1_Freq(i)==8
            data=readtable(strcat(TDRDiveStatFiles.folder(TDRDiveStatFiles.TOPPID==TOPPID),...
                '\',strtok(TDRDiveStatFiles.filename(TDRDiveStatFiles.TOPPID==TOPPID),'.'),'_QC.csv'));
            data.Time=datetime(data.JulDate,"ConvertFrom","datenum");
        %otherwise, look for subsampled DiveStat
        else
            data=readtable(strcat(TDRSubDiveStatFiles.folder(TDRSubDiveStatFiles.TOPPID==TOPPID),...
                '\',strtok(TDRSubDiveStatFiles.filename(TDRSubDiveStatFiles.TOPPID==TOPPID),'.'),'_QC.csv'));
            data.Time=datetime(data.JulDate,"ConvertFrom","datenum");
        end
    end

    %Create a 1-D variable (length of divestat x 1) for each column of the
    %DiveStat file and populate each from the loaded file
    netcdf.reDef(ncid);
    if exist('data','var')==1
        TDR1Subdimid=netcdf.defDim(TDR1SubGrpID,'NumDives',size(data,1));
    else
        TDR1Subdimid=netcdf.defDim(TDR1SubGrpID,'NumDives',0);
    end

    TDR1SubDate=netcdf.defVar(TDR1SubGrpID,'DATE',"NC_STRING",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDate,"Description","Date and time at of the start of the dive")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDate,'Time Zone','UTC');
    TDR1SubDepth=netcdf.defVar(TDR1SubGrpID,'MAXDEPTH',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDepth,'Description','Maximum depth recorded during dive');
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDepth,'Units','meters');
    TDR1SubDur=netcdf.defVar(TDR1SubGrpID,'DURATION',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDur,'Description','Total duration of the dive');
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDur,'Units','seconds');
    TDR1SubDTime=netcdf.defVar(TDR1SubGrpID,'DESC_TIME',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDTime,'Description','Time spent in descent phase of dive');
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDTime,'Units','seconds');
    TDR1SubBTime=netcdf.defVar(TDR1SubGrpID,'BOTT_TIME',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubBTime,'Description','Time spent in bottom phase of dive');
    netcdf.putAtt(TDR1SubGrpID,TDR1SubBTime,'Units','seconds');
    TDR1SubATime=netcdf.defVar(TDR1SubGrpID,'ASC_TIME',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubATime,'Description','Time spent in ascent phase of dive');
    netcdf.putAtt(TDR1SubGrpID,TDR1SubATime,'Units','seconds');
    TDR1SubDRate=netcdf.defVar(TDR1SubGrpID,'DESC_RATE',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDRate,'Description','Average rate of descent');
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDRate,'Units','meters per second');
    TDR1SubARate=netcdf.defVar(TDR1SubGrpID,'ASC_RATE',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubARate,'Description','Average rate of ascent');
    netcdf.putAtt(TDR1SubGrpID,TDR1SubARate,'Units','meters per second');
    TDR1SubPDI=netcdf.defVar(TDR1SubGrpID,'PDI',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubPDI,"Description","Post-Dive Interval (surface time after the dive)");
    netcdf.putAtt(TDR1SubGrpID,TDR1SubPDI,'Units','seconds');
    TDR1SubDWigD=netcdf.defVar(TDR1SubGrpID,'WIGGLES_DESC',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDWigD,'Description',"Number of vertical inflections detected during" + ...
        " descent phase")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDWigD,'Units',"Count")
    TDR1SubDWigB=netcdf.defVar(TDR1SubGrpID,'WIGGLES_BOTT',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDWigB,'Description',"Number of vertical inflections detected during" + ...
        " bottom phase")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDWigB,'Units',"Count")
    TDR1SubDWigA=netcdf.defVar(TDR1SubGrpID,'WIGGLES_ASC',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDWigA,'Description',"Number of vertical inflections detected during" + ...
        " ascent phase")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubDWigA,'Units',"Count")
    TDR1SubTotVertDist=netcdf.defVar(TDR1SubGrpID,'TOT_VERT_DIST_BOTT',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubTotVertDist,"Description","Sum of all of the depth changes during" + ...
        " the bottom phase of the dive")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubTotVertDist,"Units","meters")
    TDR1SubBottRng=netcdf.defVar(TDR1SubGrpID,'BOTT_RANGE',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubBottRng,"Description","Difference between max and min depth of the" + ...
        " bottom phase")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubBottRng,"Units","meters")
    TDR1SubEff=netcdf.defVar(TDR1SubGrpID,'EFFICIENCY',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubEff,"Description","Ratio of bottom time to dive cycle (Duration + PDI)")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubEff,"Units","")
    TDR1SubIDZ=netcdf.defVar(TDR1SubGrpID,'IDZ',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubIDZ,"Description","Intra-Depth Zone: a binary (0,1) indicator of" + ...
        " whether the max depth of the dive is within 20% of the max depth of the previous dive" + ...
        " (see Tremblay & Cherel, 2000)")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubIDZ,"Units","")
    TDR1SubSolarEl=netcdf.defVar(TDR1SubGrpID,'SOLAR_EL',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubSolarEl,"Description","Angle of the sun relative to the horizon line" + ...
        " (-90\circ - 90 \circ) calculated from lat, lon, date, and time.")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubSolarEl,"Units","\circ")
    TDR1SubLat=netcdf.defVar(TDR1SubGrpID,'LAT',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubLat,"Description","Decimal latitude at the start of the dive")
    TDR1SubLon=netcdf.defVar(TDR1SubGrpID,'LON',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubLon,"Description","Decimal longitude at the start of the dive")
    TDR1SubLatSE=netcdf.defVar(TDR1SubGrpID,'LAT_SE_KM',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubLatSE,"Description","Latitude error")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubLatSE,"Units","km")
    TDR1SubLonSE=netcdf.defVar(TDR1SubGrpID,'LON_SE_KM',"NC_DOUBLE",TDR1Subdimid);
    netcdf.putAtt(TDR1SubGrpID,TDR1SubLonSE,"Description","Longitude error")
    netcdf.putAtt(TDR1SubGrpID,TDR1SubLonSE,"Units","km")
    TDR1SubYear=netcdf.defVar(TDR1SubGrpID,'YEAR',"NC_DOUBLE",TDR1Subdimid);
    TDR1SubMonth=netcdf.defVar(TDR1SubGrpID,'MONTH',"NC_DOUBLE",TDR1Subdimid);
    TDR1SubDay=netcdf.defVar(TDR1SubGrpID,'DAY',"NC_DOUBLE",TDR1Subdimid);
    TDR1SubHour=netcdf.defVar(TDR1SubGrpID,'HOUR',"NC_DOUBLE",TDR1Subdimid);
    TDR1SubMin=netcdf.defVar(TDR1SubGrpID,'MIN',"NC_DOUBLE",TDR1Subdimid);
    TDR1SubSec=netcdf.defVar(TDR1SubGrpID,'SEC',"NC_DOUBLE",TDR1Subdimid);
    netcdf.endDef(ncid);

    if exist('data','var')==1
        netcdf.putVar(TDR1SubGrpID,TDR1SubDate,cellstr(data.Time));
        netcdf.putVar(TDR1SubGrpID,TDR1SubDepth,data.Maxdepth);
        netcdf.putVar(TDR1SubGrpID,TDR1SubDur,data.Dduration);
        netcdf.putVar(TDR1SubGrpID,TDR1SubDTime,data.DescTime);
        netcdf.putVar(TDR1SubGrpID,TDR1SubBTime,data.Botttime);
        netcdf.putVar(TDR1SubGrpID,TDR1SubATime,data.AscTime);
        netcdf.putVar(TDR1SubGrpID,TDR1SubDRate,data.DescRate);
        netcdf.putVar(TDR1SubGrpID,TDR1SubARate,data.AscRate);
        netcdf.putVar(TDR1SubGrpID,TDR1SubPDI,data.PDI);
        netcdf.putVar(TDR1SubGrpID,TDR1SubDWigD,data.DWigglesDesc);
        netcdf.putVar(TDR1SubGrpID,TDR1SubDWigB,data.DWigglesBott);
        netcdf.putVar(TDR1SubGrpID,TDR1SubDWigA,data.DWigglesAsc);
        netcdf.putVar(TDR1SubGrpID,TDR1SubTotVertDist,data.TotVertDistBot);
        netcdf.putVar(TDR1SubGrpID,TDR1SubBottRng,data.BottRange);
        netcdf.putVar(TDR1SubGrpID,TDR1SubIDZ,data.IDZ);
        netcdf.putVar(TDR1SubGrpID,TDR1SubSolarEl,data.SolarEl);
        netcdf.putVar(TDR1SubGrpID,TDR1SubLat,data.Lat);
        netcdf.putVar(TDR1SubGrpID,TDR1SubLon,data.Lon);
        netcdf.putVar(TDR1SubGrpID,TDR1SubLatSE,data.Lat);
        netcdf.putVar(TDR1SubGrpID,TDR1SubLonSE,data.Lat);
        netcdf.putVar(TDR1SubGrpID,TDR1SubYear,data.Year);
        netcdf.putVar(TDR1SubGrpID,TDR1SubMonth,data.Month);
        netcdf.putVar(TDR1SubGrpID,TDR1SubDay,data.Day);
        netcdf.putVar(TDR1SubGrpID,TDR1SubHour,data.Hour);
        netcdf.putVar(TDR1SubGrpID,TDR1SubMin,data.Min);
        netcdf.putVar(TDR1SubGrpID,TDR1SubSec,data.Sec);
    end
    clear data

    % TDR2Sub DiveStat
    %load DiveStat file
    try
        %if TDR full-resolution sampling frequency is every 8 seconds, use
        %main DiveStat file here
        if TagMetaDataAll.TDR2_Freq(i)==8
            data=readtable(strcat(TDR2DiveStatFiles.folder(TDR2DiveStatFiles.TOPPID==TOPPID),...
                '\',strtok(TDR2DiveStatFiles.filename(TDR2DiveStatFiles.TOPPID==TOPPID),'.'),'_QC.csv'));
            data.Time=datetime(data.JulDate,"ConvertFrom","datenum");
        %otherwise, look for subsampled DiveStat
        else
            data=readtable(strcat(TDR2SubDiveStatFiles.folder(TDR2SubDiveStatFiles.TOPPID==TOPPID),...
                '\',strtok(TDR2SubDiveStatFiles.filename(TDR2SubDiveStatFiles.TOPPID==TOPPID),'.'),'_QC.csv'));
            data.Time=datetime(data.JulDate,"ConvertFrom","datenum");
        end
    end
    %Create a 1-D variable (length of divestat x 1) for each column of the
    %DiveStat file and populate each from the loaded file
    netcdf.reDef(ncid);
    if exist('data','var')==1
        TDR2Subdimid=netcdf.defDim(TDR2SubGrpID,'NumDives',size(data,1));
    else
        TDR2Subdimid=netcdf.defDim(TDR2SubGrpID,'NumDives',0);
    end

    TDR2SubDate=netcdf.defVar(TDR2SubGrpID,'DATE',"NC_STRING",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDate,"Description","Date and time at of the start of the dive")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDate,'Time Zone','UTC');
    TDR2SubDepth=netcdf.defVar(TDR2SubGrpID,'MAXDEPTH',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDepth,'Description','Maximum depth recorded during dive');
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDepth,'Units','meters');
    TDR2SubDur=netcdf.defVar(TDR2SubGrpID,'DURATION',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDur,'Description','Total duration of the dive');
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDur,'Units','seconds');
    TDR2SubDTime=netcdf.defVar(TDR2SubGrpID,'DESC_TIME',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDTime,'Description','Time spent in descent phase of dive');
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDTime,'Units','seconds');
    TDR2SubBTime=netcdf.defVar(TDR2SubGrpID,'BOTT_TIME',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubBTime,'Description','Time spent in bottom phase of dive');
    netcdf.putAtt(TDR2SubGrpID,TDR2SubBTime,'Units','seconds');
    TDR2SubATime=netcdf.defVar(TDR2SubGrpID,'ASC_TIME',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubATime,'Description','Time spent in ascent phase of dive');
    netcdf.putAtt(TDR2SubGrpID,TDR2SubATime,'Units','seconds');
    TDR2SubDRate=netcdf.defVar(TDR2SubGrpID,'DESC_RATE',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDRate,'Description','Average rate of descent');
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDRate,'Units','meters per second');
    TDR2SubARate=netcdf.defVar(TDR2SubGrpID,'ASC_RATE',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubARate,'Description','Average rate of ascent');
    netcdf.putAtt(TDR2SubGrpID,TDR2SubARate,'Units','meters per second');
    TDR2SubPDI=netcdf.defVar(TDR2SubGrpID,'PDI',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubPDI,"Description","Post-Dive Interval (surface time after the dive)");
    netcdf.putAtt(TDR2SubGrpID,TDR2SubPDI,'Units','seconds');
    TDR2SubDWigD=netcdf.defVar(TDR2SubGrpID,'WIGGLES_DESC',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDWigD,'Description',"Number of vertical inflections detected during " + ...
        "descent phase")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDWigD,'Units',"Count")
    TDR2SubDWigB=netcdf.defVar(TDR2SubGrpID,'WIGGLES_BOTT',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDWigB,'Description',"Number of vertical inflections detected during " + ...
        "bottom phase")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDWigB,'Units',"Count")
    TDR2SubDWigA=netcdf.defVar(TDR2SubGrpID,'WIGGLES_ASC',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDWigA,'Description',"Number of vertical inflections detected during " + ...
        "ascent phase")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubDWigA,'Units',"Count")
    TDR2SubTotVertDist=netcdf.defVar(TDR2SubGrpID,'TOT_VERT_DIST_BOTT',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubTotVertDist,"Description","Sum of all of the depth changes during " + ...
        "the bottom phase of the dive")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubTotVertDist,"Units","meters")
    TDR2SubBottRng=netcdf.defVar(TDR2SubGrpID,'BOTT_RANGE',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubBottRng,"Description","Difference between max and min depth of the " + ...
        "bottom phase")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubBottRng,"Units","meters")
    TDR2SubEff=netcdf.defVar(TDR2SubGrpID,'EFFICIENCY',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubEff,"Description","Ratio of bottom time to dive cycle (Duration + PDI)")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubEff,"Units","")
    TDR2SubIDZ=netcdf.defVar(TDR2SubGrpID,'IDZ',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubIDZ,"Description","Intra-Depth Zone: a binary (0,1) indicator of" + ...
        " whether the max depth of the dive is within 20% of the max depth of the previous dive" + ...
        " (see Tremblay & Cherel, 2000)")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubIDZ,"Units","")
    TDR2SubSolarEl=netcdf.defVar(TDR2SubGrpID,'SOLAR_EL',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubSolarEl,"Description","Angle of the sun relative to the horizon" + ...
        " line (-90\circ - 90 \circ) calculated from lat, lon, date, and time.")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubSolarEl,"Units","\circ")
    TDR2SubLat=netcdf.defVar(TDR2SubGrpID,'LAT',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubLat,"Description","Decimal latitude at the start of the dive")
    TDR2SubLon=netcdf.defVar(TDR2SubGrpID,'LON',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubLon,"Description","Decimal longitude at the start of the dive")
    TDR2SubLatSE=netcdf.defVar(TDR2SubGrpID,'LAT_SE_KM',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubLatSE,"Description","Latitude error")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubLatSE,"Units","km")
    TDR2SubLonSE=netcdf.defVar(TDR2SubGrpID,'LON_SE_KM',"NC_DOUBLE",TDR2Subdimid);
    netcdf.putAtt(TDR2SubGrpID,TDR2SubLonSE,"Description","Longitude error")
    netcdf.putAtt(TDR2SubGrpID,TDR2SubLonSE,"Units","km")
    TDR2SubYear=netcdf.defVar(TDR2SubGrpID,'YEAR',"NC_DOUBLE",TDR2Subdimid);
    TDR2SubMonth=netcdf.defVar(TDR2SubGrpID,'MONTH',"NC_DOUBLE",TDR2Subdimid);
    TDR2SubDay=netcdf.defVar(TDR2SubGrpID,'DAY',"NC_DOUBLE",TDR2Subdimid);
    TDR2SubHour=netcdf.defVar(TDR2SubGrpID,'HOUR',"NC_DOUBLE",TDR2Subdimid);
    TDR2SubMin=netcdf.defVar(TDR2SubGrpID,'MIN',"NC_DOUBLE",TDR2Subdimid);
    TDR2SubSec=netcdf.defVar(TDR2SubGrpID,'SEC',"NC_DOUBLE",TDR2Subdimid);
    netcdf.endDef(ncid);

    if exist('data','var')==1
        netcdf.putVar(TDR2SubGrpID,TDR2SubDate,cellstr(data.Time));
        netcdf.putVar(TDR2SubGrpID,TDR2SubDepth,data.Maxdepth);
        netcdf.putVar(TDR2SubGrpID,TDR2SubDur,data.Dduration);
        netcdf.putVar(TDR2SubGrpID,TDR2SubDTime,data.DescTime);
        netcdf.putVar(TDR2SubGrpID,TDR2SubBTime,data.Botttime);
        netcdf.putVar(TDR2SubGrpID,TDR2SubATime,data.AscTime);
        netcdf.putVar(TDR2SubGrpID,TDR2SubDRate,data.DescRate);
        netcdf.putVar(TDR2SubGrpID,TDR2SubARate,data.AscRate);
        netcdf.putVar(TDR2SubGrpID,TDR2SubPDI,data.PDI);
        netcdf.putVar(TDR2SubGrpID,TDR2SubDWigD,data.DWigglesDesc);
        netcdf.putVar(TDR2SubGrpID,TDR2SubDWigB,data.DWigglesBott);
        netcdf.putVar(TDR2SubGrpID,TDR2SubDWigA,data.DWigglesAsc);
        netcdf.putVar(TDR2SubGrpID,TDR2SubTotVertDist,data.TotVertDistBot);
        netcdf.putVar(TDR2SubGrpID,TDR2SubBottRng,data.BottRange);
        netcdf.putVar(TDR2SubGrpID,TDR2SubIDZ,data.IDZ);
        netcdf.putVar(TDR2SubGrpID,TDR2SubSolarEl,data.SolarEl);
        netcdf.putVar(TDR2SubGrpID,TDR2SubLat,data.Lat);
        netcdf.putVar(TDR2SubGrpID,TDR2SubLon,data.Lon);
        netcdf.putVar(TDR2SubGrpID,TDR2SubLatSE,data.Lat);
        netcdf.putVar(TDR2SubGrpID,TDR2SubLonSE,data.Lat);
        netcdf.putVar(TDR2SubGrpID,TDR2SubYear,data.Year);
        netcdf.putVar(TDR2SubGrpID,TDR2SubMonth,data.Month);
        netcdf.putVar(TDR2SubGrpID,TDR2SubDay,data.Day);
        netcdf.putVar(TDR2SubGrpID,TDR2SubHour,data.Hour);
        netcdf.putVar(TDR2SubGrpID,TDR2SubMin,data.Min);
        netcdf.putVar(TDR2SubGrpID,TDR2SubSec,data.Sec);
    end
    clear data

    % TDR3Sub DiveStat
    %load DiveStat file
    try
        %if TDR full-resolution sampling frequency is every 8 seconds, use
        %main DiveStat file here
        if TagMetaDataAll.TDR3_Freq(i)==8
            data=readtable(strcat(TDR3DiveStatFiles.folder(TDR3DiveStatFiles.TOPPID==TOPPID),...
                '\',strtok(TDR3DiveStatFiles.filename(TDR3DiveStatFiles.TOPPID==TOPPID),'.'),'_QC.csv'));
            data.Time=datetime(data.JulDate,"ConvertFrom","datenum");
        %otherwise, look for subsampled DiveStat
        else
            data=readtable(strcat(TDR3SubDiveStatFiles.folder(TDR3SubDiveStatFiles.TOPPID==TOPPID),...
                '\',strtok(TDR3SubDiveStatFiles.filename(TDR3SubDiveStatFiles.TOPPID==TOPPID),'.'),'_QC.csv'));
            data.Time=datetime(data.JulDate,"ConvertFrom","datenum");
        end
    end

    %Create a 1-D variable (length of divestat x 1) for each column of the
    %DiveStat file and populate each from the loaded file
    netcdf.reDef(ncid);
    if exist('data','var')==1
        TDR3Subdimid=netcdf.defDim(TDR3SubGrpID,'NumDives',size(data,1));
    else
        TDR3Subdimid=netcdf.defDim(TDR3SubGrpID,'NumDives',0);
    end

    TDR3SubDate=netcdf.defVar(TDR3SubGrpID,'DATE',"NC_STRING",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDate,"Description","Date and time at of the start of the dive")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDate,'Time Zone','UTC');
    TDR3SubDepth=netcdf.defVar(TDR3SubGrpID,'MAXDEPTH',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDepth,'Description','Maximum depth recorded during dive');
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDepth,'Units','meters');
    TDR3SubDur=netcdf.defVar(TDR3SubGrpID,'DURATION',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDur,'Description','Total duration of the dive');
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDur,'Units','seconds');
    TDR3SubDTime=netcdf.defVar(TDR3SubGrpID,'DESC_TIME',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDTime,'Description','Time spent in descent phase of dive');
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDTime,'Units','seconds');
    TDR3SubBTime=netcdf.defVar(TDR3SubGrpID,'BOTT_TIME',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubBTime,'Description','Time spent in bottom phase of dive');
    netcdf.putAtt(TDR3SubGrpID,TDR3SubBTime,'Units','seconds');
    TDR3SubATime=netcdf.defVar(TDR3SubGrpID,'ASC_TIME',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubATime,'Description','Time spent in ascent phase of dive');
    netcdf.putAtt(TDR3SubGrpID,TDR3SubATime,'Units','seconds');
    TDR3SubDRate=netcdf.defVar(TDR3SubGrpID,'DESC_RATE',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDRate,'Description','Average rate of descent');
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDRate,'Units','meters per second');
    TDR3SubARate=netcdf.defVar(TDR3SubGrpID,'ASC_RATE',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubARate,'Description','Average rate of ascent');
    netcdf.putAtt(TDR3SubGrpID,TDR3SubARate,'Units','meters per second');
    TDR3SubPDI=netcdf.defVar(TDR3SubGrpID,'PDI',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubPDI,"Description","Post-Dive Interval (surface time after the dive)");
    netcdf.putAtt(TDR3SubGrpID,TDR3SubPDI,'Units','seconds');
    TDR3SubDWigD=netcdf.defVar(TDR3SubGrpID,'WIGGLES_DESC',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDWigD,'Description',"Number of vertical inflections detected during " + ...
        "descent phase")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDWigD,'Units',"Count")
    TDR3SubDWigB=netcdf.defVar(TDR3SubGrpID,'WIGGLES_BOTT',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDWigB,'Description',"Number of vertical inflections detected during " + ...
        "bottom phase")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDWigB,'Units',"Count")
    TDR3SubDWigA=netcdf.defVar(TDR3SubGrpID,'WIGGLES_ASC',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDWigA,'Description',"Number of vertical inflections detected during " + ...
        "ascent phase")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubDWigA,'Units',"Count")
    TDR3SubTotVertDist=netcdf.defVar(TDR3SubGrpID,'TOT_VERT_DIST_BOTT',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubTotVertDist,"Description","Sum of all of the depth changes during " + ...
        "the bottom phase of the dive")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubTotVertDist,"Units","meters")
    TDR3SubBottRng=netcdf.defVar(TDR3SubGrpID,'BOTT_RANGE',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubBottRng,"Description","Difference between max and min depth of the " + ...
        "bottom phase")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubBottRng,"Units","meters")
    TDR3SubEff=netcdf.defVar(TDR3SubGrpID,'EFFICIENCY',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubEff,"Description","Ratio of bottom time to dive cycle (Duration + PDI)")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubEff,"Units","")
    TDR3SubIDZ=netcdf.defVar(TDR3SubGrpID,'IDZ',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubIDZ,"Description","Intra-Depth Zone: a binary (0,1) indicator of" + ...
        " whether the max depth of the dive is within 20% of the max depth of the previous dive" + ...
        " (see Tremblay & Cherel, 2000)")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubIDZ,"Units","")
    TDR3SubSolarEl=netcdf.defVar(TDR3SubGrpID,'SOLAR_EL',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubSolarEl,"Description","Angle of the sun relative to the horizon " + ...
        "line (-90\circ - 90 \circ) calculated from lat, lon, date, and time.")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubSolarEl,"Units","\circ")
    TDR3SubLat=netcdf.defVar(TDR3SubGrpID,'LAT',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubLat,"Description","Decimal latitude at the start of the dive")
    TDR3SubLon=netcdf.defVar(TDR3SubGrpID,'LON',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubLon,"Description","Decimal longitude at the start of the dive")
    TDR3SubLatSE=netcdf.defVar(TDR3SubGrpID,'LAT_SE_KM',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubLatSE,"Description","Latitude error")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubLatSE,"Units","km")
    TDR3SubLonSE=netcdf.defVar(TDR3SubGrpID,'LON_SE_KM',"NC_DOUBLE",TDR3Subdimid);
    netcdf.putAtt(TDR3SubGrpID,TDR3SubLonSE,"Description","Longitude error")
    netcdf.putAtt(TDR3SubGrpID,TDR3SubLonSE,"Units","km")
    TDR3SubYear=netcdf.defVar(TDR3SubGrpID,'YEAR',"NC_DOUBLE",TDR3Subdimid);
    TDR3SubMonth=netcdf.defVar(TDR3SubGrpID,'MONTH',"NC_DOUBLE",TDR3Subdimid);
    TDR3SubDay=netcdf.defVar(TDR3SubGrpID,'DAY',"NC_DOUBLE",TDR3Subdimid);
    TDR3SubHour=netcdf.defVar(TDR3SubGrpID,'HOUR',"NC_DOUBLE",TDR3Subdimid);
    TDR3SubMin=netcdf.defVar(TDR3SubGrpID,'MIN',"NC_DOUBLE",TDR3Subdimid);
    TDR3SubSec=netcdf.defVar(TDR3SubGrpID,'SEC',"NC_DOUBLE",TDR3Subdimid);
    netcdf.endDef(ncid);

    if exist('data','var')==1
        netcdf.putVar(TDR3SubGrpID,TDR3SubDate,cellstr(data.Time));
        netcdf.putVar(TDR3SubGrpID,TDR3SubDepth,data.Maxdepth);
        netcdf.putVar(TDR3SubGrpID,TDR3SubDur,data.Dduration);
        netcdf.putVar(TDR3SubGrpID,TDR3SubDTime,data.DescTime);
        netcdf.putVar(TDR3SubGrpID,TDR3SubBTime,data.Botttime);
        netcdf.putVar(TDR3SubGrpID,TDR3SubATime,data.AscTime);
        netcdf.putVar(TDR3SubGrpID,TDR3SubDRate,data.DescRate);
        netcdf.putVar(TDR3SubGrpID,TDR3SubARate,data.AscRate);
        netcdf.putVar(TDR3SubGrpID,TDR3SubPDI,data.PDI);
        netcdf.putVar(TDR3SubGrpID,TDR3SubDWigD,data.DWigglesDesc);
        netcdf.putVar(TDR3SubGrpID,TDR3SubDWigB,data.DWigglesBott);
        netcdf.putVar(TDR3SubGrpID,TDR3SubDWigA,data.DWigglesAsc);
        netcdf.putVar(TDR3SubGrpID,TDR3SubTotVertDist,data.TotVertDistBot);
        netcdf.putVar(TDR3SubGrpID,TDR3SubBottRng,data.BottRange);
        netcdf.putVar(TDR3SubGrpID,TDR3SubIDZ,data.IDZ);
        netcdf.putVar(TDR3SubGrpID,TDR3SubSolarEl,data.SolarEl);
        netcdf.putVar(TDR3SubGrpID,TDR3SubLat,data.Lat);
        netcdf.putVar(TDR3SubGrpID,TDR3SubLon,data.Lon);
        netcdf.putVar(TDR3SubGrpID,TDR3SubLatSE,data.Lat);
        netcdf.putVar(TDR3SubGrpID,TDR3SubLonSE,data.Lat);
        netcdf.putVar(TDR3SubGrpID,TDR3SubYear,data.Year);
        netcdf.putVar(TDR3SubGrpID,TDR3SubMonth,data.Month);
        netcdf.putVar(TDR3SubGrpID,TDR3SubDay,data.Day);
        netcdf.putVar(TDR3SubGrpID,TDR3SubHour,data.Hour);
        netcdf.putVar(TDR3SubGrpID,TDR3SubMin,data.Min);
        netcdf.putVar(TDR3SubGrpID,TDR3SubSec,data.Sec);
    end
    clear data

    %AniMotum Track
    try
        data=readtable(strcat(TrackAniMotumFiles.folder(TrackAniMotumFiles.TOPPID==TOPPID),...
        '\',TrackAniMotumFiles.filename(TrackAniMotumFiles.TOPPID==TOPPID)));
        data.date=datetime(data.date);
    end
    
    netcdf.reDef(ncid);
    if exist('data','var')==1
        TrackAniMotumdimid=netcdf.defDim(AniMotumGrpID,'TrackAniMotumdimid',size(data,1));
    else
        TrackAniMotumdimid=netcdf.defDim(AniMotumGrpID,'TrackAniMotumdimid',0);
    end

    AniMotumLat=netcdf.defVar(AniMotumGrpID,'LAT',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumLat,"Description","AniMotum track latitudes")
    netcdf.putAtt(AniMotumGrpID,AniMotumLat,'Units','decimal degrees');
    AniMotumLon=netcdf.defVar(AniMotumGrpID,'LON',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumLon,"Description","AniMotum track longitudes")
    netcdf.putAtt(AniMotumGrpID,AniMotumLon,'Units','decimal degrees');
    AniMotumDate=netcdf.defVar(AniMotumGrpID,'DATE',"NC_STRING",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumDate,"Description","Date and time of AniMotum interpolated location estimate")
    netcdf.putAtt(AniMotumGrpID,AniMotumDate,'Time Zone','UTC');
    AniMotumX=netcdf.defVar(AniMotumGrpID,'X',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumX,"Description","AniMotum interpolated location estimate longitude in km, World Mercator Projection");
    netcdf.putAtt(AniMotumGrpID,AniMotumX,'Units','km');
    AniMotumY=netcdf.defVar(AniMotumGrpID,'Y',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumY,"Description","AniMotum interpolated location estimate latitude in km, World Mercator Projection");
    netcdf.putAtt(AniMotumGrpID,AniMotumY,'Units','km');
    AniMotumXse=netcdf.defVar(AniMotumGrpID,'X_SE',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumXse,"Description","AniMotum interpolated location estimate standard error in longitude");
    netcdf.putAtt(AniMotumGrpID,AniMotumXse,'Units','km');
    AniMotumYse=netcdf.defVar(AniMotumGrpID,'Y_SE',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumYse,"Description","AniMotum interpolated location estimate standard error in latitude");
    netcdf.putAtt(AniMotumGrpID,AniMotumYse,'Units','km');
    AniMotumU=netcdf.defVar(AniMotumGrpID,'U',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumU,"Description","AniMotum estimated velocity in x direction");
    netcdf.putAtt(AniMotumGrpID,AniMotumU,'Units','m/s');
    AniMotumV=netcdf.defVar(AniMotumGrpID,'V',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumV,"Description","AniMotum estimated velocity in y direction");
    netcdf.putAtt(AniMotumGrpID,AniMotumV,'Units','m/s');
    AniMotumUse=netcdf.defVar(AniMotumGrpID,'U_SE',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumUse,"Description","AniMotum estimated standard error of velocity in x direction");
    netcdf.putAtt(AniMotumGrpID,AniMotumUse,'Units','m/s');
    AniMotumVse=netcdf.defVar(AniMotumGrpID,'V_SE',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumVse,"Description","AniMotum estimated standard error of velocity in y direction");
    netcdf.putAtt(AniMotumGrpID,AniMotumVse,'Units','m/s');
    AniMotumS=netcdf.defVar(AniMotumGrpID,'S',"NC_DOUBLE",TrackAniMotumdimid);
    netcdf.putAtt(AniMotumGrpID,AniMotumS,"Description"," AniMotum estimated directionless velocity");
    netcdf.putAtt(AniMotumGrpID,AniMotumS,'Units','m/s');
    netcdf.endDef(ncid);
    if exist('data','var')==1
        netcdf.putVar(AniMotumGrpID,AniMotumDate,string(data.date));
        netcdf.putVar(AniMotumGrpID,AniMotumLat,data.lat);
        netcdf.putVar(AniMotumGrpID,AniMotumLon,data.lon);
        netcdf.putVar(AniMotumGrpID,AniMotumX,data.x);
        netcdf.putVar(AniMotumGrpID,AniMotumY,data.y);
        netcdf.putVar(AniMotumGrpID,AniMotumXse,data.x_se);
        netcdf.putVar(AniMotumGrpID,AniMotumYse,data.y_se);
        netcdf.putVar(AniMotumGrpID,AniMotumU,data.u);
        netcdf.putVar(AniMotumGrpID,AniMotumV,data.v);
        netcdf.putVar(AniMotumGrpID,AniMotumUse,data.u_se);
        netcdf.putVar(AniMotumGrpID,AniMotumVse,data.v_se);
        netcdf.putVar(AniMotumGrpID,AniMotumS,data.s);
    end
    clear data

    netcdf.close(ncid);
    clearvars -except MetaDataAll TagMetaDataAll i folder ForagingSuccessAll
end
toc
