%Script compiles filenames of all data files to be loaded into netCDF 
%files. Creates separate table for each data type for ease of organization.
%TDR order determined based on data quality, completeness, and tag type.
%
% Created by: Rachel Holser (rholser@ucsc.edu) and Arina Favilla (afavilla@ucsc.edu)
% Created on: 24-Aug-2022
% Last modified: 01-Dec-2022
%
%Version 1.1: 
%   Includes both filename and directory location of each file in
%       index spreadsheets.
%   Checks for existence of TOPPID in MetaData before adding files.
%   Changed table preallocation method
%Update Log:
% 31-Dec-2022 - updated for AniMotum instead of FoieGras
% 01-Jan-2023 - Corrected logic for kami file identification
% 05-Apr-2023 - Modified for searching external SSD instead of RRH's
%               desktop
% 17-Apr-2023 - Added other Raw GPS filename endings.
% 24-Jul-2023 - Adds user-selected output folder
% 04-Aug-2023 - Adds user-selevted drive to search through (makes switching
%               computers/drives easier)

clear
load('MetaData.mat')

infolder=uigetdir('C:\','Drive to search');


%% TrackAniMotumFiles: TOPPID, foieGras filename

%Preallocate space and format table
TrackAniMotumFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with aniMotum_crw in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\**\*_aniMotum_crw.csv'));
for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        TrackAniMotumFiles.TOPPID(i)=TOPPID;
        TrackAniMotumFiles.filename(i)=files(i).name;
        TrackAniMotumFiles.folder(i)=files(i).folder;
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TrackAniMotumFiles(TrackAniMotumFiles.TOPPID==0,:)=[];
TrackAniMotumFiles=sortrows(TrackAniMotumFiles);
clear files

%% ArgosFiles: TOPPID, raw argos filename

%Preallocate space and format table
ArgosFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with RawArgos in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\**\*RawArgos.csv'));
for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        ArgosFiles.TOPPID(i)=TOPPID;
        ArgosFiles.filename(i)=files(i).name;
        ArgosFiles.folder(i)=files(i).folder;
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
ArgosFiles(ArgosFiles.TOPPID==0,:)=[];
ArgosFiles=sortrows(ArgosFiles);
clear files

%% GPSFiles: TOPPID, raw GPS filename

%Preallocate space and format table
GPSFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with FastGPS in filename
files1=dir(strcat(infolder,'\Tracking Diving 2004-2020\**\*FastGPS.csv'));
files2=dir(strcat(infolder,'\Tracking Diving 2004-2020\**\*Locations.csv'));
files3=dir(strcat(infolder,'\Tracking Diving 2004-2020\**\*GPSRaw.csv'));
files=[files1; files2; files3];

for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        GPSFiles.TOPPID(i)=TOPPID;
        GPSFiles.filename(i)=files(i).name;
        GPSFiles.folder(i)=files(i).folder;
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
GPSFiles(GPSFiles.TOPPID==0,:)=[];
GPSFiles=sortrows(GPSFiles);
clear files

%% TrackCleanFiles: TOPPID, clean pre-processed track files

%Preallocate space and format table
TrackCleanFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with pre_aniMotum in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\**\*pre_aniMotum.csv'));
for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        TrackCleanFiles.TOPPID(i)=TOPPID;
        TrackCleanFiles.filename(i)=files(i).name;
        TrackCleanFiles.folder(i)=files(i).folder;
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TrackCleanFiles(TrackCleanFiles.TOPPID==0,:)=[];
TrackCleanFiles=sortrows(TrackCleanFiles);
clear files
%% TDRRawFiles: TOPPID, raw data filename

%Preallocate space and format table
TDRRawFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with Archive in filename
files1=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*Archive.csv'));
%Find all files with tdr_raw in filename
files2=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_tdr_raw.csv'));
%Find all files with Kami_tdr in filename
files3=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_Kami_tdr.csv'));
%Find all files with Stroke_tdr in filename
files4=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_Stroke_tdr.csv'));
files=[files1; files2; files3; files4];
for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDRRawFiles.filename(i)=files(i).name;    
            TDRRawFiles.TOPPID(i)=TOPPID;
            TDRRawFiles.folder(i)=files(i).folder;  
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDRRawFiles(TDRRawFiles.TOPPID==0,:)=[];
TDRRawFiles=sortrows(TDRRawFiles);
clear files files1 files2 files3 files4

%% TDRCleanFiles: TOPPID, pre-processed filename (*_DAprep_full.csv)

%Preallocate space and format table
TDRCleanFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _full in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_full.csv'));
for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDRCleanFiles.filename(i)=files(i).name;    
            TDRCleanFiles.folder(i)=files(i).folder;    
            TDRCleanFiles.TOPPID(i)=TOPPID;
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDRCleanFiles(TDRCleanFiles.TOPPID==0,:)=[];
TDRCleanFiles=sortrows(TDRCleanFiles);
clear files

%% TDRZOCFiles: TOPPID, ZOC output filename (*_full_iknos_rawzoc.csv)

%Preallocate space and format table
TDRZOCFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _full_iknos_rawzoc_data in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_full_iknos_rawzoc_data.csv'));
for i=1:size(files,1)
   %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDRZOCFiles.filename(i)=files(i).name;
            TDRZOCFiles.folder(i)=files(i).folder;
            TDRZOCFiles.TOPPID(i)=TOPPID;
        end
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDRZOCFiles(TDRZOCFiles.TOPPID==0,:)=[];
TDRZOCFiles=sortrows(TDRZOCFiles);
clear files

%% TDRDiveStatFiles: TOPPID, Dive Stat filename (_full_iknos_DiveStat.csv)

%Preallocate space and format table
TDRDiveStatFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _full_iknos_DiveStat in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_full_iknos_DiveStat.csv'));
for i=1:size(files,1)
   %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDRDiveStatFiles.filename(i)=files(i).name;    
            TDRDiveStatFiles.folder(i)=files(i).folder;    
            TDRDiveStatFiles.TOPPID(i)=TOPPID;
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDRDiveStatFiles(TDRDiveStatFiles.TOPPID==0,:)=[];
TDRDiveStatFiles=sortrows(TDRDiveStatFiles);
clear files

%% TDRSubDiveStatFiles: TOPPID, Dive Stat filename (_SubSample_iknos_DiveStat.csv)

%Preallocate space and format table
TDRSubDiveStatFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _SubSample_iknos_DiveStat in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_SubSample_iknos_DiveStat.csv'));
for i=1:size(files,1)
   %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR1Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDRSubDiveStatFiles.filename(i)=files(i).name;    
            TDRSubDiveStatFiles.folder(i)=files(i).folder;    
            TDRSubDiveStatFiles.TOPPID(i)=TOPPID;
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDRSubDiveStatFiles(TDRSubDiveStatFiles.TOPPID==0,:)=[];
TDRSubDiveStatFiles=sortrows(TDRSubDiveStatFiles);
clear files

%% TDR2RawFiles: TOPPID, raw data filename

%Preallocate space and format table
TDR2RawFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with Archive in filename
files1=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*Archive.csv'));
%Find all files with tdr_raw in filename
files2=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_tdr_raw.csv'));
%Find all files with Kami_tdr in filename
files3=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_Kami_tdr.csv'));
%Find all files with Stroke_tdr in filename
files4=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_Stroke_tdr.csv'));
files=[files1; files2; files3; files4];
for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR2ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2Type(TagMetaDataAll.TOPPID==TOPPID)))  
            TDR2RawFiles.filename(i)=files(i).name;    
            TDR2RawFiles.TOPPID(i)=TOPPID;
            TDR2RawFiles.folder(i)=files(i).folder;  
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR2RawFiles(TDR2RawFiles.TOPPID==0,:)=[];
TDR2RawFiles=sortrows(TDR2RawFiles);
clear files files1 files2 files3 files4

