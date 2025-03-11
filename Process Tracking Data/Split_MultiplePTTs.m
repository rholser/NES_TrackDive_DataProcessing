%Created by: TRK and RRH
%Created on: 11-Apr-2023
%
% Script loads multi-PTT argos files and splits them into individual tracks, resulting files labeled with 
% TOPPID and PTT (TOPPID_PTT_RawArgos.csv). Input files MUST have a filename ending in RawArgos.csv.
%
% Does not incorporate GPS data.
%
% Update Log:
%   24-Jul-2023 - added location prompt for user to navigate to appropriate folder

clear

%User selects folder where raw data are located and a folder for resulting outputs
infolder=uigetdir('C:\','Data Input Folder');
outfolder=uigetdir('C:\','Prepped File Output Folder');;

%find raw argos files in input folder
cd(infolder);
ArgosFiles=dir('*RawArgos.csv');
load('MetaData.mat');

TOPPIDchecklist=table(MetaDataAll.TOPPID,MetaDataAll.PTTID,'VariableNames',{'TOPPID','PTTID'});

for j=1:size(ArgosFiles,1)
    %% Load file 
    cd(infolder);
    argosdata=readtable(ArgosFiles(j).name,'ReadVariableNames',true);
    %% Identify format of input data
    %this is WC downloaded RawArgos data
    if strcmp(argosdata.Properties.VariableNames{1},'Prog')==1 && strcmp(argosdata.Properties.VariableNames{2},'PTT')==1
        clear pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        opts=detectImportOptions(ArgosFiles(j).name);
        opts = setvartype(opts,{'Class'},'char');
        argosdata=readtable(ArgosFiles(j).name,opts);

        % keep unique time/location combinations only (this is what WC retains in their "Argos.csv"
        % output - but that format currently does not retain error information)
        [C,tokeep]=unique(table(argosdata.MsgDate,argosdata.Latitude,argosdata.Longitude),'rows');
        clear C
        argosdata=argosdata(tokeep,:);
        lat1=argosdata.Latitude;
        argosdata=argosdata(~isnan(lat1),:);
        pttid=argosdata.PTT;
        lon1=argosdata.Longitude;
        lat1=argosdata.Latitude;
        lat2=argosdata.Latitude2;
        lon2=argosdata.Longitude2;
        dates=datetime(argosdata.MsgDate+argosdata.MsgTime,"Format","MM/dd/uuuu HH:mm:ss");
        lq=argosdata.Class;
        semimajor=argosdata.ErrorSemi_majorAxis;
        semiminor=argosdata.ErrorSemi_minorAxis;
        eor=argosdata.ErrorEllipseOrientation;
    end

    %this is SMRU data
    if strcmp(argosdata.Properties.VariableNames{1},'REF')==1 || strcmp(argosdata.Properties.VariableNames{1},'ref')==1
        clear pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        pttid=argosdata.PTT;
        dates=argosdata.D_DATE;
        lat1=argosdata.LAT;
        lon1=argosdata.LON;
        lat2=argosdata.ALT_LAT;
        lon2=argosdata.ALT_LON;
        lq=argosdata.LQ;
        if sum(strcmp(argosdata.Properties.VariableNames,'SEMI_MAJOR_AXIS'))==1
            semimajor=argosdata.SEMI_MAJOR_AXIS;
            semiminor=argosdata.SEMI_MINOR_AXIS;
            eor=argosdata.ELLIPSE_ORIENTATION;
        else
            semimajor=NaN([height(argosdata),1]);
            semiminor=NaN([height(argosdata),1]);
            eor=NaN([height(argosdata),1]);
        end

        lq1=lq;
        lq=cell(length(lq1),1);
        for i=1:length(lq1) %turn SMRU numerical location classes back into letters for foieGras
            if lq1(i)==-1
                lq{i,1}='A';
            elseif lq1(i)==-2
                lq{i,1}='B';
            elseif lq1(i)==-9
                lq{i,1}='Z';
            elseif lq1(i)==1
                lq{i,1}='1';
            elseif lq1(i)==0
                lq{i,1}='0';
            elseif lq1(i)==2
                lq{i,1}='2';
            elseif lq1(i)==3
                lq{i,1}='3';
            elseif isempty(lq1(i))==1
                lq{i,1}=NaN;
            end
        end
    end

    if strcmp(argosdata.Properties.VariableNames{1},'Program')==1
        clear validlocs pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        lat1=argosdata.Latitude;
        validlocs=find(~isnan(lat1));
        argosdata=argosdata(validlocs,:);
        pttid=argosdata.PTT;
        lat1=argosdata.Latitude;
        lon1=argosdata.Longitude;
        lat2=argosdata.LatitudeSolution2;
        lon2=argosdata.LongitudeSolution2;
        dates=argosdata.LocationDate;
        lq=argosdata.LocationClass;
        semimajor=argosdata.Semi_majorAxis;
        semiminor=argosdata.Semi_minorAxis;
        eor=argosdata.EllipseOrientation;

    end

    %not really sure what this format this is...ha
    if sum(strcmp(argosdata.Properties.VariableNames,'PlatformIDNo'))>0
        clear pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        %omit lines without valid locations
        argosdata=argosdata((~isnan(argosdata.Latitude)),:);
        pttid=argosdata.PlatformIDNo_;
        lat1=argosdata.Latitude;
        lon1=argosdata.Longitude;
        lat2=argosdata.Lat_Sol_2;
        lon2=argosdata.Long_2;
        dates=argosdata.Loc_Date;
        lq=argosdata.Loc_Quality;
        semimajor=argosdata.Semi_majorAxis;
        semiminor=argosdata.Semi_minorAxis;
        eor=argosdata.EllipseOrientation;
    end

    if strcmp(argosdata.Properties.VariableNames{1},'DeployID')==1 && strcmp(argosdata.Properties.VariableNames{2},'PTT')==1
        clear pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        %omit lines without valid locations
        argosdata=argosdata((~isnan(argosdata.Latitude)),:);
        pttid=argosdata.PTT;
        lat1=argosdata.Latitude;
        lon1=argosdata.Longitude;
        lat2=argosdata.Latitude2;
        lon2=argosdata.Longitude2;
        dates=datetime(argosdata.Date,'InputFormat','HH:mm:ss dd-MMM-uuuu');
        lq=argosdata.LocationQuality;
        semimajor=NaN(size(argosdata,1));
        semiminor=NaN(size(argosdata,1));
        eor=NaN(size(argosdata,1));
    end

    if strcmp(argosdata.Properties.VariableNames{1},'TOPPID')==1
        clear pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        opts=detectImportOptions(ArgosFiles(j).name); %this likes to turn location classes into non-char which is bad, so reimport the data
        try
            opts = setvartype(opts,{'LocationClass'},'char');
            argosdata=readtable(ArgosFiles(j).name,opts);
            lq=argosdata.LocationClass;
            pttid=argosdata.PTT;
            lat1=argosdata.Latitude;
            lon1=argosdata.Longitude;
            argosdata=argosdata((~isnan(argosdata.Latitude)),:);
            dates=datetime(argosdata.JulDate,'ConvertFrom','datenum');
            semimajor=argosdata.SemiMajorAxis;
            semiminor=argosdata.SemiMinorAxis;
            eor=argosdata.EllipseOrientation;
        end
        try
            opts = setvartype(opts,{'lq'},'char');
            argosdata=readtable(ArgosFiles(j).name,opts);
            lq=argosdata.lq;
            pttid=argosdata.pttid;
            lat1=argosdata.lat1;
            lon1=argosdata.lon1;
            dates=argosdata.dates;
            semimajor=argosdata.semimajor;
            semiminor=argosdata.semiminor;
            eor=argosdata.eor;
        end
    end

    locs1=table(NaN(length(lat1),1),pttid,dates,lat1,lon1,lq,semimajor,semiminor,eor,...
        'VariableNames',{'TOPPID','pttid','dates','lat1','lon1','lq','semimajor','semiminor','eor'});

    uniqueptts=unique(pttid);

    %% Write Argos data from indiviudal PTTs to files for netCDF level 1 data
    for k=1:length(uniqueptts)
        clear pttlocs PTTID TOPPIDs
        pttlocs=locs1(locs1.pttid==uniqueptts(k),:);
        PTTID=uniqueptts(k);
        TOPPIDs=MetaDataAll.TOPPID(MetaDataAll.PTTID==PTTID);
        for l=1:size(TOPPIDs,1)
            GPSFile=dir(strcat('E:\Tracking Diving 2004-2020\GPS Raw\',num2str(TOPPIDs(l)),'*.csv'));
            SealID=MetaDataAll.FieldID(MetaDataAll.TOPPID==TOPPIDs(l));
            StartTime=MetaDataAll.DepartDate(MetaDataAll.TOPPID==TOPPIDs(l));
            if ~isnat(MetaDataAll.ArriveDate(MetaDataAll.TOPPID==TOPPIDs(l)))
                EndTime=MetaDataAll.ArriveDate(MetaDataAll.TOPPID==TOPPIDs(l));
                index=find(pttlocs.dates>=StartTime & pttlocs.dates<=EndTime);
            else
                index=find(pttlocs.dates>=StartTime);
            end

            if size(index,1)>0
                argoslocs=table(repmat(TOPPIDs(l),length(index),1),pttlocs.pttid(index),pttlocs.dates(index),pttlocs.lat1(index),...
                    pttlocs.lon1(index),pttlocs.lq(index),pttlocs.semimajor(index),pttlocs.semiminor(index),pttlocs.eor(index),...
                    'VariableNames',{'TOPPID','PTT','Date','Latitude','Longitude','LocationClass','SemiMajorAxis',...
                    'SemiMinorAxis','EllipseOrientation'});

                if size(GPSFile,1)>0
                    GPSdata=readtable(strcat(GPSFile.folder,'\',GPSFile.name));
                    GPSdata(1,:)=[];
                    GPSdata(end,:)=[];
                    toppidg=NaN(height(GPSdata),1);
                    toppidg(:)=TOPPIDs(l);
                    pttidg=repmat(pttid(1),height(GPSdata),1);
                    try
                        datesg=datetime(GPSdata.Day+GPSdata.Time,'Format','MM/dd/uuuu HH:mm:ss');
                    end
                    try
                        datesg=datetime(GPSdata.Date,'Format','HH:mm:ss.SSSSSS dd-MMM-uuuu');
                    end

                    %datesg=datenum(datesg);
                    if days(abs(mean(datesg(1:10))-mean(pttlocs.dates(index(1):index(10)))))>60 %if the dates of the beginning of the gps data are more than two months away, wrong record
                        continue
                    end
                    lat1g=GPSdata.Latitude;
                    lon1g=GPSdata.Longitude;
                    lc1g=repmat("G",height(GPSdata),1);
                    gpslocs=table(toppidg,pttidg,datesg,lat1g,lon1g,lc1g,NaN(length(lat1g),1),...
                        NaN(length(lat1g),1),NaN(length(lat1g),1),...
                        'VariableNames',{'TOPPID','PTT','Date','Latitude','Longitude','LocationClass','SemiMajorAxis',...
                    'SemiMinorAxis','EllipseOrientation'});
                    clear GPSdata toppidg pttidg datesg lat1g lon1g lc1g
                    
                    %in case there are multiple records in GPS file
                    gpslocs=gpslocs(gpslocs.Date>=StartTime & gpslocs.Date<=EndTime,:);

                    if height(gpslocs)>0
                        tracklocs=[argoslocs;gpslocs];
                    elseif height(argoslocs)==0
                        continue
                    else
                        tracklocs=argoslocs;
                    end
                    tracklocs=sortrows(tracklocs,3);
                    cd(outfolder);
                    writetable(tracklocs,[num2str(TOPPIDs(l)),'_',num2str(uniqueptts(k)) '_argos_raw_pre_aniMotum.csv']);
                else
                    cd(outfolder);

                    writetable(argoslocs,[num2str(TOPPIDs(l)),'_',num2str(uniqueptts(k)) '_argos_raw_pre_aniMotum.csv']);
                end
            end
            clear indexS tartTime EndTime SealID
        end
    end
end