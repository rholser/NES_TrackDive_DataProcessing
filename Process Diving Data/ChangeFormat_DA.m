%output=ChangeFormat_DA(filename,Start,End,TOPPID)
%
%Function to prepare csv file, fix errors, and run dive analysis on TDR data. Truncates data to startstop 
% for non-Little Leonardo data
%
%Created by: Rachel Holser (rholser@ucsc.edu), rewritten from P.Robinson's 2009 script.
%
%Requires IKNOS toolbox
%Requires functions: iknos_da
%                    DA_data_compiler
%                    iknos_findclosest_RRH
%                    resolution_DepthRes
%
%Version 4.2: incorportates new SMRU tdr_clean files and uses datetime
%             rather than datenum wherever possible
%
% Update Log:
% 05-Dec-2022 - modified by Arina Favilla to (1) update zoc approach to account for large zero offset
%               and (2) fix Kami timestamp:
%               added elseif statements to Step 1
%               added line to Step 3.1
%               added Step 3.3
%               added code to Kami if statement in Step 4
%               modified Step 8 to round DepthRes
%               added Step 8.1
%               edited Step 9
% 10-Dec-2022 - Add datetime conversions for different instrument types
% 17-Dec-2022 - Changed depth res method to use resolution_DepthRes
% 21-Dec-2022 - Modified minsurface in Step 8.1 to account for instances where WC tag
%               records -80m during surface interval when dry
% 22-Dec-2022 - Minor changes to final figure
% 23-Dec-2022 - Added exceptions to Step 8.1
% 28-Dec-2022 - Added date conversion to Step 2.2 and Step 3
%               Added NaT and duplicate time filter to Step 6
%               Added TOPPID exceptions to Step 8.1
% 04-Jan-2023 - Changed name and added Kami details to step 3.3
% 01-Mar-2023 - Added more Kami timestamp corrections for 32 seals (A.Favilla)
%               Fixed compress factor for some Kami seals to include offset (A.Favilla)
%               Fixed datetime issue for 20015002 WC tag (A. Favilla)
% 16-Mar-2023 - Added year corrections for SMRU tags: 2016004, 2016018, 2018004 (A.Favilla)
% 21-Mar-2023 - Incorporated Rachel's SMRU_tweaks.m code as Step 6.1 (A.Favilla)
% 03-Jul-2023 - Changed to using iknos_da_V2 (uses textscan) (R.Holser)
% 18-Mar-2024 - Changed min dive depth to 25m
%
%Version 4.3: Uses All_Filenames.mat for locating/loading files. Includes new input "outFolder".
%             Allows TDRs in all folders to be run as one batch. Modified filename handling in steps
%              7 and 9.
% Update Log:
% 01-May-2024 - Modified kami timestamp adjustments - reads in parameters from csv in Step 3 and
%               applies the corrections in Step 4
%               Requires 'KamiTimeAdjust.csv' and 'StrokeTimeAdjust.csv'
% 29-May-2024 - Add cut date for 2010028

