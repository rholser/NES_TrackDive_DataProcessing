
%smruTDR_import_V4(filename) will read in SMRU tdr archives ('_tdr.txt'),
%removes text lines, and exports the data as _tdr_raw.csv. It then will
%check the data for time gaps and jumps, correct any that are found, and
%export the result as _tdr_clean.csv.
%
%Created by: T.Keates (tkeates@ucsc.edu) and R.Holser (rholser@ucsc.edu)
%Last modified: 22-Oct-2022

%Version 4.0:
% Modified from read_smru_tdr_TRK_RRH_V3 to:
%   include separate raw and clean csv exports
%   use newer date/time functionality

%Step 1: imports archived data from SMRU tags, finds and removes 
% "HAULOUS" text segments, and exports remaining data as tdr_raw.csv.

%Step 2: fills "HAULOUT" gaps (with depth = 0 at sampling interval of instrument) 
% and checks for other time jumps in data and reparses all into a continuous 
% time series. Data are exported into tdr_clean.csv, which is ready for
% processing with IKNOS using DiveProcessing.m


function smruTDR_import(filename)
%load data into table and name columns
tdrdataraw=readtable(filename);
tdrdataraw=tdrdataraw(:,1:3);
tdrdataraw.Properties.VariableNames={'Date' 'Time' 'Depth'};

%Remove end lines if there are no data
if isnan(tdrdataraw.Time(end))
    tdrdataraw(end,:)=[];
end

if isnan(tdrdataraw.Time(end))
    tdrdataraw(end,:)=[];
end

%find lines in raw data that have "HAULOUT" in them
gapstofill=find(strcmp(tdrdataraw.Date,'HAULOUT:')==1);

%% Create tdr_raw.csv
%remove HAULOUT lines in copy of data and export result to csv
tdrdatarawcsv=tdrdataraw;
tdrdatarawcsv(gapstofill,:)=[];
tdrdatarawcsv.Date=datetime(char(tdrdatarawcsv.Date),"InputFormat","uuuu/MM/dd");
tdrdatarawcsv.Time=tdrdatarawcsv.Date+tdrdatarawcsv.Time;
writetable(tdrdatarawcsv(:,2:3),[filename(1:end-4) '_raw.csv']);
clear tdrdatarawcsv

%% Create tdr_clean.csv