%% TDR2CleanFiles: TOPPID, pre-processed filename (*_DAprep_full.csv)

%Preallocate space and format table
TDR2CleanFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _full in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_full.csv'));
for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDR2CleanFiles.filename(i)=files(i).name;    
            TDR2CleanFiles.folder(i)=files(i).folder;    
            TDR2CleanFiles.TOPPID(i)=TOPPID;
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR2CleanFiles(TDR2CleanFiles.TOPPID==0,:)=[];
TDR2CleanFiles=sortrows(TDR2CleanFiles);
clear files

%% TDR2ZOCFiles: TOPPID, ZOC output filename (*_full_iknos_rawzoc.csv)

%Preallocate space and format table
TDR2ZOCFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _full_iknos_rawzoc_data in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_full_iknos_rawzoc_data.csv'));
for i=1:size(files,1)
   %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDR2ZOCFiles.filename(i)=files(i).name;
            TDR2ZOCFiles.folder(i)=files(i).folder;
            TDR2ZOCFiles.TOPPID(i)=TOPPID;
        end
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR2ZOCFiles(TDR2ZOCFiles.TOPPID==0,:)=[];
TDR2ZOCFiles=sortrows(TDR2ZOCFiles);
clear files

%% TDR2DiveStatFiles: TOPPID, Dive Stat filename (_full_iknos_DiveStat_QC.csv)