function ChangeFormat_DA(filename,Start,End,TOPPID,outFolder)
%% Step 1: load csv of TDR data
    data=readtable(strcat(outFolder,'/',filename),'HeaderLines',0,'ReadVariableNames',true);
    
    %Test for normal headers.  If Depth header is missing, re-imports file with no headers and assigns them.
    if isempty(find(strcmp('Depth', data.Properties.VariableNames))>0)
        data=readtable(strcat(outFolder,'/',filename),'HeaderLines',0,'ReadVariableNames',false);
        data.Properties.VariableNames(1)={'Time'};
        data.Properties.VariableNames(2)={'Depth'};
        data(1,:)=[]; %remove top row - often has faulty time format when no headers
    end
    %%Combine date and time columns for Kami tag
    % if size(strfind(filename,'Kami'),1)>0
    %     [y,m,d]=ymd(data.Date);
    %     [H,M,S]=hms(data.Time);
    %     data.Time=datetime(y,m,d,H,M,S);
    %     data=removevars(data,'Date');
    %     clear y m d H M S
    % end
    % Combine date and time columns and fix no seconds issue for 2015002 WC tag
    if TOPPID==2015002 && contains(filename,'Archive.csv')
        [y m d]=ymd(datetime(data.Date,'InputFormat','MM/dd/yyyy'));
        [H M S]=hms(data.Time);
        M=[M(1)-1; M ;M(end)+1];
        new_min_idx=find(diff(M)~=0); %new_min_idx=new_min_idx(1:end-1);
        new_min=diff(find(diff(M)~=0));
        SampFreq=60/mode(diff(find(diff(M)==1)));
        for u=1:length(new_min)
            S(new_min_idx(u):new_min_idx(u+1)-1)=[0:SampFreq:SampFreq*new_min(u)-1];
        end
        M=M(2:end-1);
        data.Time=datetime(y,m,d,H,M,S);
        data=removevars(data,'Date');
        clear y m d H M S new_min_idx new_min SampFreq u
    end

%% Step 2: remove rows with depth issues
    %Step 2.1: remove rows with NaNs (often present in row with duplicate time stamp)
    data(isnan(data.Depth),:)=[];
    
    %Step 2.2: deal with 2000+m spikes.
    % For TOPPID 2015003, simply remove spikes - visual inspection indicates remaining record is reliable.
    if TOPPID==2015003
        data(data.Depth>2000,:)=[];
    % For all others, pull rows with depths greater than 2000m into separate data structure, convert timestamp 
    % to serial date, and check against Start and End date to see if spike occur during time at sea.
    else
        bad_data=data(data.Depth>2000,:);
        %Convert and check dates in bad_data
        try
            bad_data.Time=datetime(bad_data.Time,'InputFormat','dd/MM/yyyy HH:mm:ss');
        end
        try
            bad_data.Time=datetime(bad_data.Time,'InputFormat','HH:mm:ss dd-MMM-yyyy');
        end
        try
            bad_data.Time=bad_data.Date+bad_data.Time;
        end
        bad_data.Start=bad_data.Time-Start;
        bad_data.End=End-bad_data.Time;
        %Indices within data
        bad_data.Ind(:)=0;
        bad_data.Ind=find(data.Depth>2000);
        %Index to indicate within time at sea (0 if not, 1 if yes)
        bad_data.Ind2(:)=0;
        bad_data.Ind2(bad_data.Start>0 & bad_data.End>0)=1;
        %Find earliest incident of spiking
        Cut_Ind=min(bad_data.Ind(bad_data.Ind2==1));
        %Truncate data to first spike
        data(Cut_Ind:end,:)=[];
    end
    
    %Step 2.3: Detect and remove lines with other unrealistically large depth jumps, which may indicates a tag 
    % reset with bad datetime that will not convert correctly
    ind_bad1=find(abs(diff(data.Depth))>30); %depth jumps more than 30m
    ind_bad1(:)=ind_bad1(:)+1;
    data(ind_bad1,:)=[];

