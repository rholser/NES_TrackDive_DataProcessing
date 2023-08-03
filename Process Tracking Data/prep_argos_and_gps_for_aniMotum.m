% Created by: T.Keates (tkeates@ucsc.edu)
% Created on: June 2018
%
% Create aniMotum input from raw Argos and solved GPS data
%
% Incorporates Argos semi major and semi minor axes and ellipse orientations where available (Kalman filtered data)
%
% Identifies several different input data formats, however, there may well be more in the future...
%
% Input data:
    % MetaData.mat (includes startstop)
    % All_Filenames.mat (includes path and filename for all file types, with TOPPID as unique
    % identifier)
    % RawArgos and RawGPS files need to be prepared ahead of time (split, named with TOPPID and PTT,
    % and correctly constrained to trip start and end. This code no longer checks for matching dates
    % between Argos and GPS data - that needs to be done by checking against MetaData prior to combining 
    % (some Argos records don't start until mid-trip, directly comparing was causing trips to be skipped).
%
% Output data:
  % One csv per track with:
    % TOPPID
    % pttid
    % JulDate
    % Date
    % Latitude
    % Longitude
    % LocationClass
    % SemiMajorAxis
    % SemiMinorAxis
    % EllipseOrientation
%    
%Things this code does:
%
%Truncates location data based on startstop.csv file (i.e. locations before seal left shore and after she 
% returned are omitted). If seal returned home but the tag stopped recording locations, an end point is assigned 
% IF the data gap is not more than 5 days (to avoid drawing a meaningless straight line back home). 
% Adjust this if desired.
%    
%Creates "TOPPIDchecklist" to keep track of the tracks run. This also classifies into: 
% "Very Little Data" (<10 locations), 
% "Incomplete, Did Not Return Home" (tag not recovered), 
% "Incomplete, Returned Home" (tag recovered, but more than 10 days of data on return missing), or 
% "Complete" (seal returned, data gap if any <10 days).
% Depending on your needs, adjust these criteria. Visual QC always recommended - the aniMotum R code makes 
% you some maps.

% Version 2.0:
% Update Log:
%   08-Apr-2023 - RRH - Changed file names to aniMotum, updated dates to use datetime instead of datenum
%   11-Apr-2023 - RRH - Changing to use AllFilenames.mat to find files
%   17-Jun-2023 - RRH - Incorporate multiple GPS filenames/types (GPS from mat files)

clear 
%cd 'E:/Tracking Diving 2004-2020/Argos Raw'
%ArgosFiles=dir('*RawArgos.csv');
load('MetaData.mat');

%Using AllFilename.mat structure and writes files to same location that raw files are found.
load('All_Filenames.mat')
TOPPIDchecklist=table(MetaDataAll.TOPPID,MetaDataAll.PTTID,'VariableNames',{'TOPPID','PTTID'});

for j=1:size(ArgosFiles,1)
    %% Load file from All_Filenames: ArgosFiles
    argosdata=readtable(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j)),'ReadVariableNames',true);
    toppid=ArgosFiles.TOPPID(j);
    PTTID1=MetaDataAll.PTTID(MetaDataAll.TOPPID==toppid);
    %% Identify format of input data
    %this is WC downloaded RawArgos data
    if strcmp(argosdata.Properties.VariableNames{1},'Prog')==1 && strcmp(argosdata.Properties.VariableNames{2},'PTT')==1
        clear pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        opts=detectImportOptions(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j)));
        opts = setvartype(opts,{'Class'},'char');
        argosdata=readtable(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j)),opts);

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

    %this is WC downloaded RawArgos data from Solar Tags
    if strcmp(argosdata.Properties.VariableNames{1},'PTT')==1 && strcmp(argosdata.Properties.VariableNames{2},'Platform')==1
        clear pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        opts=detectImportOptions(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j)));
        %opts = setvartype(opts,{'Class'},'char');
        argosdata=readtable(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j)),opts);

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
        lat2=argosdata.Lat_Sol_1;
        lon2=argosdata.Long_1;
        dates=datetime(argosdata.MsgDate,"Format","MM/dd/uuuu HH:mm:ss");
        lq=argosdata.Loc_Quality;
        semimajor=argosdata.Semi_majorAxis;
        semiminor=argosdata.Semi_minorAxis;
        eor=argosdata.EllipseOrientation;
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

        % lq1=lq;
        % lq=cell(length(lq1),1);
        % for i=1:length(lq1) %turn SMRU numerical location classes back into letters for foieGras
        %     if lq1(i)==-1
        %         lq{i,1}='A';
        %     elseif lq1(i)==-2
        %         lq{i,1}='B';
        %     elseif lq1(i)==-9
        %         lq{i,1}='Z';
        %     elseif lq1(i)==1
        %         lq{i,1}='1';
        %     elseif lq1(i)==0
        %         lq{i,1}='0';
        %     elseif lq1(i)==2
        %         lq{i,1}='2';
        %     elseif lq1(i)==3
        %         lq{i,1}='3';
        %     elseif isempty(lq1(i))==1
        %         lq{i,1}=NaN;
        %     end
        % end
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
    if strcmp(argosdata.Properties.VariableNames{1},'DeployID')==1
        clear pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        %omit lines without valid locations
        argosdata=argosdata((~isnan(argosdata.Latitude)),:);
        semimajor=NaN(size(argosdata,1),1);
        semiminor=NaN(size(argosdata,1),1);
        eor=NaN(size(argosdata,1),1);
        try
            pttid=argosdata.PlatformIDNo_;
            lat1=argosdata.Latitude;
            lon1=argosdata.Longitude;
            dates=argosdata.Loc_Date;
            lq=argosdata.Loc_Quality;
            semimajor=argosdata.Semi_majorAxis;
            semiminor=argosdata.Semi_minorAxis;
            eor=argosdata.EllipseOrientation;
        end
        try
            pttid=argosdata.Ptt;
            lat1=argosdata.Latitude;
            lon1=argosdata.Longitude;
            dates=datetime(argosdata.Date,'Format','HH:mm:ss dd-MMM-uuuu');
            lq=argosdata.LocationQuality;
        end
        try
            pttid=argosdata.PTT;
            dates=datetime(argosdata.Date,'InputFormat','HH:mm:ss dd-MMM-uuuu');
            lq=argosdata.LocationQuality;
            lat1=argosdata.Latitude;
            lon1=argosdata.Longitude;
        end
    end
    %not really sure what this format this is either... double ha
    if strcmp(argosdata.Properties.VariableNames{1},'vernacular_name')==1
        opts=detectImportOptions(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j)));
        opts = setvartype(opts,{'location_quality'},'char');
        argosdata=readtable(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j)),opts);        

        clear validlocs pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        lat1=argosdata.decimal_latitude;
        validlocs=find(~isnan(lat1));
        argosdata=argosdata(validlocs,:);
        pttid=argosdata.PTT;
        lat1=argosdata.decimal_latitude;
        lon1=argosdata.decimal_longitude;
        % lat2=argosdata.LatitudeSolution2;
        % lon2=argosdata.LongitudeSolution2;
        dates=datetime(argosdata.year,argosdata.month,argosdata.day,0,0,0)+argosdata.time;
        lq=argosdata.location_quality;
        semimajor=NaN(size(validlocs,1),1);
        semiminor=NaN(size(validlocs,1),1);
        eor=NaN(size(validlocs,1),1);
    end

    %this is argos data pulled from existing matfiles
    if strcmp(argosdata.Properties.VariableNames{1},'TOPPID')==1
        clear pttid lat1 lon1 lat2 lon2 dates lq semimajor semiminor eor
        opts=detectImportOptions(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j))); %this likes to turn location classes into non-char which is bad, so reimport the data
        try
            opts = setvartype(opts,{'LocationClass'},'char');
            argosdata=readtable(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j)),opts);
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
            argosdata=readtable(strcat(ArgosFiles.folder(j),'\',ArgosFiles.filename(j)),opts);
            lq=argosdata.lq;
            pttid=argosdata.pttid;
            lat1=argosdata.lat1;
            lon1=argosdata.lon1;
            dates=argosdata.dates;
            semimajor=argosdata.semimajor;
            semiminor=argosdata.semiminor;
            eor=argosdata.eor;
        end
        %omit lines without valid locations
    end

    locs1=table(NaN(length(lat1),1),pttid,dates,lat1,lon1,lq,semimajor,semiminor,eor,...
        'VariableNames',{'TOPPID','pttid','dates','lat1','lon1','lq','semimajor','semiminor','eor'});
    uniqueptts=unique(pttid);

    %add GPS data if exists for that TOPPID
    for k=1:length(uniqueptts)
        PTTID=uniqueptts(k);            
        gpslocs=table();

        if ~isempty(GPSFiles(GPSFiles.TOPPID==toppid,:))
            GPSfile=strcat(GPSFiles.folder(GPSFiles.TOPPID==toppid),'\',GPSFiles.filename(GPSFiles.TOPPID==toppid));
            if contains(GPSFiles.filename(GPSFiles.TOPPID==toppid),'Locations')
                %this is Wildlife Computers downloaded GPS
                GPSdata=readtable(GPSfile);
                if size(GPSdata,1)>5
                    toppidg=repmat(toppid,height(GPSdata),1);
                    pttidg=repmat(pttid(1),height(GPSdata),1);
                    try
                        datesg=datetime(GPSdata.Date,'Format','MM/dd/uuuu HH:mm:ss');
                    end
                    try
                        datesg=GPSdata.Day+GPSdata.Time;
                    end
                    %datesg=datenum(datesg);
                    % if abs(mean(datesg(1:10))-mean(locs1.dates(1:10)))>60 %if the dates of the beginning of the gps data are more than two months away, wrong record
                    %     continue
                    % end
                    lat1g=GPSdata.Latitude;
                    lon1g=GPSdata.Longitude;
                    lc1g=repmat("G",height(GPSdata),1);
                    gpslocs=table(toppidg,pttidg,datesg,lat1g,lon1g,lc1g,NaN(length(lat1g),1),...
                        NaN(length(lat1g),1),NaN(length(lat1g),1),...
                        'VariableNames',{'TOPPID','pttid','dates','lat1','lon1','lq','semimajor','semiminor','eor'});
                    clear GPSdata toppidg pttidg datesg lat1g lon1g lc1g
                end

            elseif contains(GPSFiles.filename(GPSFiles.TOPPID==toppid),'GPSRaw')
                %this is GPS data from mat files
                GPSdata=readtable(GPSfile);
                %if fewer than five lines of GPS data, ignore
                if size(GPSdata,1)>5
                    %Could be one of two formats (different header rows)
                    if strcmp(GPSdata.Properties.VariableNames{1},'TOPPID')==1
                        datesg=datetime(GPSdata.dates);
                        % if abs(mean(datesg(1:10))-mean(locs1.dates(1:10)))>60 %if the dates of the beginning of the gps data are more than two months away, wrong record
                        %     continue
                        % end
                        toppidg=GPSdata.TOPPID;
                        pttidg=repmat(pttid(1),height(GPSdata),1);
                        lat1g=GPSdata.lat1;
                        lon1g=GPSdata.lon1;
                        lc1g=GPSdata.lq;
                    else
                        GPSdata.Properties.VariableNames(1)={'PTTID'};
                        GPSdata.Properties.VariableNames(2)={'JulDate'};
                        GPSdata.Properties.VariableNames(9)={'Lat'};
                        GPSdata.Properties.VariableNames(10)={'Lon'};
                        toppidg=repmat(toppid,height(GPSdata),1);
                        pttidg=repmat(pttid(1),height(GPSdata),1);
                        datesg=datetime(GPSdata.JulDate,'ConvertFrom','excel');
                        %datesg=datenum(datesg);
                        % if abs(mean(datesg(1:10))-mean(locs1.dates(1:10)))>60 %if the dates of the beginning of the gps data are more than two months away, wrong record
                        %     continue
                        % end
                        lat1g=GPSdata.Lat;
                        lon1g=GPSdata.Lon;
                        lc1g=repmat("G",height(GPSdata),1);
                    end
                    gpslocs=table(toppidg,pttidg,datesg,lat1g,lon1g,lc1g,NaN(length(lat1g),1),...
                        NaN(length(lat1g),1),NaN(length(lat1g),1),...
                        'VariableNames',{'TOPPID','pttid','dates','lat1','lon1','lq','semimajor','semiminor','eor'});
                    clear GPSdata toppidg pttidg datesg lat1g lon1g lc1g

                    % else
                    %     %This is SMRU
                    %     SMRU_GPS=readtable(GPSfile);
                    %     if sum(ismember(unique(SMRU_GPS.PTT),PTTID))>0
                    %         GPSdata=SMRU_GPS(SMRU_GPS.PTT==PTTID,:);
                    %         toppidg=repmat(toppid,height(GPSdata),1);
                    %         pttidg=repmat(PTTID,height(GPSdata),1);
                    %         datesg=GPSdata.D_DATE;
                    %         lat1g=GPSdata.LAT;
                    %         lon1g=GPSdata.LON;
                    %         lc1g=repmat("G",height(GPSdata),1);
                    %         gpslocs=table(toppidg,pttidg,datesg,lat1g,lon1g,lc1g,NaN(length(lat1g),1),...
                    %             NaN(length(lat1g),1),NaN(length(lat1g),1),...
                    %             'VariableNames',{'TOPPID','pttid','dates','lat1','lon1','lq','semimajor','semiminor','eor'});
                end
            end
        end

        %merge argos and gps from this ptt and sort by time
        argoslocs=locs1(locs1.pttid==PTTID,:);
        if height(gpslocs)>0
            locs2=[argoslocs;gpslocs];
        elseif height(argoslocs)==0
            continue
        else
            locs2=argoslocs;
        end
        locs=sortrows(locs2,3);
        clear locs2 argoslocs gpslocs

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %use first several days of data to find deployment metadata, because sometimes a tag test (which
        %shouldn't be more than a few days) happens a long time defore a deployment
        

        %Criterion here: data start needs to be within 30 days of departure
        daysofdata=unique(dateshift(locs.dates,'start','day'));
        %are there multiple deployments in this file?
        deltatimes=diff(daysofdata);
        cuts=find(deltatimes>20);
        %add first row of data as a "cut" in case the deployment starts right away (no time diff).
        % Add 1 to remaining ones to get beginning of next chunk.
        cuts=[1;cuts+1];
        q=1;
        trackindex=[];
        for m=1:length(cuts)
            if toppid==2013048
                tindex1=find(MetaDataAll.TOPPID==toppid);
                if ~isempty(tindex1)
                    trackindex(q,1)=tindex1;
                    q=q+1;
                end
            else
                tindex1=find(MetaDataAll.PTTID==PTTID & abs(MetaDataAll.DepartDate-daysofdata(cuts(m)))<=30);
                if ~isempty(tindex1)
                    trackindex(q,1)=tindex1;
                    q=q+1;
                end
            end
        end

        if isempty(trackindex)==1 && ~isempty(MetaDataAll.PTTID==PTTID)
            fprintf('Error: No matching record in MetaDataAll file found. Time stamps could be off, could be a translocation...')
            continue
        end

        %for each track in the data (should hopefully be one):
        for p=1:length(trackindex)
            tindex=trackindex(p);
            TOPPID=MetaDataAll.TOPPID(tindex);
            SealID=MetaDataAll.FieldID(tindex);

            %Get start and end time from MetaDataAll
            StartTime=MetaDataAll.DepartDate(tindex);
            EndTime=MetaDataAll.ArriveDate(tindex);
            %truncate tracks according to startstop dates
            if isnat(EndTime)
                index=find(locs.pttid==PTTID & locs.dates>=StartTime);
            else
                index=find(locs.pttid==PTTID & locs.dates>=StartTime & locs.dates<=EndTime);
            end

            if isempty(index)
                continue
            end

            tracklocs=table(repmat(TOPPID,length(index),1),locs.pttid(index),locs.dates(index),locs.lat1(index),locs.lon1(index),locs.lq(index),locs.semimajor(index),locs.semiminor(index),locs.eor(index),...
                'VariableNames',{'TOPPID','PTT','Date','Latitude','Longitude','LocationClass','SemiMajorAxis','SemiMinorAxis','EllipseOrientation'});

            %determine if this track is complete by comparing last location to end
            %location, more than 10 days = incomplete
            row=find(TOPPIDchecklist.TOPPID==TOPPID);
            TOPPIDchecklist.Status(row)="run";
            if height(tracklocs)<10
                TOPPIDchecklist.Complete(row)="Very Little Data";
            elseif isnat(EndTime)
                TOPPIDchecklist.Complete(row)="Incomplete, Did Not Return Home";
            elseif (EndTime-tracklocs.Date(end))>10
                TOPPIDchecklist.Complete(row)="Incomplete, Returned Home";
            else
                TOPPIDchecklist.Complete(row)="Complete";
            end

            %add end point to track if seal returned to colony and the data gap is less than 14 days
            EndLat=MetaDataAll.ArriveLat(tindex);
            EndLon=MetaDataAll.ArriveLon(tindex);
            StartLat=MetaDataAll.DepartLat(tindex);
            StartLon=MetaDataAll.DepartLon(tindex);

            x=height(tracklocs);
            if x<6
                continue
            end

            if ~isnan(EndLat) && ~isnan(EndLon) && (EndTime-tracklocs.Date(end))<5
                tracklocs.TOPPID(x+1)=TOPPID;
                tracklocs.PTT(x+1)=locs.pttid(1);
                tracklocs.Date(x+1)=EndTime;
                tracklocs.Latitude(x+1)=EndLat;
                tracklocs.Longitude(x+1)=EndLon;
                tracklocs.LocationClass(x+1)={"G"};
                tracklocs.SemiMajorAxis(x+1)=NaN;
                tracklocs.SemiMinorAxis(x+1)=NaN;
                tracklocs.EllipseOrientation(x+1)=NaN;
            end

            %Add start lat/lon/time
            tracklocs.TOPPID(x+2)=TOPPID;
            tracklocs.PTT(x+2)=locs.pttid(1);
            tracklocs.Date(x+2)=StartTime;
            tracklocs.Latitude(x+2)=StartLat;
            tracklocs.Longitude(x+2)=StartLon;
            tracklocs.LocationClass(x+2)={"G"};
            tracklocs.SemiMajorAxis(x+2)=NaN;
            tracklocs.SemiMinorAxis(x+2)=NaN;
            tracklocs.EllipseOrientation(x+2)=NaN;

            %sort rows again
            tracklocs=sortrows(tracklocs,3);

            %cd 'E:/Tracking Diving 2004-2020/'
            cd 'E:/Tracking Diving 2004-2020/All Pre aniMotum'
            writetable(tracklocs,strcat(num2str(TOPPID),'_', num2str(PTTID),'_GPS_Argos_pre_aniMotum.csv'))
            clear index StartTime EndTime EndLat EndLon tokeep tracklocs
        end
    end
    clear argosdata dates lat1 lat2 lc lc2 lon1 lon2 lq pttid trackindex uniqueptts PTTID validlocs TOPPID matrix locs1 locs gpslocs
   
end
%save('TrackRunningChecklist.mat','TOPPIDchecklist')