%Preallocate space and format table
TDR2DiveStatFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});


%Find all files with _full_iknos_DiveStat in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_full_iknos_DiveStat.csv'));
for i=1:size(files,1)
   %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDR2DiveStatFiles.filename(i)=files(i).name;    
            TDR2DiveStatFiles.folder(i)=files(i).folder;    
            TDR2DiveStatFiles.TOPPID(i)=TOPPID;
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR2DiveStatFiles(TDR2DiveStatFiles.TOPPID==0,:)=[];
TDR2DiveStatFiles=sortrows(TDR2DiveStatFiles);
clear files

%% TDR2SubDiveStatFiles: TOPPID, Dive Stat filename (_SubSample_iknos_DiveStat_QC.csv)

%Preallocate space and format table
TDR2SubDiveStatFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _SubSample_iknos_DiveStat in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_SubSample_iknos_DiveStat.csv'));
for i=1:size(files,1)
   %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR2Type(TagMetaDataAll.TOPPID==TOPPID)))  
            TDR2SubDiveStatFiles.filename(i)=files(i).name;    
            TDR2SubDiveStatFiles.folder(i)=files(i).folder;    
            TDR2SubDiveStatFiles.TOPPID(i)=TOPPID;
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR2SubDiveStatFiles(TDR2SubDiveStatFiles.TOPPID==0,:)=[];
TDR2SubDiveStatFiles=sortrows(TDR2SubDiveStatFiles);
clear files

%% TDR3RawFiles: TOPPID, raw data filename

%Preallocate space and format table
TDR3RawFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with Archive in filename
files1=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*Archive.csv'));
%Find all files with tdr_raw in filename
files2=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_tdr_raw.csv'));
%Find all files with Kami_tdr in filename
files3=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_Kami_tdr.csv'));
%Find all files with Stroke_tdr in filename
files4=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_Stroke_tdr.csv'));
files=[files1; files2; files3; files4];
for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDR3RawFiles.filename(i)=files(i).name;    
            TDR3RawFiles.TOPPID(i)=TOPPID;
            TDR3RawFiles.folder(i)=files(i).folder;  
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR3RawFiles(TDR3RawFiles.TOPPID==0,:)=[];
TDR3RawFiles=sortrows(TDR3RawFiles);
clear files files1 files2 files3 files4

%% TDR3CleanFiles: TOPPID, pre-processed filename (*_DAprep_full.csv)

%Preallocate space and format table
TDR3CleanFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _full in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_full.csv'));
for i=1:size(files,1)
    %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDR3CleanFiles.filename(i)=files(i).name;    
            TDR3CleanFiles.folder(i)=files(i).folder;    
            TDR3CleanFiles.TOPPID(i)=TOPPID;
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR3CleanFiles(TDR3CleanFiles.TOPPID==0,:)=[];
TDR3CleanFiles=sortrows(TDR3CleanFiles);
clear files