%% Step 3: date conversions
    %Step 3.1: Conver to datetime then parse out time into separate columns using datevec
    try
        data.Time=datetime(data.Time,'InputFormat','dd/MM/yyyy HH:mm:ss');
    end
    try
        data.Time=datetime(data.Time,'InputFormat','HH:mm:ss dd-MMM-yyyy');
    end
    try
        data.Time=datetime(data.Time,'InputFormat','dd-MMM-yyyy HH:mm:ss');
    end
    try
        data.Time=data.Date+data.Time;
        data.Time=datetime(data.Time,"Format",'default');
    end
    
    [data.Year, data.Month, data.Day, data.Hour, data.Min, data.Sec]...
        =datevec(data.Time);
    data.Sec=round(data.Sec);
    
    %Step 3.2: Adjustments for specific TDR records based on TOPPID and tag type.
    % Truncate records when visual inspection indicates sensor failures began
    if TOPPID==2010028 && contains(filename,'Archive.csv')%recording fails on Feb 22 2010
        Cut=datetime(2010,02,22);
        data(data.Time>Cut,:)=[];
    elseif TOPPID==2010077 && contains(filename,'Archive.csv')%recording began to fail on Nov 7 2010
        Cut=datetime(2010,11,07);
        data(data.Time>Cut,:)=[];
    elseif TOPPID==2010081 && contains(filename,'Archive.csv')%record began to fail on Oct 8 2010
        Cut=datetime(2010,10,07);
        data(data.Time>Cut,:)=[];
    elseif TOPPID==2012039 && contains(filename,'Archive.csv')%record began to fail on Sep 5 2012
        Cut=datetime(2012,09,05);
        data(data.Time>Cut,:)=[];
    end
    % Year correction for CTD tag records with incorrect year in recorded timestamps (day, month, and time 
    % all correct)
    if TOPPID==2016004 && contains(filename,'tdr_clean.csv')%recording starts in 2012 instead of 2016
        data.Year=data.Year+4;
        data.Time=data.Time+calyears(4);
    elseif TOPPID==2016018 && contains(filename,'tdr_clean.csv')%recording starts in 2012 instead of 2016
        data.Year=data.Year+4;
        data.Time=data.Time+calyears(4);
    elseif TOPPID==2017024 && contains(filename,'tdr_clean.csv')%recording starts in 2013 instead of 2017
        data.Year=data.Year+4;
        data.Time=data.Time+calyears(4);
    elseif TOPPID==2017025 && contains(filename,'tdr_clean.csv')%recording starts in 2013 instead of 2017
        data.Year=data.Year+4;
        data.Time=data.Time+calyears(4);
    elseif TOPPID==2017026 && contains(filename,'tdr_clean.csv')%recording starts in 2013 instead of 2017
        data.Year=data.Year+4;
        data.Time=data.Time+calyears(4);
    elseif TOPPID==2017028 && contains(filename,'tdr_clean.csv')%recording starts in 2016 instead of 2017
        data.Year=data.Year+1;
        data.Time=data.Time+calyears(1);
    elseif TOPPID==2018004 && contains(filename,'tdr_clean.csv')%recording starts in 2014 instead of 2018
        data.Year=data.Year+4;
        data.Time=data.Time+calyears(4);
    elseif TOPPID==2018028 && contains(filename,'tdr_clean.csv')%recording starts in 2013 instead of 2018
        data.Year=data.Year+5;
        data.Time=data.Time+calyears(5);
    elseif TOPPID==2018030 && contains(filename,'tdr_clean.csv')%recording starts in 2017 instead of 2018
        data.Year=data.Year+1;
        data.Time=data.Time+calyears(1);
    elseif TOPPID==2018034 && contains(filename,'tdr_clean.csv')%recording starts in 2017 instead of 2018
        data.Year=data.Year+1;
        data.Time=data.Time+calyears(1);
    elseif TOPPID==2019010 && contains(filename,'tdr_clean.csv')%recording starts in 2017 instead of 2018
        data.Year=data.Year+4;
        data.Time=data.Time+calyears(4);
    end
    % Correction for Stroke logger record
    if size(strfind(filename,'Stroke'),1)>0 && TOPPID==2011043
        firsthalf=data(data.Time<=datetime(2011,7,4,12,6,55),:);
        secondhalf=data(data.Time>datetime(2011,7,4,12,6,55),:);
        insertDepth=repelem(firsthalf.Depth(end),26,1); % extend surface interval by 26*seconds(5)=130
        insertDateTime=transpose(firsthalf.Time(end)+seconds(5):seconds(5):firsthalf.Time(end)+26*seconds(5));
        insertStroke=zeros(26,1); insertSway=zeros(26,1); insertPosture=zeros(26,1);
        insert=table(insertDateTime,insertDepth,insertStroke,insertSway,insertPosture,'VariableNames',{'Time','Depth','Stroke','Sway','Posture'});
        secondhalf.Time=transpose(insert.Time(end)+seconds(5):seconds(5):secondhalf.Time(end)+26*seconds(5));
        %%%% There are instances of a 10 second interval in secondhalf so these newly calculated
        %%%% times are two rows longer thean secondhalf.
        clear data;
        data=[firsthalf; insert; secondhalf];
    end

    %Step 3.3: load UTC offset and compression factor for kami and stroke records (applied in Step 4)
    adjustKami=readtable('KamiTimeAdjust.csv');
    adjustStroke=readtable('StrokeTimeAdjust.csv');

    if size(strfind(filename,'Kami'),1)>0
        offset=adjustKami.Offset_Direction(adjustKami.TOPPID==TOPPID)*...
            (hours(adjustKami.Offset_Hour(adjustKami.TOPPID==TOPPID))+...
            minutes(adjustKami.Offset_Min(adjustKami.TOPPID==TOPPID))+...
            seconds(adjustKami.Offset_Sec(adjustKami.TOPPID==TOPPID))); 
        Cut=datetime(adjustKami.Cut_Year(adjustKami.TOPPID==TOPPID),...
            adjustKami.Cut_Month(adjustKami.TOPPID==TOPPID),...
            adjustKami.Cut_Day(adjustKami.TOPPID==TOPPID),...
            adjustKami.Cut_Hour(adjustKami.TOPPID==TOPPID),...
            adjustKami.Cut_Min(adjustKami.TOPPID==TOPPID),...
            adjustKami.Cut_Sec(adjustKami.TOPPID==TOPPID));
        compress=hours(adjustKami.Compress_Hour(adjustKami.TOPPID==TOPPID))+...
            minutes(adjustKami.Compress_Min(adjustKami.TOPPID==TOPPID))+...
            seconds(adjustKami.Compress_Sec(adjustKami.TOPPID==TOPPID)); 
        expand=adjustKami.Expand(adjustKami.TOPPID==TOPPID);
    elseif size(strfind(filename,'Stroke'),1)>0
        offset=adjustStroke.Offset_Direction(adjustStroke.TOPPID==TOPPID)*...
            (hours(adjustStroke.Offset_Hour(adjustStroke.TOPPID==TOPPID))+...
            minutes(adjustStroke.Offset_Min(adjustStroke.TOPPID==TOPPID))+...
            seconds(adjustStroke.Offset_Sec(adjustStroke.TOPPID==TOPPID))); 
        Cut=datetime(adjustStroke.Cut_Year(adjustStroke.TOPPID==TOPPID),...
            adjustStroke.Cut_Month(adjustStroke.TOPPID==TOPPID),...
            adjustStroke.Cut_Day(adjustStroke.TOPPID==TOPPID),...
            adjustStroke.Cut_Hour(adjustStroke.TOPPID==TOPPID),...
            adjustStroke.Cut_Min(adjustStroke.TOPPID==TOPPID),...
            adjustStroke.Cut_Sec(adjustStroke.TOPPID==TOPPID)); 
        compress=hours(adjustStroke.Compress_Hour(adjustStroke.TOPPID==TOPPID))+...
            minutes(adjustStroke.Compress_Min(adjustStroke.TOPPID==TOPPID))+...
            seconds(adjustStroke.Compress_Sec(adjustStroke.TOPPID==TOPPID)); 
        expand=adjustStroke.Expand(adjustStroke.TOPPID==TOPPID);
    else
        offset=0;
        compress=0;
        Cut=0;
        expand=0;
    end