%If there are HAULOUT gaps, fill them and re-parse data
if ~isempty(gapstofill)
    %start line counter for raw data
    linecountraw=1;
    linecountnew=1;

    %Calculate time interval between each measurement.
    timechange=diff(tdrdataraw.Time);
    samplinginterval=median(timechange,'omitnan'); %most common sampling interval within record

    %calculate max size of final tables based on total duration of data collection
    %and sampling frequency
    finish=datetime(strcat(char(tdrdataraw.Date(end)),char(tdrdataraw.Time(end))),"InputFormat","uuuu/MM/ddHH:mm:ss");
    start=datetime(strcat(char(tdrdataraw.Date(1)),char(tdrdataraw.Time(1))),"InputFormat","uuuu/MM/ddHH:mm:ss");
    tablesize=ceil((finish-start)/samplinginterval)+5000;

    %Create empty arrays for Date, Time, and Depth
    NewData=table('Size',[tablesize,2],'VariableTypes',{'datetime','double'},...
        'VariableNames',{'Time','Depth'});

    %Loop through "HAULOUT" incidents to concatenate raw data with generated
    %timestamps and depth to fill time gaps and create a file with continuous,
    %consistent time intervals from start to finish.
    for i=1:length(gapstofill)
        n=gapstofill(i); %n is index of row in tdrdataraw with "HAULOUT"

        %parse out "good" data up to haulout
        %Combine date and time into single datetime 
        RawDate=table(datetime(strcat(char(tdrdataraw.Date(linecountraw:(n-1))),...
            char(tdrdataraw.Time(linecountraw:(n-1)))),"InputFormat","uuuu/MM/ddHH:mm:ss"),...
            'VariableNames',{'Date'});
        RawDepth=table(tdrdataraw.Depth(linecountraw:(n-1)),'VariableNames',{'Depth'});
        RawEnd=linecountnew-1+size(RawDate,1); %index for end of raw data chunk

        %Define haulout time period/length and shift linecountraw based on file
        %contents (number of rows to skip before data restarts)
        hauloutstart=datetime(strcat(char(tdrdataraw.Date(n-1)),...
            char(tdrdataraw.Time(n-1))),"InputFormat","uuuu/MM/ddHH:mm:ss"); %find timestamp of line before the haulout
        if isnan(tdrdataraw.Depth(n+1))
            hauloutend=datetime(strcat(char(tdrdataraw.Date(n+3)),...
                char(tdrdataraw.Time(n+3))),"InputFormat","uuuu/MM/ddHH:mm:ss"); %three rows later data starts (usually CTD tags)
            linecountraw=n+3;
        else
            hauloutend=datetime(strcat(char(tdrdataraw.Date(n+1)),...
                char(tdrdataraw.Time(n+1))),"InputFormat","uuuu/MM/ddHH:mm:ss"); %one row later data starts again (usually GPS tags)
            linecountraw=n+1;
        end

        %Create date/time stamps from haulout start to end, at sampling
        %interval of instrument and generate Date/Time/Depth to fill the
        %haulout gap
        GapDate=table((hauloutstart:samplinginterval:hauloutend)','VariableNames',{'Date'});
        GapDepth=table('Size',[size(GapDate,1),1],'VariableTypes',{'double'},...
            'VariableNames',{'Depth'});
        GapEnd=RawEnd-1+size(GapDate,1); %index for end of gap data chunk

        %Concatenate Date/Time/Depth into continuous tables (one for each)
        NewData.Time(linecountnew:RawEnd)=RawDate.Date;
        NewData.Time(RawEnd:GapEnd)=GapDate.Date;
        NewData.Depth(linecountnew:RawEnd)=RawDepth.Depth;
        NewData.Depth(RawEnd:GapEnd)=GapDepth.Depth;

        %Adjust linecountnew for start of new loop
        linecountnew=GapEnd+1;

        clear RawDate RawDepth GapDate GapDepth 
    end

    %Parse out last chunk of good data and add to tables
    RawDate=table(datetime(strcat(char(tdrdataraw.Date(linecountraw:end)),...
        char(tdrdataraw.Time(linecountraw:end))),"InputFormat","uuuu/MM/ddHH:mm:ss"),...
        'VariableNames',{'Date'});
    RawDepth=table(tdrdataraw.Depth(linecountraw:end),'VariableNames',{'Depth'});
    RawEnd=linecountnew-1+size(RawDate,1); %index for end of raw data chunk

    NewData.Time(linecountnew:RawEnd)=RawDate.Date;
    NewData.Depth(linecountnew:RawEnd)=RawDepth.Depth;

    %Remove excess rows at end (if any)
    NewData(ismissing(NewData.Time),:)=[];

    %Remove any mid-record NaNs
    NewData(isnan(NewData.Depth),:)=[];

    %cut off data when time gap of greater than 4 seconds (indicative of battery
    %dying - remaining data untrustworthy)
    timechange=diff(NewData.Time);
    NewData((timechange==0),:)=[];
    timechange=diff(NewData.Time);
    badtime=find(timechange>4);

    if ~isempty(badtime)
        cutoff=min(badtime(:));
        NewData(cutoff:end,:)=[];
    end

%If there are no gaps, just write original data into .csv
else
    NewData=table('Size',[size(tdrdataraw,1),2],'VariableTypes',{'datetime','double'},...
    'VariableNames',{'Time','Depth'});
    NewData.Time=datetime(strcat(char(tdrdataraw.Date),...
        char(tdrdataraw.Time)),"InputFormat","uuuu/MM/ddHH:mm:ss");
    NewData.Depth=tdrdataraw.Depth;
end
writetable(NewData,[filename(1:end-4) '_clean.csv']);