%% TDR3ZOCFiles: TOPPID, ZOC output filename (*_full_iknos_rawzoc.csv)

%Preallocate space and format table
TDR3ZOCFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _full_iknos_rawzoc_data in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_full_iknos_rawzoc_data.csv'));
for i=1:size(files,1)
   %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDR3ZOCFiles.filename(i)=files(i).name;
            TDR3ZOCFiles.folder(i)=files(i).folder;
            TDR3ZOCFiles.TOPPID(i)=TOPPID;
        end
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR3ZOCFiles(TDR3ZOCFiles.TOPPID==0,:)=[];
TDR3ZOCFiles=sortrows(TDR3ZOCFiles);
clear files

%% TDR3DiveStatFiles: TOPPID, Dive Stat filename (_full_iknos_DiveStat_QC.csv)

%Preallocate space and format table
TDR3DiveStatFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});


%Find all files with _full_iknos_DiveStat in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_full_iknos_DiveStat.csv'));
for i=1:size(files,1)
   %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3Type(TagMetaDataAll.TOPPID==TOPPID))) 
            TDR3DiveStatFiles.filename(i)=files(i).name;    
            TDR3DiveStatFiles.folder(i)=files(i).folder;    
            TDR3DiveStatFiles.TOPPID(i)=TOPPID;
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR3DiveStatFiles(TDR3DiveStatFiles.TOPPID==0,:)=[];
TDR3DiveStatFiles=sortrows(TDR3DiveStatFiles);
clear files

%% TDR3SubDiveStatFiles: TOPPID, Dive Stat filename (_SubSample_iknos_DiveStat_QC.csv)

%Preallocate space and format table
TDR3SubDiveStatFiles=table('Size',[size(MetaDataAll,1),3],'VariableNames',{'TOPPID','filename','folder'},...
    'VariableTypes',{'double','string','string'});

%Find all files with _SubSample_iknos_DiveStat in filename
files=dir(strcat(infolder,'\Tracking Diving 2004-2020\TDRs\**\*_SubSample_iknos_DiveStat.csv'));
for i=1:size(files,1)
   %Pull TOPPID directly from filename
    TOPPID=str2double(strtok(files(i).name,'_'));
    if sum(TagMetaDataAll.TOPPID==TOPPID)>0
        %Check if file is for TDR1ID in TagMetaDataAll
        if ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3ID(TagMetaDataAll.TOPPID==TOPPID))) ||...
                ~isempty(strfind(files(i).name,TagMetaDataAll.TDR3Type(TagMetaDataAll.TOPPID==TOPPID)))  
            TDR3SubDiveStatFiles.filename(i)=files(i).name;    
            TDR3SubDiveStatFiles.folder(i)=files(i).folder;    
            TDR3SubDiveStatFiles.TOPPID(i)=TOPPID;
        end 
    end
    clear TOPPID
end

%Remove extra rows in table and sort by TOPPID (ascending order)
TDR3SubDiveStatFiles(TDR3SubDiveStatFiles.TOPPID==0,:)=[];
TDR3SubDiveStatFiles=sortrows(TDR3SubDiveStatFiles);
clear files

outfolder=uigetdir('C:\','File Output Folder');
cd(outfolder);

save('All_Filenames.mat','TrackAniMotumFiles','ArgosFiles','GPSFiles','TrackCleanFiles', 'TDRRawFiles',...
    'TDRCleanFiles','TDRZOCFiles','TDRDiveStatFiles','TDRSubDiveStatFiles','TDR2RawFiles','TDR2CleanFiles',...
    'TDR2ZOCFiles','TDR2DiveStatFiles','TDR2SubDiveStatFiles','TDR3RawFiles','TDR3CleanFiles','TDR3ZOCFiles',...
    'TDR3DiveStatFiles','TDR3SubDiveStatFiles');