%% Step 4: Time corrections and truncations
% For Kami and Stroke TDRs: apply offset, truncate record, and apply compression/expansion factor
% For other TDRs: truncate record to start and end

if size(strfind(filename,'Kami'),1)>0 || size(strfind(filename,'Stroke'),1)>0
    %retain original datetime
    data.TimeOriginal=data.Time;

    % Step 4.1: apply offset if needed and recalculate date vector
    if offset~=0
        data.Time=data.Time+offset;
        [data.Year, data.Month, data.Day, data.Hour, data.Min, data.Sec]...
            =datevec(data.Time);
        data.Sec=round(data.Sec); % some seconds > 59 so next lines fix the issue
        % nextmin=find(stroke.Sec>59);
        if sum(data.Sec>59)>0
            data.Time=datetime(data.Year, data.Month, data.Day, data.Hour, data.Min, data.Sec);
            [data.Year, data.Month, data.Day, data.Hour, data.Min, data.Sec]...
                =datevec(data.Time);
        end
    end

    % Step 4.2: truncate record to Start and Stop times (accounting for offset if needed)
    if ~isnat(Cut)
        Cut=Cut+offset;
        data(data.Time>Cut,:)=[];
        [~,ind1]=min(abs(data.Time-Start));
        [~,ind2]=min(abs(data.Time-End));
        data=data(ind1:ind2,:);
    else
        [~,ind1]=min(abs(data.Time-Start));
        [~,ind2]=min(abs(data.Time-End));
        data=data(ind1:ind2,:);
    end

    % Step 4.3: apply compression/expansion factor as appropriate and recalculate date vector
    if compress~=0
        record_length=seconds(data.Time(end)-data.Time(1));
        record_frac=seconds(data.Time(:)-data.Time(1));
        if TOPPID==2013043 || TOPPID==2013045 || TOPPID==2018001
            record_frac=flip(record_frac);
        end
        if expand==0
            data.DateTime=data.Time-seconds((seconds(compress)*record_frac)/record_length);
        else % if expand==1
            data.DateTime=data.Time-seconds((seconds(-1*compress)*record_frac)/record_length);
        end
        [data.Year, data.Month, data.Day, data.Hour, data.Min, data.Sec]...
            =datevec(data.Time);
        data.Sec=round(data.Sec); % some seconds > 59 so next lines fix the issue
        if sum(data.Sec>59)>0
            data.Time=datetime(data.Year, data.Month, data.Day, data.Hour, data.Min, data.Sec);
            [data.Year, data.Month, data.Day, data.Hour, data.Min, data.Sec]...
                =datevec(data.Time);
        end
    end
