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
% Creates two netCDF files for each animal (one for raw and curated data,
% one for processed data). Both files will contain all of the same global
% attributes so metadata are available in both files.
%
% V.2.2
% 04-Dec-2022 - Changed variable naming to remove redundant identifiers
% 05-Jan-2023 - fixed putAtt and putVar command code
%               Removed Raw and Curated parent groups - only one level of organization now
% 06-Jan-2023 - Additions and adjustments to global attributes
% 17-Mar-2023 - Additions and adjustments to global attributes
% 19-Jul-2023 - Split Level 1/2 and Level 3 file generation into separate scripts; added metadata to
%               global attributes section
% 05-Aug-2023 - Modifications to account for importing data from different
%               formats; added TOPPID-specific import options for a few animals; added
%               annotation; added user-selected (ui) output folder
% 06-Aug-2023 - Added global attribute
% 14-Aug-2023 - Modified global attributes

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
    
    %% Create level 1&2 netCDF file, groups, and global attributes
    %Define filename and set to overwrite pre-existing files
    filename=[folder '\' num2str(TOPPID) '_TrackTDR_RawCurated.nc'];
    ncid=netcdf.create(filename,'CLOBBER');

    %Raw Data Groups
    %RawGrpID=netcdf.defGrp(ncid,'RAW_DATA');
    RawArgosGrpID=netcdf.defGrp(ncid,'RAW_ARGOS');
    RawGPSGrpID=netcdf.defGrp(ncid,'RAW_GPS');
    RawTDR1GrpID=netcdf.defGrp(ncid,'RAW_TDR1');
    RawTDR2GrpID=netcdf.defGrp(ncid,'RAW_TDR2');
    RawTDR3GrpID=netcdf.defGrp(ncid,'RAW_TDR3');

    %Curated Data Groups
    %CuratedGrpID=netcdf.defGrp(ncid,'CURATED_DATA');
    CuratedTrackGrpID=netcdf.defGrp(ncid,'CURATED_LOCATIONS');
    ZOCTDR1GrpID=netcdf.defGrp(ncid,'CLEAN_ZOC_TDR1');
    ZOCTDR2GrpID=netcdf.defGrp(ncid,'CLEAN_ZOC_TDR2');
    ZOCTDR3GrpID=netcdf.defGrp(ncid,'CLEAN_ZOC_TDR3');


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
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Citation_Paper", '');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Citation_Paper_DOI", '');
    netcdf.putAtt(ncid, netcdf.getConstant("NC_GLOBAL"),  "Citation_Dataset", ['Costa, Daniel et al. (2023), ' ...
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

    %% Raw Data Group
    % Argos Raw - RawArgosGrpID
    try
        data=readtable(strcat(ArgosFiles.folder(ArgosFiles.TOPPID==TOPPID),'\',...
            ArgosFiles.filename(ArgosFiles.TOPPID==TOPPID)));
        try
            data(isnat(data.MsgDate),:)=[];
        end
    end

    %Create Argos Raw variables and attributes using size of data file if it exists,
    %otherwise variable size = 0.
    netcdf.reDef(ncid);
    if exist('data','var')==1
        RawArgosdimid=netcdf.defDim(ncid,'RawArgos_rows',size(data,1));
    else
        RawArgosdimid=netcdf.defDim(ncid,'RawArgos_rows',0);
    end
    RawArgosPTT=netcdf.defVar(RawArgosGrpID,'PTT','NC_DOUBLE',RawArgosdimid);
    netcdf.putAtt(RawArgosGrpID,RawArgosPTT,"Description","PTT of satellite tag");
    RawArgosDate=netcdf.defVar(RawArgosGrpID,'DATE','NC_STRING',RawArgosdimid);
    netcdf.putAtt(RawArgosGrpID,RawArgosDate,"Description","Date of Argos-based location estimate");
    RawArgosClass=netcdf.defVar(RawArgosGrpID,'CLASS','NC_STRING',RawArgosdimid);
    netcdf.putAtt(RawArgosGrpID,RawArgosClass,"Description","Location class of Argos-based location estimate");
    RawArgosLat1=netcdf.defVar(RawArgosGrpID,'LAT1','NC_DOUBLE',RawArgosdimid);
    netcdf.putAtt(RawArgosGrpID,RawArgosLat1,"Description","Latitude of Argos-based location estimate");
    netcdf.putAtt(RawArgosGrpID,RawArgosLat1,'Units','decimal degrees');
    RawArgosLon1=netcdf.defVar(RawArgosGrpID,'LON1','NC_DOUBLE',RawArgosdimid);
    netcdf.putAtt(RawArgosGrpID,RawArgosLon1,"Description","Longitude of Argos-based location estimate");
    netcdf.putAtt(RawArgosGrpID,RawArgosLon1,'Units','decimal degrees');
    RawArgosSemiMaj=netcdf.defVar(RawArgosGrpID,'SEMIMAJOR','NC_DOUBLE',RawArgosdimid);
    netcdf.putAtt(RawArgosGrpID,RawArgosSemiMaj,"Description","");
    RawArgosSemiMin=netcdf.defVar(RawArgosGrpID,'SEMIMINOR','NC_DOUBLE',RawArgosdimid);
    netcdf.putAtt(RawArgosGrpID,RawArgosSemiMin,"Description","");
    RawArgosEOR=netcdf.defVar(RawArgosGrpID,'EOR','NC_DOUBLE',RawArgosdimid);
    netcdf.putAtt(RawArgosGrpID,RawArgosEOR,"Description","");
    netcdf.endDef(ncid);

    % If data are available, write to RawArgos variables
    if exist('data','var')==1
        % Identify format of input data and alter import options as needed          
        if strcmp(data.Properties.VariableNames{1},'Prog')==1 && strcmp(data.Properties.VariableNames{2},'PTT')==1
            opts=detectImportOptions(strcat(ArgosFiles.folder(ArgosFiles.TOPPID==TOPPID),'\',...
                ArgosFiles.filename(ArgosFiles.TOPPID==TOPPID)));
            opts = setvartype(opts,{'Class'},'char');
            data=readtable(strcat(ArgosFiles.folder(ArgosFiles.TOPPID==TOPPID),'\',...
                ArgosFiles.filename(ArgosFiles.TOPPID==TOPPID)),opts);
            data(isnat(data.MsgDate),:)=[];
            netcdf.putVar(RawArgosGrpID,RawArgosPTT,data.PTT)
            netcdf.putVar(RawArgosGrpID,RawArgosDate,string(datetime(data.MsgDate+data.MsgTime,"Format","MM/dd/uuuu HH:mm:ss")))
            netcdf.putVar(RawArgosGrpID,RawArgosClass,data.Class)
            netcdf.putVar(RawArgosGrpID,RawArgosLat1,data.Latitude)
            netcdf.putVar(RawArgosGrpID,RawArgosLon1,data.Longitude)
            netcdf.putVar(RawArgosGrpID,RawArgosSemiMaj,data.ErrorSemi_majorAxis)
            netcdf.putVar(RawArgosGrpID,RawArgosSemiMin,data.ErrorSemi_minorAxis)
            netcdf.putVar(RawArgosGrpID,RawArgosEOR,data.ErrorEllipseOrientation)

        %this is SMRU data
        elseif contains(data.Properties.VariableNames{1},'REF','IgnoreCase',true)==1
            netcdf.putVar(RawArgosGrpID,RawArgosPTT,data.PTT)
            netcdf.putVar(RawArgosGrpID,RawArgosDate,string(data.D_DATE))
            netcdf.putVar(RawArgosGrpID,RawArgosClass,data.LQ)
            netcdf.putVar(RawArgosGrpID,RawArgosLat1,data.LAT)
            netcdf.putVar(RawArgosGrpID,RawArgosLon1,data.LON)
            if sum(strcmp(data.Properties.VariableNames,'SEMI_MAJOR_AXIS'))==1
                netcdf.putVar(RawArgosGrpID,RawArgosSemiMaj,data.SEMI_MAJOR_AXIS)
                netcdf.putVar(RawArgosGrpID,RawArgosSemiMin,data.SEMI_MINOR_AXIS)
                netcdf.putVar(RawArgosGrpID,RawArgosEOR,data.ELLIPSE_ORIENTATION)
            end

        elseif strcmp(data.Properties.VariableNames{1},'Program')==1
            netcdf.putVar(RawArgosGrpID,RawArgosPTT,data.PTT)
            netcdf.putVar(RawArgosGrpID,RawArgosDate,string(data.LocationDate))
            netcdf.putVar(RawArgosGrpID,RawArgosClass,data.LocationClass)
            netcdf.putVar(RawArgosGrpID,RawArgosLat1,data.Latitude)
            netcdf.putVar(RawArgosGrpID,RawArgosLon1,data.Longitude)
            netcdf.putVar(RawArgosGrpID,RawArgosSemiMaj,data.Semi_majorAxis)
            netcdf.putVar(RawArgosGrpID,RawArgosSemiMin,data.Semi_minorAxis)
            netcdf.putVar(RawArgosGrpID,RawArgosEOR,data.EllipseOrientation)

        %not really sure what this format this is...ha
        elseif sum(strcmp(data.Properties.VariableNames,'PlatformIDNo'))>0
            netcdf.putVar(RawArgosGrpID,RawArgosPTT,data.PlatformIDNo_)
            netcdf.putVar(RawArgosGrpID,RawArgosDate,string(data.Loc_Date))
            netcdf.putVar(RawArgosGrpID,RawArgosClass,data.Loc_Quality)
            netcdf.putVar(RawArgosGrpID,RawArgosLat1,data.Latitude)
            netcdf.putVar(RawArgosGrpID,RawArgosLon1,data.Longitude)
            netcdf.putVar(RawArgosGrpID,RawArgosSemiMaj,data.Semi_majorAxis)
            netcdf.putVar(RawArgosGrpID,RawArgosSemiMin,data.Semi_minorAxis)
            netcdf.putVar(RawArgosGrpID,RawArgosEOR,data.EllipseOrientation)

        elseif strcmp(data.Properties.VariableNames{1},'DeployID')==1 && strcmp(data.Properties.VariableNames{2},'PTT')==1
            netcdf.putVar(RawArgosGrpID,RawArgosPTT,data.PTT)
            netcdf.putVar(RawArgosGrpID,RawArgosDate,string(data.Date))
            netcdf.putVar(RawArgosGrpID,RawArgosClass,data.LocationQuality)
            netcdf.putVar(RawArgosGrpID,RawArgosLat1,data.Latitude)
            netcdf.putVar(RawArgosGrpID,RawArgosLon1,data.Longitude)
            netcdf.putVar(RawArgosGrpID,RawArgosSemiMaj,data.Semi_majorAxis)
            netcdf.putVar(RawArgosGrpID,RawArgosSemiMin,data.Semi_minorAxis)
            netcdf.putVar(RawArgosGrpID,RawArgosEOR,data.EllipseOrientation)

        elseif strcmp(data.Properties.VariableNames{1},'TOPPID')==1
            opts=detectImportOptions(strcat(ArgosFiles.folder(ArgosFiles.TOPPID==TOPPID),'\',...
                ArgosFiles.filename(ArgosFiles.TOPPID==TOPPID)));
            try
                opts = setvartype(opts,{'Class'},'char');
                data=readtable(strcat(ArgosFiles.folder(ArgosFiles.TOPPID==TOPPID),'\',...
                    ArgosFiles.filename(ArgosFiles.TOPPID==TOPPID)),opts);
                netcdf.putVar(RawArgosGrpID,RawArgosPTT,data.PTT)
                netcdf.putVar(RawArgosGrpID,RawArgosDate,string(datetime(argosdata.JulDate,'ConvertFrom','datenum')))
                netcdf.putVar(RawArgosGrpID,RawArgosClass,data.LocationClass)
                netcdf.putVar(RawArgosGrpID,RawArgosLat1,data.Latitude)
                netcdf.putVar(RawArgosGrpID,RawArgosLon1,data.Longitude)
                netcdf.putVar(RawArgosGrpID,RawArgosSemiMaj,data.SemiMajorAxis)
                netcdf.putVar(RawArgosGrpID,RawArgosSemiMin,data.SemiMinorAxis)
                netcdf.putVar(RawArgosGrpID,RawArgosEOR,data.EllipseOrientation)
            end
            try
                opts = setvartype(opts,{'lq'},'char');
                data=readtable(strcat(ArgosFiles.folder(ArgosFiles.TOPPID==TOPPID),'\',...
                    ArgosFiles.filename(ArgosFiles.TOPPID==TOPPID)),opts);
                netcdf.putVar(RawArgosGrpID,RawArgosPTT,data.pttid)
                netcdf.putVar(RawArgosGrpID,RawArgosDate,data.dates)
                netcdf.putVar(RawArgosGrpID,RawArgosClass,char(data.lq))
                netcdf.putVar(RawArgosGrpID,RawArgosLat1,data.lat1)
                netcdf.putVar(RawArgosGrpID,RawArgosLon1,data.lon1)
                netcdf.putVar(RawArgosGrpID,RawArgosSemiMaj,data.semimajor)
                netcdf.putVar(RawArgosGrpID,RawArgosSemiMin,data.semiminor)
                netcdf.putVar(RawArgosGrpID,RawArgosEOR,data.eor)
            end

        elseif sum(strcmp(data.Properties.VariableNames,'vernacular_name'))>0
            [~,~,~,data.hour,data.min,data.sec]=datevec(data.time);
            netcdf.putVar(RawArgosGrpID,RawArgosPTT,data.PTT)
            netcdf.putVar(RawArgosGrpID,RawArgosDate,string(datetime(data.year,data.month,data.day,data.hour,data.min,data.sec)))
            netcdf.putVar(RawArgosGrpID,RawArgosClass,data.location_quality)
            netcdf.putVar(RawArgosGrpID,RawArgosLat1,data.decimal_latitude)
            netcdf.putVar(RawArgosGrpID,RawArgosLon1,data.decimal_longitude)
            if sum(strcmp(data.Properties.VariableNames,'semimajor'))==1
                netcdf.putVar(RawArgosGrpID,RawArgosSemiMaj,data.semimajor)
                netcdf.putVar(RawArgosGrpID,RawArgosSemiMin,data.semiminor)
                netcdf.putVar(RawArgosGrpID,RawArgosEOR,data.eor)
            end
        end
    end
    clear data

    %GPS Raw - RawGPRGrpID
    try
        data=readtable(strcat(GPSFiles.folder(GPSFiles.TOPPID==TOPPID),'\',...
            GPSFiles.file(GPSFiles.TOPPID==TOPPID)), "HeaderLines",3);
    end

    %Create GPS Raw variables and attributes using size of data file if it exists,
    %otherwise variable size = 0.
    netcdf.reDef(ncid);
    if exist('data','var')==1
        RawGPSdimid=netcdf.defDim(ncid,'RawGPS_rows',size(data,1));
    else
        RawGPSdimid=netcdf.defDim(ncid,'RawGPS_rows',0);
    end
    RawGPSDate=netcdf.defVar(RawGPSGrpID,'DATE','NC_STRING',RawArgosdimid);
    netcdf.putAtt(RawGPSGrpID,RawGPSDate,"Description","Date of GPS-based location estimate");
    RawGPSTime=netcdf.defVar(RawGPSGrpID,'TIME','NC_STRING',RawGPSdimid);
    netcdf.putAtt(RawGPSGrpID,RawGPSTime,"Description","Time of GPS-based location estimate");
    RawGPSSats=netcdf.defVar(RawGPSGrpID,'NUM_SATELLITES','NC_DOUBLE',RawGPSdimid);
    netcdf.putAtt(RawGPSGrpID,RawGPSSats,"Description","Number of GPS satellites detected for location estimate");
    RawGPSLat=netcdf.defVar(RawGPSGrpID,'LAT','NC_DOUBLE',RawGPSdimid);
    netcdf.putAtt(RawGPSGrpID,RawGPSLat,"Description","Latitude of GPS-based location estimate");
    netcdf.putAtt(RawGPSGrpID,RawGPSLat,'Units','decimal degrees');
    RawGPSLon=netcdf.defVar(RawGPSGrpID,'LON','NC_DOUBLE',RawGPSdimid);
    netcdf.putAtt(RawGPSGrpID,RawGPSLon,"Description","Longitude of GPS-based location estimate");
    netcdf.putAtt(RawGPSGrpID,RawGPSLon,'Units','decimal degrees');
    netcdf.endDef(ncid);
   
    % If data are available, write to RawArgos variables
    if exist('data','var')==1
        netcdf.putVar(RawGPSGrpID,RawGPSDate,string(data.Day))
        netcdf.putVar(RawGPSGrpID,RawGPSTime,string(data.Time))
        netcdf.putVar(RawGPSGrpID,RawGPSSats,data.Satellites)
        netcdf.putVar(RawGPSGrpID,RawGPSLat,data.Latitude)
        netcdf.putVar(RawGPSGrpID,RawGPSLon,data.Longitude)
    end
    clear data

    %TDR1 Raw - RawTDR1GrpID
    try
        data=readtable(strcat(TDRRawFiles.folder(TDRRawFiles.TOPPID==TOPPID),'\',...
            TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID)));
        data(isnan(data.Depth),:)=[];
    end
    
    %Create TDR1 Raw variables and attributes using size of data file if it exists,
    %otherwise variable size = 0.
    netcdf.reDef(ncid);
    if exist('data','var')==1
        RawTDR1dimid=netcdf.defDim(ncid,'RawTDR1_rows',size(data,1));
    else
        RawTDR1dimid=netcdf.defDim(ncid,'RawTDR1_rows',0);
    end
    RawTDR1Date=netcdf.defVar(RawTDR1GrpID,'DATE','NC_STRING',RawTDR1dimid);
    RawTDR1Depth=netcdf.defVar(RawTDR1GrpID,'DEPTH','NC_DOUBLE',RawTDR1dimid);
    RawTDR1Temp=netcdf.defVar(RawTDR1GrpID,'EXTERNAL_TEMP','NC_DOUBLE',RawTDR1dimid);
    RawTDR1Light=netcdf.defVar(RawTDR1GrpID,'LIGHT','NC_DOUBLE',RawTDR1dimid);
    netcdf.endDef(ncid);

    %If data are available, write to variables
    if exist('data','var')==1
        %Set up different imports to account for different instrument types/formats
        %Wildlife Computers
        if contains(TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID),'out-Archive')==1
            netcdf.putVar(RawTDR1GrpID,RawTDR1Date,string(data.Time));
            netcdf.putVar(RawTDR1GrpID,RawTDR1Depth,data.Depth);
            m=size(data,2);
        %SMRU
        elseif contains(TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID),'tdr') && ~contains(TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID),'kami','IgnoreCase',true)==1
            netcdf.putVar(RawTDR1GrpID,RawTDR1Date,string(data.Time));
            netcdf.putVar(RawTDR1GrpID,RawTDR1Depth,data.Depth);
        %Little Leonardo Kami
        elseif contains(TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID),'kami','IgnoreCase',true)==1
            netcdf.putVar(RawTDR1GrpID,RawTDR1Date,string(datetime(data.Date+data.Time,'Format','dd-MMM-uuuu HH:mm:ss')));
            netcdf.putVar(RawTDR1GrpID,RawTDR1Depth,data.Depth);
        %Little Leonardo Stroke
        elseif contains(TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID),'stroke','IgnoreCase',true)==1
            netcdf.putVar(RawTDR1GrpID,RawTDR1Date,string(datetime(data.Date+data.Time,'Format','dd-MMM-uuuu HH:mm:ss')));
            netcdf.putVar(RawTDR1GrpID,RawTDR1Depth,data.Depth);
        end
    end
    clear data data_names

    %TDR2 Raw - RawTDR2GrpID
    try
        data=readtable(strcat(TDR2RawFiles.folder(TDR2RawFiles.TOPPID==TOPPID),'\',...
            TDR2RawFiles.filename(TDR2RawFiles.TOPPID==TOPPID)));
            data(isnan(data.Depth),:)=[];
    end

    %Create TDR2 Raw variables and attributes using size of data file if it exists,
    %otherwise variable size = 0.
    netcdf.reDef(ncid);
    if exist('data','var')==1
        RawTDR2dimid=netcdf.defDim(ncid,'RawTDR2_rows',size(data,1));
    else
        RawTDR2dimid=netcdf.defDim(ncid,'RawTDR2_rows',0);
    end
    RawTDR2Date=netcdf.defVar(RawTDR2GrpID,'DATE','NC_STRING',RawTDR2dimid);
    RawTDR2Depth=netcdf.defVar(RawTDR2GrpID,'DEPTH','NC_DOUBLE',RawTDR2dimid);
    RawTDR2Temp=netcdf.defVar(RawTDR2GrpID,'EXTERNAL_TEMP','NC_DOUBLE',RawTDR2dimid);
    RawTDR2Light=netcdf.defVar(RawTDR2GrpID,'LIGHT','NC_DOUBLE',RawTDR2dimid);
    netcdf.endDef(ncid);
    
    %If data are available, write to variables
    if exist('data','var')==1
        %Set up different imports to account for different instrument types/formats
        %Wildlife Computers - may include light and temp
        if contains(TDR2RawFiles.filename(TDR2RawFiles.TOPPID==TOPPID),'out-Archive')==1
            if TOPPID==2013041 || TOPPID==2013043 || TOPPID==2013045 || TOPPID==2013047 || TOPPID==2015006
                netcdf.putVar(RawTDR2GrpID,RawTDR2Date,string(data.Var1));
                netcdf.putVar(RawTDR2GrpID,RawTDR2Depth,data.Var2);
                m=size(data,2);
            else
                netcdf.putVar(RawTDR2GrpID,RawTDR2Date,string(data.Time));
                netcdf.putVar(RawTDR2GrpID,RawTDR2Depth,data.Depth);
                m=size(data,2);
            end
            %SMRU
        elseif contains(TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID),'tdr') && ~contains(TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID),'kami','IgnoreCase',true)==1
            netcdf.putVar(RawTDR2GrpID,RawTDR2Date,string(data.Time));
            netcdf.putVar(RawTDR2GrpID,RawTDR2Depth,data.Depth);
            %Little Leonardo Kami
        elseif contains(TDR2RawFiles.filename(TDR2RawFiles.TOPPID==TOPPID),'kami','IgnoreCase',true)==1
            netcdf.putVar(RawTDR2GrpID,RawTDR2Date,string(datetime(data.Date+data.Time,'Format','dd-MMM-uuuu HH:mm:ss')));
            netcdf.putVar(RawTDR2GrpID,RawTDR2Depth,data.Depth);
            %Little Leonardo Stroke
        elseif contains(TDR2RawFiles.filename(TDR2RawFiles.TOPPID==TOPPID),'stroke','IgnoreCase',true)==1
            netcdf.putVar(RawTDR2GrpID,RawTDR2Date,string(datetime(data.Date+data.Time,'Format','dd-MMM-uuuu HH:mm:ss')));
            netcdf.putVar(RawTDR2GrpID,RawTDR2Depth,data.Depth);
        end
        netcdf.putAtt(RawTDR2GrpID,RawTDR2Temp,'Units','Degrees C');
    end
    clear data

    %TDR3 Raw - RawTDR3GrpID
    try
        data=readtable(strcat(TDR3RawFiles.folder(TDR3RawFiles.TOPPID==TOPPID),'\',...
            TDR3RawFiles.filename(TDR3RawFiles.TOPPID==TOPPID)));
        data(isnan(data.Depth),:)=[];
    end

    %Create TDR3 Raw variables and attributes using size of data file if it exists,
    %otherwise variable size = 0.netcdf.reDef(ncid);
    if exist('data','var')==1
        RawTDR3dimid=netcdf.defDim(ncid,'RawTDR3_rows',size(data,1));
    else
        RawTDR3dimid=netcdf.defDim(ncid,'RawTDR3_rows',0);
    end
    RawTDR3Date=netcdf.defVar(RawTDR3GrpID,'DATE','NC_STRING',RawTDR3dimid);
    RawTDR3Depth=netcdf.defVar(RawTDR3GrpID,'DEPTH','NC_DOUBLE',RawTDR3dimid);
    RawTDR3Temp=netcdf.defVar(RawTDR3GrpID,'EXTERNAL_TEMP','NC_DOUBLE',RawTDR3dimid);
    RawTDR3Light=netcdf.defVar(RawTDR3GrpID,'LIGHT','NC_DOUBLE',RawTDR3dimid);
    netcdf.endDef(ncid);

    %If data are available, write to variables
    if exist('data','var')==1
        %Set up different imports to account for different instrument types/formats
        %Wildlife Computers - may include light and temp
        if contains(TDR3RawFiles.filename(TDR3RawFiles.TOPPID==TOPPID),'out-Archive')==1
            netcdf.putVar(RawTDR3GrpID,RawTDR3Date,string(data.Time));
            netcdf.putVar(RawTDR3GrpID,RawTDR3Depth,data.Depth);
            m=size(data,2);
            %SMRU
        elseif contains(TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID),'tdr') && ~contains(TDRRawFiles.filename(TDRRawFiles.TOPPID==TOPPID),'kami','IgnoreCase',true)==1
            netcdf.putVar(RawTDR3GrpID,RawTDR3Date,string(data.Time));
            netcdf.putVar(RawTDR3GrpID,RawTDR3Depth,data.Depth);
            %Little Leonardo Kami
        elseif contains(TDR3RawFiles.filename(TDR3RawFiles.TOPPID==TOPPID),'kami','IgnoreCase',true)==1
            netcdf.putVar(RawTDR3GrpID,RawTDR3Date,string(datetime(data.Date+data.Time,'Format','dd-MMM-uuuu HH:mm:ss')));
            netcdf.putVar(RawTDR3GrpID,RawTDR3Depth,data.Depth);
            %Little Leonardo Stroke
        elseif contains(TDR3RawFiles.filename(TDR3RawFiles.TOPPID==TOPPID),'stroke','IgnoreCase',true)==1
            netcdf.putVar(RawTDR3GrpID,RawTDR3Date,string(datetime(data.Date+data.Time,'Format','dd-MMM-uuuu HH:mm:ss')));
            netcdf.putVar(RawTDR3GrpID,RawTDR3Depth,data.Depth);
        end
        netcdf.putAtt(RawTDR3GrpID,RawTDR3Temp,'Units','Degrees C');
    end
    clear data

    %% Curated Data Group
    % Track Clean
    try
        opts=detectImportOptions(strcat(TrackCleanFiles.folder(TrackCleanFiles.TOPPID==TOPPID),'\',...
            TrackCleanFiles.filename(TrackCleanFiles.TOPPID==TOPPID)));
        opts = setvartype(opts,{'LocationClass'},'char');
        % modified import options for certain animals
        if TOPPID==2008040
        elseif TOPPID==2016019
            opts = setvartype(opts,'Date','datetime');
            opts = setvaropts(opts,'Date','InputFormat','HH:mm:ss dd-MMM-uuuu', ...
                'DatetimeFormat','dd-MMM-uuuu HH:mm:ss');
        end
        data=readtable(strcat(TrackCleanFiles.folder(TrackCleanFiles.TOPPID==TOPPID),'\',...
            TrackCleanFiles.filename(TrackCleanFiles.TOPPID==TOPPID)),opts);
        data(isnat(data.Date),:)=[];
    end
    
    %Create Track Clear variables and attributes using size of data file if it exists,
    %otherwise variable size = 0.netcdf.reDef(ncid);
    netcdf.reDef(ncid);
    if exist('data','var')==1
        CleanTrackdimid=netcdf.defDim(ncid,'CuratedLocations_rows',size(data,1));
    else
        CleanTrackdimid=netcdf.defDim(ncid,'CuratedLocations_rows',0);
    end
    CleanTrackDate=netcdf.defVar(CuratedTrackGrpID,'DATE','NC_STRING',CleanTrackdimid);
    netcdf.putAtt(CuratedTrackGrpID,CleanTrackDate,"Description","Date and time of Argos-based location estimate");
    CleanTrackLat=netcdf.defVar(CuratedTrackGrpID,'LAT','NC_DOUBLE',CleanTrackdimid);
    netcdf.putAtt(CuratedTrackGrpID,CleanTrackLat,"Description","Latitude of Argos-based location estimate");
    netcdf.putAtt(CuratedTrackGrpID,CleanTrackLat,'Units','decimal degrees');
    CleanTrackLon=netcdf.defVar(CuratedTrackGrpID,'LON','NC_DOUBLE',CleanTrackdimid);
    netcdf.putAtt(CuratedTrackGrpID,CleanTrackLat,"Description","Longitude of Argos-based location estimate");
    netcdf.putAtt(CuratedTrackGrpID,CleanTrackLon,'Units','decimal degrees');
    CleanTrackLocClass=netcdf.defVar(CuratedTrackGrpID,'LOC_CLASS','NC_STRING',CleanTrackdimid);
    netcdf.putAtt(CuratedTrackGrpID,CleanTrackLocClass,"Description","Location class of Argos-based location estimate");
    CleanTrackSMajA=netcdf.defVar(CuratedTrackGrpID,'SEMI_MAJ_AXIS','NC_DOUBLE',CleanTrackdimid);
    netcdf.putAtt(CuratedTrackGrpID,CleanTrackSMajA,"Description","Semi-major axis of Argos-based location estimate’s error ellipse");
    CleanTrackSMinA=netcdf.defVar(CuratedTrackGrpID,'SEMI_MIN_AXIS','NC_DOUBLE',CleanTrackdimid);
    netcdf.putAtt(CuratedTrackGrpID,CleanTrackSMinA,"Description","Semi-minor axis of Argos-based location estimate’s error ellipse");
    CleanTrackEllipseOr=netcdf.defVar(CuratedTrackGrpID,'ELLIPSE_ORIENTATION','NC_DOUBLE',CleanTrackdimid);
    netcdf.putAtt(CuratedTrackGrpID,CleanTrackEllipseOr,"Description","Semi-major axis orientation from north");
    netcdf.endDef(ncid);
    
    %If data are available, write to variables
    if exist('data','var')==1
        netcdf.putVar(CuratedTrackGrpID,CleanTrackDate,string(data.Date));
        netcdf.putVar(CuratedTrackGrpID,CleanTrackLat,data.Latitude);
        netcdf.putVar(CuratedTrackGrpID,CleanTrackLon,data.Longitude);
        netcdf.putVar(CuratedTrackGrpID,CleanTrackLocClass,data.LocationClass);
        netcdf.putVar(CuratedTrackGrpID,CleanTrackSMajA,data.SemiMajorAxis);
        netcdf.putVar(CuratedTrackGrpID,CleanTrackSMinA,data.SemiMinorAxis);
        netcdf.putVar(CuratedTrackGrpID,CleanTrackEllipseOr,data.EllipseOrientation);
    else
    end
    clear data

    %TDR1 ZOC
    try
        data=readmatrix(strcat(TDRZOCFiles.folder(TDRZOCFiles.TOPPID==TOPPID),'\',...
            TDRZOCFiles.filename(TDRZOCFiles.TOPPID==TOPPID)),'HeaderLines',26);
    end

    %Define length dimension and variables for TDR1 ZOC
    netcdf.reDef(ncid);
    if exist('data','var')==1
        ZOCTDR1dimid=netcdf.defDim(ncid,'ZOCTDR1_rows',size(data,1));
    else
        ZOCTDR1dimid=netcdf.defDim(ncid,'ZOCTDR1_rows',0);
    end
    ZOCTDR1Date=netcdf.defVar(ZOCTDR1GrpID,'DATE','NC_DOUBLE',ZOCTDR1dimid);
    netcdf.putAtt(ZOCTDR1GrpID,ZOCTDR1Date,'Description','MATLAB serial date');
    netcdf.putAtt(ZOCTDR1GrpID,ZOCTDR1Date,'Origin','January 0, 0000 in the proleptic ISO calendar');
    ZOCTDR1CorrDepth=netcdf.defVar(ZOCTDR1GrpID,'CORR_DEPTH','NC_DOUBLE',ZOCTDR1dimid);
    netcdf.putAtt(ZOCTDR1GrpID,ZOCTDR1CorrDepth,'Description','Depth corrected for true surface')
    netcdf.putAtt(ZOCTDR1GrpID,ZOCTDR1CorrDepth,'Units','meters')
    ZOCTDR1Depth=netcdf.defVar(ZOCTDR1GrpID,'DEPTH','NC_DOUBLE',ZOCTDR1dimid);
    netcdf.putAtt(ZOCTDR1GrpID,ZOCTDR1Depth,'Description','Uncorrected depth')
    netcdf.putAtt(ZOCTDR1GrpID,ZOCTDR1Depth,'Units','meters')
    netcdf.endDef(ZOCTDR1GrpID);

    %Write in data
    if exist('data','var')==1
        netcdf.putVar(ZOCTDR1GrpID,ZOCTDR1Date,data(:,2));
        netcdf.putVar(ZOCTDR1GrpID,ZOCTDR1CorrDepth,data(:,1));
        netcdf.putVar(ZOCTDR1GrpID,ZOCTDR1Depth,data(:,3));
    else
    end
    clear data

    %TDR2 ZOC
    try
        data=readmatrix(strcat(TDR2ZOCFiles.folder(TDR2ZOCFiles.TOPPID==TOPPID),'\',...
            TDR2ZOCFiles.filename(TDR2ZOCFiles.TOPPID==TOPPID)),'HeaderLines',26);
    end
    %Define length dimension and variables for TDR1 ZOC
    netcdf.reDef(ncid);
    if exist('data','var')==1
        ZOCTDR2dimid=netcdf.defDim(ncid,'ZOCTDR2_rows',size(data,1));
    else
        ZOCTDR2dimid=netcdf.defDim(ncid,'ZOCTDR2_rows',0);
    end
    ZOCTDR2Date=netcdf.defVar(ZOCTDR2GrpID,'DATE','NC_DOUBLE',ZOCTDR2dimid);
    netcdf.putAtt(ZOCTDR2GrpID,ZOCTDR2Date,'Description','MATLAB serial date');
    netcdf.putAtt(ZOCTDR2GrpID,ZOCTDR2Date,'Origin','January 0, 0000 in the proleptic ISO calendar');
    ZOCTDR2CorrDepth=netcdf.defVar(ZOCTDR2GrpID,'CORR_DEPTH','NC_DOUBLE',ZOCTDR2dimid);
    netcdf.putAtt(ZOCTDR2GrpID,ZOCTDR2CorrDepth,'Description','Depth corrected for true surface')
    netcdf.putAtt(ZOCTDR2GrpID,ZOCTDR2CorrDepth,'Units','meters')
    ZOCTDR2Depth=netcdf.defVar(ZOCTDR2GrpID,'DEPTH','NC_DOUBLE',ZOCTDR2dimid);
    netcdf.putAtt(ZOCTDR2GrpID,ZOCTDR2Depth,'Description','Uncorrected depth')
    netcdf.putAtt(ZOCTDR2GrpID,ZOCTDR2Depth,'Units','meters')
    netcdf.endDef(ZOCTDR2GrpID);

    %Write in data
    if exist('data','var')==1
        netcdf.putVar(ZOCTDR2GrpID,ZOCTDR2Date,data(:,2));
        netcdf.putVar(ZOCTDR2GrpID,ZOCTDR2CorrDepth,data(:,1));
        netcdf.putVar(ZOCTDR2GrpID,ZOCTDR2Depth,data(:,3));
    else
    end
    clear data

    %TDR3 ZOC
    try
        data=readmatrix(strcat(TDR3ZOCFiles.folder(TDR3ZOCFiles.TOPPID==TOPPID),'\',...
            TDR3ZOCFiles.filename(TDR3ZOCFiles.TOPPID==TOPPID)),'HeaderLines',26);
    end
    %Define length dimension and variables for TDR1 ZOC
    netcdf.reDef(ncid);
    if exist('data','var')==1
        ZOCTDR3dimid=netcdf.defDim(ncid,'ZOCTDR3_rows',size(data,1));
    else
        ZOCTDR3dimid=netcdf.defDim(ncid,'ZOCTDR3_rows',0);
    end
    ZOCTDR3Date=netcdf.defVar(ZOCTDR3GrpID,'DATE','NC_DOUBLE',ZOCTDR3dimid);
    netcdf.putAtt(ZOCTDR3GrpID,ZOCTDR3Date,'Description','MATLAB serial date');
    netcdf.putAtt(ZOCTDR3GrpID,ZOCTDR3Date,'Origin','January 0, 0000 in the proleptic ISO calendar');
    ZOCTDR3CorrDepth=netcdf.defVar(ZOCTDR3GrpID,'CORR_DEPTH','NC_DOUBLE',ZOCTDR3dimid);
    netcdf.putAtt(ZOCTDR3GrpID,ZOCTDR3CorrDepth,'Description','Depth corrected for true surface')
    netcdf.putAtt(ZOCTDR3GrpID,ZOCTDR3CorrDepth,'Units','meters')
    ZOCTDR3Depth=netcdf.defVar(ZOCTDR3GrpID,'DEPTH','NC_DOUBLE',ZOCTDR3dimid);
    netcdf.putAtt(ZOCTDR3GrpID,ZOCTDR3Depth,'Description','Uncorrected depth')
    netcdf.putAtt(ZOCTDR3GrpID,ZOCTDR3Depth,'Units','meters')
    netcdf.endDef(ZOCTDR3GrpID);

    %Write in data
    if exist('data','var')==1
        netcdf.putVar(ZOCTDR3GrpID,ZOCTDR3Date,data(:,2));
        netcdf.putVar(ZOCTDR3GrpID,ZOCTDR3CorrDepth,data(:,1));
        netcdf.putVar(ZOCTDR3GrpID,ZOCTDR3Depth,data(:,3));
    end
    clear data

    %Close netCDF file when finished
    netcdf.close(ncid);

    clearvars -except MetaDataAll TagMetaDataAll i folder ForagingSuccessAll
end
toc