% For non-Kami/Stroke TDRs, truncate record only
else
    [~,ind1]=min(abs(data.Time-Start));
    [~,ind2]=min(abs(data.Time-End));
    data=data(ind1:ind2,:);
end


%% Step 5: calculate sampling rate
    SamplingDiff=diff(data.Time);
    SamplingRate=seconds(round(mode(SamplingDiff)));

%% Step 6: Remove data with bad times (zero or negative sampling rates or NaT)
%NOTE: This will only remove SINGLE bad lines and will not deal with full time shifts.
    OffTime_ind=find(SamplingDiff<=0);
    OffTime_ind(:)=OffTime_ind(:)+1;
    data(OffTime_ind,:)=[];

        % Step 6.1 Adjustments made on a case-by-case basis where TDR records have backwards time jumps
        if TOPPID==2018023 && contains(filename,'tdr_clean.csv')
            %remove overlapping dives
            nrows=(40*60)/4; 
            data(OffTime_ind(3,1)-nrows:OffTime_ind(3,1)+nrows,:)=[];
    
            %long period of deep measurements at ~minute intervals overlapping in time with other
            %(normal) diving data
            nrows=2338619-2338217;
            data(OffTime_ind(2,1)-nrows:OffTime_ind(2,1),:)=[];
    
            %remove overlapping dives
            nrows=(40*60)/4;
            data(OffTime_ind(1,1)-nrows:OffTime_ind(1,1)+nrows,:)=[];
    
        elseif TOPPID==2018024 && contains(filename,'tdr_clean.csv')
            %two sections of unusual dives/backwards time right at the end of record.  Trim to
            %04-Jan-2019 00:56:00
            data(find(data.Time=='04-Jan-2019 00:56:00'):end,:)=[];
    
        elseif TOPPID==2018025 && contains(filename,'tdr_clean.csv')
            %Remove 12 minutes prior to backwards time jump
            nrows=(12*60)/4;
            data(OffTime_ind(1,1)-nrows:OffTime_ind(1,1),:)=[];
    
        elseif TOPPID==2018026 && contains(filename,'tdr_clean.csv')
            %Remove 15 minute before and after time jump
            nrows=(15*60)/4;
            data(OffTime_ind(3,1)-nrows:OffTime_ind(3,1)+nrows,:)=[];
    
            %Remove 1 minute before and after time jump
            nrows=60/4;
            data(OffTime_ind(2,1)-nrows:OffTime_ind(2,1)+nrows,:)=[];
    
            %Remove 9 minutes prior to time jump
            nrows=(60*9)/4;
            data(OffTime_ind(1,1)-nrows:OffTime_ind(1,1),:)=[];
    
            %Remove depths greater than 1400 - glitch
            data(data.Depth>1400,:)=[];
    
        elseif TOPPID==2018028 && contains(filename,'tdr_clean.csv')
            %Remove 16 minutes after time jump
            nrows=(16*60)/4;
            data(OffTime_ind(1,1):OffTime_ind(1,1)+nrows,:)=[];
    
        end
    
    data(isnat(data.Time),:)=[];

%% Step 7: generate variable string for iknos da and write to new .csv.
    if size(strfind(filename,'-out-Archive'),1)>0
        filenameDA=strcat(outFolder,'\',strtok(filename,'-'),'_DAprep_full.csv');
        filenameDAStr=strcat(outFolder,'\',strtok(filename,'-'),'_DAString.txt');
    else
        filenameDA=strcat(outFolder,'\',strtok(filename,'.'),'_DAprep_full.csv');
        filenameDAStr=strcat(outFolder,'\',strtok(filename,'.'),'_DAString.txt');
    end
    
    [data_DA,DAstring]=DA_data_compiler(data);
    writematrix(data_DA,filenameDA);
    fid=fopen(filenameDAStr,'wt');
    fprintf(fid,DAstring);
    fclose(fid);


%% Step 8: Depth resolution and MinMax detection
    DepthRes=resolution_DepthRes(data.Depth);

    %Step 8.1: detect if dive surface intervals have offset >10m. Some individual TOPPIDs have been 
    % manually asigned due to weird surface data found during visual inspection.
    running_surface = movmin(data.Depth,hours(2),'SamplePoints',data.Time);
    [f,xi]=ecdf(running_surface); %figure; ecdf(running_surface,'Bounds','on');
    if size(xi,2)<3 && size(strfind(filename,'_tdr_clean'),1)>0
        minsurface=0; % SMRU tags
    elseif TOPPID==2013032 && size(strfind(filename,'-out-Archive'),1)>0 % TDR stopped recording when "DRY", resulting in gaps during surface events.
        minsurface=0; % set manually through visual inspection
    elseif TOPPID==2006052 && size(strfind(filename,'-out-Archive'),1)>0 % TDR stopped recording when "DRY", resulting in gaps during surface events.
        minsurface=0; % set manually through visual inspection
    elseif TOPPID==2013036 && size(strfind(filename,'-out-Archive'),1)>0 % TDR stopped recording when "DRY", resulting in gaps during surface events.
        minsurface=0; % set manually through visual inspection
    elseif abs(xi(3)-xi(2))>10 % if there's a large jump, might be due to surface spikes
        minsurface=xi(3);
    else
        minsurface=interp1(f,xi,0.05);
    end

%% Step 9: Run IKNOS DA - new ZocMinMax with DEFAULT ZOC params
    if minsurface<-10
        iknos_da(filenameDA,DAstring,32/SamplingRate,25/DepthRes,20,'wantfile_yes','ZocWindow',2,...
            'ZocWidthForMode',15,'ZocSurfWidth',10,'ZocDiveSurf',15,'ZocMinMax',[minsurface-10,2200]);
    else
        iknos_da(filenameDA,DAstring,32/SamplingRate,25/DepthRes,20,'wantfile_yes','ZocWindow',2,...
            'ZocWidthForMode',15,'ZocSurfWidth',10,'ZocDiveSurf',15,'ZocMinMax',[-10,2200]);
    end

%% Step 10: Plot and save QC figs

% Load rawzoc data and divestat files
    if size(strfind(filename,'-out-Archive'),1)>0
        rawzocdatafile=dir(strcat(outFolder,'\',strtok(filename,'-'),'_DAprep_full_iknos_rawzoc_data.csv'));
        rawzocdata=readtable(strcat(rawzocdatafile.folder,'\',rawzocdatafile.name),'HeaderLines',26,'ReadVariableNames',true);
        rawzocdata.Time=datetime(rawzocdata.time,'ConvertFrom','datenum');
    
        DiveStatfile=dir(strcat(outFolder,'\',strtok(filename,'-'),'_DAprep_full_iknos_DiveStat.csv'));
        DiveStat=readtable(strcat(DiveStatfile.folder,'\',DiveStatfile.name),'HeaderLines',26,'ReadVariableNames',true);
        DiveStat.Time=datetime(DiveStat.Year,DiveStat.Month,DiveStat.Day,DiveStat.Hour,DiveStat.Min,DiveStat.Sec);
    else
        rawzocdatafile=dir(strcat(outFolder,'\',strtok(filename,'.'),'_DAprep_full_iknos_rawzoc_data.csv'));
        rawzocdata=readtable(strcat(rawzocdatafile.folder,'\',rawzocdatafile.name),'HeaderLines',26,'ReadVariableNames',true);
        rawzocdata.Time=datetime(rawzocdata.time,'ConvertFrom','datenum');
    
        DiveStatfile=dir(strcat(outFolder,'\',strtok(filename,'.'),'_DAprep_full_iknos_DiveStat.csv'));
        DiveStat=readtable(strcat(DiveStatfile.folder,'\',DiveStatfile.name),'HeaderLines',26,'ReadVariableNames',true);
        DiveStat.Time=datetime(DiveStat.Year,DiveStat.Month,DiveStat.Day,DiveStat.Hour,DiveStat.Min,DiveStat.Sec);
    end
    
    %plot raw and zoc'd data and indicate all dive start and ends from divestat
    figure(1);
    plot(rawzocdata.Time,rawzocdata.depth);
    hold on; set(gca,'YDir','reverse');
    plot(rawzocdata.Time,rawzocdata.CorrectedDepth,'b');
    scatter(DiveStat.Time,zeros(size(DiveStat,1),1),[],'go');
    scatter(DiveStat.Time+seconds(DiveStat.Dduration),zeros(size(DiveStat,1),1),[],'ro');
    text(DiveStat.Time,DiveStat.Maxdepth,num2str(DiveStat.DiveNumber),'Color','b');
    legend({'raw','zoc','Start dive','End dive'});
    title(['Raw vs ZOC: ' num2str(TOPPID)]);
    if size(strfind(filename,'-out-Archive'),1)>0
        savefig(strcat(outFolder,'\',strtok(filename,'-'),'_Raw_ZOC.fig'));
    else
        savefig(strcat(outFolder,'\',strtok(filename,'.'),'_Raw_ZOC.fig'));
    end
    close;
    
    clear bad_data Cut_Ind ind_bad1 ind1 ind2 OffTime_ind NaTTime_ind offset compress Cut minsurface
end
