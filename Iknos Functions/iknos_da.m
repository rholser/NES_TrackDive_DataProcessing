function iknos_da(inputfile,dataformat,timemultiple,depthmultiple,depth_zone,wantfile,varargin)
%
% IKNOS_DA easily import and analyze TDR data in a variety of  formats.
% The output includes 2 figures and one statistic file. If you ask for it
% ('wantfile_yes'), a raw data file will also be created.
% My advice is to try without asking for the raw data first, so that you
% can tweak the zoc parameters as you want. When you are happy of it, then
% re-run it and ask for the raw file to be created.
%
% USAGE:
% iknos_da(inputfile,dataformat,timemultiple,depthmultiple,depth_zone,wantfile,varargin)
%       EXAMPLES:
%       iknos_da('MyFile.csv','Day Month Year Hour Minute Second depth etemp alight blight',4,8,20,'wantfile_yes');
%       iknos_da('MyFile.csv','Day Month Year Hour Minute Second depth etemp alight',3,6,20,'wantfile_no',...
%                'BotFix',75,'ZocMinMax',[-5,200],'ZocWidthForMode',4,'NightCutOff',100,'ThermoclineGradient',0.03);
%
%INPUTS:
%
%   filename:   the complete filename in single quotes
%
%   dataformat:    a string (in single quotes) describing your file.
%           This string must give the variables names of your file in order
%           They can be separated by any non-letter character
%           The orthograph must match the following variables names
%           variable names:
%           Year , Month, Day, Hour, Minute, Second, ampm          %% all numeric am and pm can work
%           depth, itemp, etemp, alight, blight, speed, salinity        %% all numeric
%           xa, xb, xc, xd, xe, xf, xg, xh, xi, xj  other numeric variables
%           ya, yb, yc, yd, ye, yf, yg, yh, yi, yj  other string variables
%
%   timemultiple: to define a dive, how many data points do you want ?
%           For example if  4, this means 3 times 'sampling interval' will be the minimum time for
%           a dive to be analyzed by iknos_da. You must then enter 3
%           (without quotes).
%
%   depthmultiple: to define a dive, which depth should it be ?
%            For example, if 5 meters, and depth resolution is 0.5 m, you must enter 10
%            (without quotes).
%
%   depth_zone: to calculate the intra-depth-zone index.
%            Please read (and cite): Tremblay and Cherel 2000. Benthic and pelagic dives: a
%            new foraging behaviour in rockhopper penguins. Marine Ecology
%            Progress Series 204:257-267.
%            20 is advised. If your animal is strongly benthic, go for 10
%            (without quotes).
%
%   wantfile: do you want the raw data output ?
%            Entry must be a string with either 'wantfile_yes' or
%            'wantfile_no'.
%
% VARARGIN is a matlab word, which can be filled with anything. In this
%       case, it can be all parameters for which you want to change the default
%       values. A brief description follows in the format:
%       'parameter' , default value
%
% For input in zoc
%
%     'ZocMinMax'  ,  [-10 2500]  % values out of this depth range (m) will be trimmed
%     'ZocWindow'  ,  'auto'   % see the function for details
%     'ZocSpeedFilter'  ,  5      % this is in Meter per Second
%     'ZocWidthForMode'  ,  'auto'   % See the function for details
%     'ZocModeMax'  ,  ZocWidthForMode/2
%     'ZocSurfWidth'  ,  'auto'    % see the Function for details
%     'ZocDiveSurf'  ,  6     % 6 times depth resolution
%
% For input in iknos_find_bottom
%
%       Default to find bottom time is a slope method. If you want to change
%       this and have a fixed percentage of maximum depth to calculate bottom
%       time, you can enter 'BotFix' only. Then,  80% will be the
%       default, but you can also enter for example 'BotFix',75.
%
%       'BotFix'  ,  80    %%  means 80% of maximum depth
%
% For input in iknos_euphotic_depth
%
%       'NightCutOff'  ,  150    % Euphotic depth cannot be calculated at night.
%       150 is a cut off that works on the Wildlife Computers MK9 scale light.
%       With other tags or other scale for light, check what are the values
%       between Day and night, and change this accordingly.
%
% For input in iknos_thermocline_depth
%
%       'ThermoclineGradient'  ,  0.05   % This is in Degree Centigrade per meter
%       of depth.
%
% Information regarding the importation of the data :
%       Idea behind the code: being able to extract data from a time
%       series of TDR data, even if the file contains up to extra 10 numeric or 10 text variables (unused in
%       analysis). The output must be such as they can be easily handled after (analyse, re-write...).
%       After the import process, matrix1 comtains time vectors, matrix2 contains
%       the "working" variables, and matrix3 contains the extra numeric
%       variables. A character string with the associated variable names is
%       created for each matrix, for further creation of headerlines in the output files.
%       The extra text variables remain alone (they are not merge in a matrix) but a character string
%       is also created with the variable names.
%       For working variables, the column number in matrix2 is calculated for
%       each variable (example: coldepth=2), for easy utilization of the 'working" matrix .
%       A list of entered variables is also kept for further presence checking
%       This permits to import data in any order, in (almost) any file, and to
%       detect the potential analyses to do depending on the available
%       variables.
%
% VERSION: 2.3/1.2
%       Version coding is as follow: first number for Dive analysis
%       program, Second number for Zoc program.
%
% CREDIT:
%       Yann Tremblay (The iknos Toolbox)
%       To use this program, please contact me:  tremblay@biology.ucsc.edu
%       developped from November 2003 to March 2005.
%
% HISTORY:
%       August 2005: Starting version numbering: 2.1/1.0
%                    Input parameters are printed in output files.
%       March 2007: Little changes in Depth interval management
%                   Version changed to 2.1/1.1
%       July 2021: Altered date/time variable names to avoid overlap with
%                   function names. Changed maxload from 10MB to 1GB to
%                   account for newer hardware - most files can be
%                   processed as a single piece rather than cut into
%                   chunks. Version changed to 2.2/1.1
%       December 2022 (Arina Favilla): changed iknos_resolution() to either
%                                      resolution_DepthRes() or
%                                      resolution_SamplingRate(),
%                                      added zoc'd profile to _zoc.fig
%       17-Dec-2022 - changed name to iknos_da
%       22-Dec-2022 - changed use of strvcat-->char, csvread-->readmatrix, isstr-->ischar,
%                     where appropriate
%       12-Apr-2023 - changed remaining textread-->textscan and char-->sprintf for M1/M2 Mac compatibility
%       03-Aug-2023 - updated function names (no functionality changes, just naming convention)
%       06-Jun-2024 - replaced strvcat with updated functions
%       07-Jun-2024 - further modifications for printing parameters at the start of output files.
%                     Removed old/commented out code.

version='2.3/1.2';
ProcessTime=datetime("now");

%% IKNOS_DA: import data
% filename=inputfile; %things have been written in parts and merge latter... (could be more simple)
potential_variables=char('Year','Month','Day','Hour','Minute','Second','ampm',... % temporal recognized variables
    'depth','itemp','etemp','alight','blight','speed','salinity',... % data recognized variables
    'xa','xb','xc','xd','xe','xf','xg','xh','xi','xj',... % extra variables numeric
    'ya','yb','yc','yd','ye','yf','yg','yh','yi','yj'); % extra variables text
spv=size(potential_variables,1);
logic1=isletter(dataformat);
logic1=logic1';
idxvar=iknos_setones(logic1); % iknos_setones is a personal function
s=size(idxvar,1);

%% IMPORT: extract variables names, check for valid var names, and create format
%% string for use in the textscan command
format=[];
variables={}; % vertical list for presence checking
variables2=''; % horizontal list for use in the textread command
for i=1:s
    string=dataformat(1,idxvar(i,1):idxvar(i,2));
    variables{end+1}=string;
    present=0;
    j=1;
    while present==0 && j<=spv
        if ~strcmp(string,deblank(potential_variables(j,:)))
            present=0;
            j=j+1;
        else
            present=1;
            break
        end
    end
    if present==0
        error('Unrecognize variable name: %s',string);
    else

        if ismember(string,char('Year','Month','Day','Hour','Minute','Second'),'rows')
            format=strcat(format,' %f');
            if i==1
                variables2=string;
            else
                variables2=strcat(variables2,',',string);
            end
        elseif ismember(string,char('xa','xb','xc','xd','xe','xf','xg','xh','xi','xj'),'rows')
            format=strcat(format,' %f');
            if i==1
                variables2=string;
            else
                variables2=strcat(variables2,',',string);
            end
        elseif ismember(string,char('ya','yb','yc','yd','ye','yf','yg','yh','yi','yj','ampm'),'rows')
            format=strcat(format,' %s');
            if i==1
                variables2=string;
            else
                variables2=strcat(variables2,',',string);
            end
        else % that is the non temporal recognized variables (e.g. depth etemp alight speed...)
            format=strcat(format,' %f');
            if i==1
                variables2=string;
            else
                variables2=strcat(variables2,',',string);
            end
        end
    end
end
variables=char(variables);

%% IMPORT: check if the minimum variables required is met
if ~ismember('Month',variables,'rows') ||...
        ~ismember('Day',variables,'rows') ||...
        ~ismember('Hour',variables,'rows') ||...
        ~ismember('Minute',variables,'rows') ||...
        ~ismember('depth',variables,'rows')
    error('One or more of the following variables are missing: Month Day Hour Minute depth')
end

%% IMPORT: check if depth_zone, timemultiple and depthmultiple are numeric and wantfile is a character string.
%    This is generally not the case if there is a mistake in the input arguments or their order.

if ~isnumeric(timemultiple) || timemultiple<=0
    error('timemultiple must be a positive, non null, numeric value');
end
if ~isnumeric(depthmultiple) || depthmultiple<=0
    error('depthmultiple must be a positive, non null, numeric value');
end
if ~isnumeric(depth_zone) || depth_zone<=0 || depth_zone>=100
    error('depth_zone must be a numeric value in the interval   ] 0 , 100 [ ');
end
if ~ischar(wantfile)
    error('Input wantfile must be a character string (''wantfile_yes'' or ''wantfile_no'')');
end

%% IMPORT: extract only one column (Second ..or Minute if Second is abscent)
%% to check for number of lines and evaluate if it is necessary to cut
%% the file into sections to avoid memory overload
format1=[];
if ismember('Second',variables,'rows')
    sec_exist=1;
    for i=1:s
        var=deblank(variables(i,:));
        if ismember(var,char('Year','Month','Day','Hour','Minute'),'rows')
            format1=strcat(format1,' %*f');
        elseif ismember(var,char('Second'),'rows')
            format1=strcat(format1,' %f');
        elseif ismember(var,char('xa','xb','xc','xd','xe','xf','xg','xh','xi','xj'),'rows')
            format1=strcat(format1,' %*f');
        elseif ismember(var,char('ya','yb','yc','yd','ye','yf','yg','yh','yi','yj','ampm'),'rows')
            format1=strcat(format1,' %*s');
        else % that is the non temporal recognized variables (e.g. depth etemp alight speed...)
            format1=strcat(format1,' %*f');
        end
    end
else % Minute exist necessiraly and its presence has been checked before.
    sec_exist=0;
    for i=1:s
        var=deblank(variables(i,:));
        if ismember(var,char('Year','Month','Day','Hour','Second'),'rows')
            format1=strcat(format1,' %*f');
        elseif ismember(var,char('Minute'),'rows')
            format1=strcat(format1,' %f');
        elseif ismember(var,char('xa','xb','xc','xd','xe','xf','xg','xh','xi','xj'),'rows')
            format1=strcat(format1,' %*f');
        elseif ismember(var,char('ya','yb','yc','yd','ye','yf','yg','yh','yi','yj','ampm'),'rows')
            format1=strcat(format1,' %*s');
        else % that is the non temporal recognized variables (e.g. depth etemp alight speed...)
            format1=strcat(format1,' %*f');
        end
    end
end

if ~ismember('Year',variables,'rows') % variable Year is absent from file
    chk=0;
    while chk==0 % input Year for first data
        yr=input('Please enter starting Year of data (between 1970 and 2070) with 4 digits:');
        if isempty(yr)
            chk=0;
        elseif isnumeric(yr)==0
            chk=0;
        elseif yr<1970 || yr>2070
            chk=0;
        else
            chk=1;
        end
    end
else
    yr=[];
end

%% evaluate varargin inputs
% Varargin inputs must have the format: 'string',value
% They go by pair
BotString='';
ZocString='';
NightDayLightCutoff=[];
ThermoclineGradient=[];
ParamLineZoc={};
ParamLineBot={};
for i=1:2:size(varargin,2)-1
    if ischar(varargin{i}) && strcmp(varargin{i}(1:3),'Zoc')
        ZocString=strcat(ZocString,',''',varargin{i},'''');
        if max(size(varargin{i+1}))==1 % this is because one Zoc input can be a vector of 2 values (see zoc)
            ZocString=strcat(ZocString,',',num2str(varargin{i+1}));
            ParamLineZoc{end+1} = strjoin({'%   ', varargin{i}, ' = ', num2str(varargin{i+1})}, ''); % add string to cell array
        else
            ZocString=strcat(ZocString,',[',num2str(varargin{i+1}),']');
            ParamLineZoc{end+1} = strjoin({'%   ', varargin{i}, ' = ', num2str(varargin{i+1})}, ''); % add string to cell array
        end
    elseif ischar(varargin{i}) && strcmp(varargin{i}(1:3),'Bot')
        BotString=strcat(BotString,',''',varargin{i},'''');
        BotString=strcat(BotString,',',num2str(varargin{i+1}));
        ParamLineBot{end+1, 1} = strjoin({'%   ', varargin{i}, ' = ', num2str(varargin{i+1})}, '');
    elseif ischar(varargin{i}) && strcmp(varargin{i},'NightCutOff')
        NightDayLightCutoff=num2str(varargin{i+1});
    elseif ischar(varargin{i}) && strcmp(varargin{i},'ThermoclineGradient')
        ThermoclineGradient=varargin{i+1};
    end
end
% Convert ParamLineZoc and ParamLineBot into string arrays
if ~isempty(ParamLineZoc)
    ParamLineZoc = strjoin(ParamLineZoc, newline);
else
    ParamLineZoc = '';
end
if ~isempty(ParamLineBot)
    ParamLineBot = strjoin(ParamLineBot, newline);
else
    ParamLineBot = '';
end

if isempty(BotString)
    BotString=',''BotSlope''';
end

if isempty(NightDayLightCutoff)
    NightDayLightCutoff=150;
end
if isempty(ThermoclineGradient)
    ThermoclineGradient=0.05;
end

%% Build command line strings
%Converted to use textscan instead of textread
fid = fopen(inputfile, 'r');
if fid == -1
    error('File not found');
end

try
    timecol = textscan(fid, format1, 'delimiter', ',\t ;/:', 'emptyvalue', NaN, 'HeaderLines', 0);
    headline = 0;
catch
    try
        frewind(fid);
        timecol = textscan(fid, format1, 'delimiter', ',\t ;/:', 'emptyvalue', NaN, 'HeaderLines', 1);
        headline = 1;
    catch
        try
            frewind(fid);
            timecol = textscan(fid, format1, 'delimiter', ',\t ;/:', 'emptyvalue', NaN, 'HeaderLines', 2);
            headline = 2;
        catch
            error(['Error importing the time column: check for 1) character strings in data field 2) number headerlines (max 2)' ...
                ' 3) variable names in the good order 4) delimiter(s) must be: ''tab , ; / :'' (no space)']);
        end
    end
end

fclose(fid);
timecol = timecol{1};
n_lines=length(timecol);

if sec_exist==1
    sampling_interval=resolution_SamplingRate(timecol);
else
    sampling_interval=resolution_SamplingRate(timecol).*60;
end

if sampling_interval==0
    error('Time Vector is invalid, sampling interval was found equal to zero.');
end

clear timecol
h=dir(inputfile);
file_size=h.bytes; clear h

%% if file is larger than "maxload", it will be chunked.
%% maxload is half if raw data file output is wanted
%% otherwise there is memory issues
maxload=1000000000; %% this is 10 Megs  (Changed to 1GB )
n_chunk=ceil(file_size/maxload); % how many times 1 GB.
chunk_idx=round((0:n_lines/n_chunk:n_lines)');
overlap=round((2*60*60)/sampling_interval); % minimum number of lines in the file that covers 2 Hours.

%% calculate the number of lines to skip (headerline)
%% and the number of lines to import (N)
if n_chunk>1
    headerline=[];
    N=[];
    for i=1:size(chunk_idx,1)-1
        headerline=[headerline;chunk_idx(i,1)-overlap+headline];
        N=[N;chunk_idx(i+1,1)+overlap*2-chunk_idx(i,1)+headline];
    end
    headerline(1,1)=headline;
    N(1,1)=chunk_idx(2,1)+overlap+headline;
    N(size(N,1),1)=N(size(N,1),1)-overlap-headline;
else
    headerline=headline;
    N=n_lines;
end

%% Final file names
finaloutputstatfile=strcat(strtok(inputfile,'.'), '_iknos_DiveStat.csv');
finaloutputrawfile=strcat(strtok(inputfile,'.'), '_iknos_rawzoc_data.csv');
finaloutputfig1file=strcat(strtok(inputfile,'.'),'_iknos_fig_zoc.fig');
finaloutputfig2file=strcat(strtok(inputfile,'.'),'_iknos_fig_da.fig');

%% Strings used later to write the output stat files in the main function
header_results=['Year,Month,Day,Hour,Min,Sec,JulDate,Maxdepth,Dduration,Botttime,DescTime,DescRate,AscTime,' ...
    'AscRate,PDI,DWigglesDesc,DWigglesBott,DWigglesAsc,TotVertDistBot,BottRange,Efficiency,IDZ'];
format_results=['%4.0f, %2.0f, %2.0f, %2.0f, %2.0f, %2.0f, %f, %4.1f, %4.0f, %4.0f, %4.0f, %2.3f,' ...
    ' %4.0f, %2.3f, %5.0f, %3.0f, %3.0f, %3.0f, %3.1f, %3.1f, %1.3f, %1.0f'];
result_string='[timevect;result1';  %divnumb'';
if ismember('alight',variables,'rows')
    header_results=strcat(header_results,',','LightAtBott,LWiggles,LightAtSurf,Lattenuation,EuphoticDepth');
    format_results=strcat(format_results,',','  %4.3f, %3.0f, %4.1f, %3.3f, %3.1f');
    result_string=strcat(result_string,';','result2');
end
if ismember('itemp',variables,'rows') || ismember('etemp',variables,'rows')
    header_results=strcat(header_results,',','TempAtSurf,TempAtBott');
    format_results=strcat(format_results,',','%3.3f, %3.3f');
    result_string=strcat(result_string,';','result3');
end
if ismember('etemp',variables,'rows')
    header_results=strcat(header_results,',','ThermoclineDepth');
    format_results=strcat(format_results,',',' %4.2f');
end
if ismember('speed',variables,'rows')
    header_results=strcat(header_results,',','SwimSpeedDesc,SwimSpeedBott,SwimSpeedAsc,MaxSwimSpeed,TotAccelBott,DescAngle,AscAngle');
    format_results=strcat(format_results,',',' %2.3f, %2.3f, %2.3f, %2.3f, %3.0f, %3.1f, %3.1f');
    result_string=strcat(result_string,';','result4');
end
result_string=strcat(result_string,']');
str3=strcat('fprintf(fid,','''',header_results,'\n'');');
str4=strcat('fprintf(fid,','''',format_results,'\n'',',result_string,');');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAIN LOOP OF PROGRAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
if size(headerline,1)==1  %% this means: file processed in one chunk.
    cut=0;
    block_number=[];
    i=1;

    [fig1,fig2,yr,intervaldepth,intervaltime,ParamLineZoc]=yt_import_and_analyse(yr,N(i,1),headerline(i,1),cut,block_number,overlap,inputfile,...
        finaloutputstatfile,finaloutputrawfile,variables,variables2,format,timemultiple,depthmultiple,depth_zone,wantfile,str3,str4,...
        ZocString,BotString,NightDayLightCutoff,ThermoclineGradient,dataformat,ParamLineBot,ParamLineZoc,version,ProcessTime);
    %N(i,1),headerline(i,1),cut,block_number,chunk_idx,inputfile,outputstatfile,outputrawfile,variables,variables2,
    % format,timemultiple,depthmultiple,method_bt,depth_zone,wantfile,str3,str4

    %% Build parameter lines to be added to output files
    param=yt_getParameters(inputfile,dataformat,ZocString,ParamLineZoc,timemultiple,depthmultiple,depth_zone,...
        ParamLineBot,wantfile,NightDayLightCutoff,ThermoclineGradient,intervaltime,intervaldepth,version,ProcessTime);

    %% Save the output figures so that they will be visible when opened
    set(fig1,'visible','on');
    saveas(fig1,finaloutputfig1file);
    set(fig1,'visible','off');
    set(fig2,'visible','on');
    saveas(fig2,finaloutputfig2file);
    set(fig2,'visible','off');
    close all
    %% open stat file and add the dive number column
    M=readmatrix(finaloutputstatfile,'Range',[2,1]); 
    fileID=fopen(finaloutputstatfile); 
    header=textscan(fileID,'%s',1,'delimiter','\n'); 
    fclose(fileID); 
    M=[(1:size(M,1))',M];
    %% add dive numbers on the figure with analyzed dives
    fig2=open(finaloutputfig2file);
    set(fig2,'visible','off');
    text(M(:,8),-M(:,9),num2str(M(:,1))); 
    set(fig2,'visible','on');
    saveas(fig2,finaloutputfig2file);
    set(fig2,'visible','off');
    close all
    %% save Stat file in its final form
    header_results=['DiveNumber,',header_results,'\n'];
    format_results=[ '%6u,' ,format_results,'\n'];
    M=flipud(rot90(M));
    fid = fopen(finaloutputstatfile,'w');
    fprintf(fid,'%s\n',param{:});
    fprintf(fid,header_results);
    fprintf(fid,format_results,M);
    fclose(fid);
    clear M

else  %%% This is if the file is processed in several chunks
    cut=1;
    statfilelist=[];
    rawfilelist=[];
    for i=1:size(headerline,1)
        outputstatfile=strcat('ImprobableTemporaryFileNameToDelete_',num2str(i),'.csv');
        statfilelist=char(statfilelist,outputstatfile);
        outputrawfile=strcat('ImprobTempRawFileNameToDelete_',num2str(i),'.csv');
        rawfilelist=char(rawfilelist,outputrawfile);
        if i~=size(headerline,1)
            block_number=i;
        else
            block_number=999999;
        end
        [fig1,fig2,yr,intervaldepth,intervaltime,ParamLineZoc]=yt_import_and_analyse(yr,N(i,1),headerline(i,1),cut,block_number,overlap,inputfile,...
            outputstatfile,outputrawfile,variables,variables2,format,timemultiple,depthmultiple,depth_zone,wantfile,str3,str4,...
            ZocString,BotString,NightDayLightCutoff,ThermoclineGradient,dataformat,ParamLineBot,ParamLineZoc,version,ProcessTime);
        %N(i,1),headerline(i,1),cut,block_number,chunk_idx,inputfile,outputstatfile,outputrawfile,variables,variables2,format,
        % timemultiple,depthmultiple,method_bt,depth_zone,wantfile,str3,str4
    end

    %% Save the output figures so that they will be visible when opened
    set(fig1,'visible','on');
    saveas(fig1,finaloutputfig1file);
    set(fig1,'visible','off');
    set(fig2,'visible','on');
    saveas(fig2,finaloutputfig2file);
    set(fig2,'visible','off');
    close all

    %% Put the temporary stat files together
    M=[];
    for i=1:size(headerline,1)
        fil=deblank(statfilelist(i,:));
        N=readmatrix(fil,'Range',[2,1]);
        M=[M;N]; clear N
        if i==1 % not necessary to do this each time.
            fileID=fopen(fil);
            header=textscan(fileID,'%s',1,'delimiter','\n');
            fclose(fileID);
        end
    end
    M=[(1:size(M,1))',M];

    %% add dive numbers on the figure with analyzed dives
    fig2=open(finaloutputfig2file);
    set(fig2,'visible','off');
    text(M(:,8),-M(:,9),num2str(M(:,1))); 
    set(fig2,'visible','on');
    saveas(fig2,finaloutputfig2file);
    set(fig2,'visible','off');
    close all

    %% Build parameter lines to be added to output files
    param=yt_getParameters(inputfile,dataformat,ZocString,ParamLineZoc,timemultiple,depthmultiple,depth_zone,...
        ParamLineBot,wantfile,NightDayLightCutoff,ThermoclineGradient,intervaltime,intervaldepth,version,ProcessTime);

    %% save statfile in its final form
    header_results=['DiveNumber,',header_results,'\n'];
    format_results=[ '%6u,' ,format_results,'\n'];
    M=flipud(rot90(M));
    fid = fopen(finaloutputstatfile,'w');
    fprintf(fid,'%s\n',param{:});
    fprintf(fid,header_results);
    fprintf(fid,format_results,M);
    fclose(fid);
    clear M N

    %% Put the temporary raw files together
    if strcmp(wantfile,'wantfile_yes')
        M=[];
        for i=1:size(headerline,1)
            fil=deblank(rawfilelist(i,:));
            N=readmatrix(fil,'Range',[2,1]); 
            M=[M;N]; 
            clear N
            if i==1 % not necessary to do this each time.
                fileID=fopen(fil); 
                header=textscan(fileID,'%s',1,'delimiter','\n');
                fclose(fileID); 
                header=char(header); 
            end
        end
        format='%4.3f,%7.6f';
        for i=1:size(M,2)-2
            format=[format,',%4.3f'];
        end
        format=[format,'\n'];
        header_results=[header,'\n'];
        M=flipud(rot90(M));
        fid = fopen(finaloutputrawfile,'w');
        fprintf(fid,'%s\n',param{:});
        fprintf(fid,header_results);
        fprintf(fid,format,M);
        fclose(fid);
        clear M N
    end

    delete ImprobableTemporaryFileNameToDelete_*.*
    delete ImprobTempRawFileNameToDelete_*.*
end

%%% END OF MAIN LOOP %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function IKNOS_DA(inputfile,variables2,format,timemultiple,depthmultiple,method_bt,depth_zone,wantfile)

%% CORE FUNCTION OF PROGRAM
function [fig1,fig2,yr,intervaldepth,intervaltime,ParamLineZoc]=yt_import_and_analyse(yr,a,b,cut,block_number,overlap,inputfile,...
    outputstatfile,outputrawfile,variables,variables2,format,timemultiple,depthmultiple,depth_zone,wantfile,str3,str4,...
    ZocString,BotString,NightDayLightCutoff,ThermoclineGradient,dataformat,ParamLineBot,ParamLineZoc,version,ProcessTime)

%% Import
variables2=split(variables2,',');
fid = fopen(inputfile, 'r');
if fid == -1
    error('File not found');
end

try
    output = textscan(fid, format, 'delimiter', ',\t ;/:', 'emptyvalue', NaN, 'HeaderLines', b);
catch
    error(['Error importing the file in yt_import_and_analyse: check for 1) character strings in data field ' ...
        '2) number headerlines (max 2) 3) variable names in the good order 4) delimiter(s) must be: ''tab , ; / :'' (no space)'])
end
fclose(fid);

% Loop through the cell array and create variables
for i = 1:length(variables2)
    eval([variables2{i}, ' = output{i};']);
end
clear output

%%IMPORT: check validity of data for Month Day Hour Minute and Second
if max(Month)>12
    error('Invalid data in variable ''Month''');
end
if max(Day)>31
    error('Invalid data in variable ''Day''');
end
if max(Hour)>23
    error('Invalid data in variable ''Hour''');
end
if max(Minute)>59
    error('Invalid data in variable ''Minute''');
end
if ismember('Second',variables,'rows') && max(Second)>59
    error('Invalid data in variable ''Second''');
end

%% IMPORT: creates Seconds vector if not present in file
if ~ismember('Second',variables,'rows')
    Second=zeros(size(Minute,1),1);
end

%% IMPORT: check Year presence, input Year if absent, format and change
% from 2 digits to 4 digits, calculate time vector
% Note: valid Years between 1970 and 2070 only (can be changed, but
% this partly prevents from funky values)
if ~isempty(yr) % that is if variable Year is absent from file

    Year=ones(size(Minute,1),1).*yr;
    time=datenum(Year,Month,Day,Hour,Minute,Second);
    sig=sign(diff(time));
    idx=find(sig==-1); % Not empty if transition between Year exist in file
    while ~isempty(idx) % change Year if a transition between Year exist in file
        yr=yr+1;
        chk=idx(1,1);
        Year(chk+1:size(Minute,1),1)=yr;
        time=datenum(Year,Month,Day,Hour,Minute,Second);
        sig=sign(diff(time));
        idx=find(sig==-1);
    end

    endtimevector=datevec(time(end));
    yr=endtimevector(1,1);

else % variable Year is present in file
    %% If necessary transform from 2 digits to 4 digits value
    % Valid Years are only between 1971 to 2070
    Year(Year<=70)=Year(Year<=70)+2000;
    Year(Year>70 & Year<100)=Year(Year>70 & Year<100)+1900;
    if ~isempty(Year(Year<=1970)) || ~isempty(Year(Year>2070))
        error('Invalid data in variable ''Year'''); % No electronic TDR record before 1970 !?
    end
    time=datenum(Year,Month,Day,Hour,Minute,Second);
    yr=[];
end
clear Year Month Day Hour Minute Second

%% In case inputa have this Fuc%$#@ AMPM format ! modify it
if ismember(variables,'ampm','rows')
    time(ismember(lower(ampm),'pm','rows'),1)=time(ismember(lower(ampm),'pm',rows),1)+0.5;
end
clear ampm


%%% if the file is cut in pieces (i.e. cut==1)
%%% then we need the time limit for a given block (block_number)
%%% indexes are extracted in "chunk_idx"

if cut==1 && block_number==1
    from_time=time(1,1);
    %     disp(datestr(from_time,0)); % can be used to debug
    if isnan(from_time) % this would be bad luck !
        qw=1+1;         % go down for upper limit
        from_time=time(qw,1);
        while isnan(from_time)
            qw=qw+1;
            from_time=time(qw,1);
        end
    end
    to_time=time( size(time,1)-overlap ,1);
    %         disp(datestr(to_time,0));  % can be used to debug
    if isnan(to_time)  % this would be bad luck !
        qw=size(time,1)-overlap-1; % go up for lower limit
        to_time=time(qw,1);
        while isnan(to_time)
            qw=qw-1;
            to_time=time(qw,1);
        end
    end
elseif cut==1 && block_number==999999 % 999999 is a code for "last block"
    from_time=time(overlap+1,1);  % chunk_idx(size(chunk_idx,1)-1
    %         disp(datestr(from_time,0));  % can be used to debug
    if isnan(from_time)    % this would be bad luck !
        qw=1+overlap+1;
        from_time=time(qw,1);
        while isnan(from_time)
            qw=qw+1;
            from_time=time(qw,1);
        end
    end
    to_time=time(size(time,1),1);
    %             disp(datestr(to_time,0));  % can be used to debug
    if isnan(to_time)  % this would be bad luck !
        qw=size(time,1)-overlap-1;
        to_time=time(qw,1);
        while isnan(to_time)
            qw=qw-1;
            to_time=time(qw,1);
        end
    end
elseif cut==1 && block_number>1 && block_number<999999 % that means intermediate blocks
    from_time=time(overlap+1,1);
    %         disp(datestr(from_time,0)); % can be used to debug
    if isnan(from_time) % this would be bad luck !
        qw=1+overlap*2+1;
        from_time=time(qw,1);
        while isnan(from_time)
            qw=qw+1;
            from_time=time(qw,1);
        end
    end
    to_time=time(size(time,1)-overlap,1);
    %             disp(datestr(to_time,0));  % can be used to debug
    if isnan(to_time)  % this would be bad luck !
        qw=size(time,1)-overlap-1;
        to_time=time(qw,1);
        while isnan(to_time)
            qw=qw-1;
            to_time=time(qw,1);
        end
    end
end

%% IMPORT: create matrix with recognized variables + julian time;
%  adjust variables1, variables2 and colnumber accordingly
%     matrix1=datevec(time);
var_mat1='Year,Month,Day,Hour,Minute,Second';
matrix2=[time,depth];
clear time depth
var_mat2='time,depth';
coltime=1;
coldepth=2;
matrix3=[];
var_mat3='';
var_txt='';
inc=1;
s=size(variables,1);

for i=1:s
    var=deblank(variables(i,:));
    if ~ismember(var,char('Year','Month','Day','Hour','Minute','Second','depth',... % only recognized data variables
            'xa','xb','xc','xd','xe','xf','xg','xh','xi','xj',...
            'ya','yb','yc','yd','ye','yf','yg','yh','yi','yj'),'rows')
        % entering var name this way permits to avoid later modification if the number of data variables changes
        eval(['matrix2=[matrix2',',',var,'];']);
        eval(['clear ',var,]);
        eval(['col',var,'=',num2str(2+inc),';']);
        var_mat2=[var_mat2,',',var];
        inc=inc+1;
    elseif ismember(var,char('xa','xb','xc','xd','xe','xf','xg','xh','xi','xj'),'rows') % only additional numeric variables
        eval(['matrix3=[matrix3',',',var,'];']);
        if isempty(var_mat3)
            var_mat3=var;
        else
            var_mat3=[var_mat3,',',var];
        end
        eval(['clear ',var,]);
    elseif ismember(var,char('ya','yb','yc','yd','ye','yf','yg','yh','yi','yj'),'rows') % only additional text variables
        if isempty(var_txt)
            var_txt=var;
            eval(['clear ',var,]);
        else
            var_txt=[var_txt,',',var];
            eval(['clear ',var,]);
        end
    end
end

%% IMPORT: make a little room!
%  Note: we do not clear text variables
clear chk command1 command2 command3 format Year Month Day Hour Minute Second i idx idxvar j logic1 nbstr
clear potential_variables present sig spv string time var depth itemp etemp alight blight speed salinity inc
clear xa xb xc xd xe xf xg xh xi xj variables2

%%% END of import section --------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Begining of data validity check and analysis

%% IKNOS_DA: take out any rows without depth values or time values
wewant=find(~isnan(matrix2(:,coldepth)) & ~isnan(matrix2(:,coltime)));
%     matrix1=matrix1(wewant,:);
matrix2=matrix2(wewant,:);
if isempty(matrix3)==0
    matrix3=matrix3(wewant,:);
end
if isempty(var_txt)==0
    var_txt=var_txt(wewant,:);
end
clear wewant

%% IKNOS_DA: Check for errors in the time vector
if ~issorted(matrix2(:,coltime))
    matrix2=sortrows(matrix2,coltime);
    %     error('Some input data are not succesive, and/or are repeated');
end

%% IKNOS_DA: depth and time resolution
intervaldepth=resolution_DepthRes(matrix2(:,coldepth));
if intervaldepth<=0.01
    matrix2(:,coldepth)=iknos_round2nearest(matrix2(:,coldepth),0.01);
    intervaldepth=0.01;
elseif intervaldepth>0.01 && intervaldepth<=0.1
    matrix2(:,coldepth)=iknos_round2nearest(matrix2(:,coldepth),0.1);
    intervaldepth=0.1;
elseif intervaldepth>0.1 && intervaldepth<=0.2
    matrix2(:,coldepth)=iknos_round2nearest(matrix2(:,coldepth),0.2);
    intervaldepth=0.2;
elseif intervaldepth>0.2 && intervaldepth<=0.3
    matrix2(:,coldepth)=iknos_round2nearest(matrix2(:,coldepth),0.3);
    intervaldepth=0.3;
elseif intervaldepth>0.3 && intervaldepth<=0.4
    matrix2(:,coldepth)=iknos_round2nearest(matrix2(:,coldepth),0.4);
    intervaldepth=0.4;
elseif intervaldepth>0.4 && intervaldepth<=0.5
    matrix2(:,coldepth)=iknos_round2nearest(matrix2(:,coldepth),0.5);
    intervaldepth=0.5;
end

disp(['Interval depth == ',num2str(intervaldepth)]);
intervaltime=resolution_SamplingRate(round(matrix2(:,coltime).*86400));

%% IKNOS_DA: correct depth values
% disp(['[depth2,correction]=iknos_zoc(matrix2(:,coltime),matrix2(:,coldepth)',ZocString,');']); %can be used to debug
eval([ '[depth2,correction]=iknos_zoc(matrix2(:,coltime),matrix2(:,coldepth)',ZocString,');']);

% %% IKNOS_DA: Plot to check the zero offset correction
fig1=figure(1);
set(fig1,'visible','off');
plot(matrix2(:,coltime),-matrix2(:,coldepth),'ob-');
hold on;
plot(matrix2(:,coltime),-correction','-r'); %zocvalue
hold on , datetick('x',1) , grid on
plot(matrix2(:,coltime),-depth2,'g'); % added by Arina

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    THE "CREATE RAW DATA FILE" SECTION-----------------------------------
%% IKNOS_DA: Create raw data file with corrected depth at the beginning
%  create raw data file if strcmp(outfile,'outfile_yes')==1

if strcmp(wantfile,'wantfile_yes')

    %% CREATE RAW DATA FILE: first: chunk to the non overlapped part of the data
    % reminder: matrix1 is 6 columns time matrix, matrix2 is recognized var,
    % matrix3 is other numeric variables, var_
    if cut==1  %% if file is chunked in several pieces
        wanted=find(matrix2(:,coltime)>=from_time & matrix2(:,coltime)<to_time);
        %         bigcell=[num2cell(depth2(wanted,:)),num2cell(matrix2(wanted,:))];
        %         if ~isempty(matrix3);
        %             bigcell=[bigcell,num2cell(matrix3(wanted,:))];
        %         end
        % %         if ~isempty(var_txt);
        % %             bigcell=[bigcell,cellstr(var_txt(wanted,:))];
        % %         end
        %     else  %% this is if file processed in one chunk
        %         bigcell=[num2cell(depth2),num2cell(matrix2)];
        %         if ~isempty(matrix3);
        %             bigcell=[bigcell,num2cell(matrix3)];
        %         end
        % %         if ~isempty(var_txt);
        % %             bigcell=[bigcell,cellstr(var_txt)];
        % %         end
    end

    %% CREATE RAW DATA FILE: minimum manipulations
    header=['CorrectedDepth',',',var_mat2]; % minimum output possible
    format2='%4.1f'; % minimum output possible
    for i=1:size(matrix2,2)
        format2=[format2,',','%f'];
    end
    %due to weird fprintf way of putting in text, need to flip output around
    matrix2=flipud(rot90(matrix2));

    %% CREATE RAW DATA FILE: if some extra numeric variables exist
    if ~isempty(matrix3)
        header=[header,',',var_mat3];
        for i=1:size(matrix3,2)
            format2=[format2,',','%4.3f'];
        end
        matrix3=flipud(rot90(matrix3));
    end

    %% CREATE RAW DATA FILE: Create str1 and str2 for writing the file after evaluation.
    str1=['fprintf(fid,','''',header,'\n'');'];

    if isempty(matrix3)% & isempty(var_txt);
        if cut==1
            str2=['fprintf(fid,','''',format2,'\n'',','[(depth2(wanted,1))'';matrix2(:,wanted)]);'];
        else
            str2=['fprintf(fid,','''',format2,'\n'',','[(depth2)'';matrix2]);'];
        end
    else
        if cut==1
            str2=['fprintf(fid,','''',format2,'\n'',','[(depth2(wanted,1))'';matrix2(:,wanted);matrix3(:,wanted)]);'];
        else
            str2=['fprintf(fid,','''',format2,'\n'',','[depth2'';matrix2;matrix3]);'];
        end
    end

    %% CREATE RAW DATA FILE: Write the file
    if cut==1
        fid=fopen(outputrawfile,'w');
        eval(str1);
        eval(str2);
        fclose(fid);
        disp(['Raw data file saved: ',outputrawfile]);
    else
        % Build parameter lines to be added to output files
        param=yt_getParameters(inputfile,dataformat,ZocString,ParamLineZoc,timemultiple,depthmultiple,depth_zone,...
            ParamLineBot,wantfile,NightDayLightCutoff,ThermoclineGradient,intervaltime,intervaldepth,version,ProcessTime);

        fid=fopen(outputrawfile,'w');
        fprintf(fid,'%s\n',param{:});
        eval(str1);
        eval(str2);
        fclose(fid);
        disp(['Raw data file saved: ',outputrawfile]);

    end
    %% matrix2 comes back to its initial stage
    matrix2=flipud(rot90(matrix2));

else
    disp('Raw data file NOT saved.')
end

% End of the "create raw data file section"-----------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% IKNOS_DA: Cleanup and release memory
clear   ya yb yc yd ye yf yg yh yi yj fileout matrix1 matrix3  var_txt
clear var_mat1 var_mat3 string2  inc header zocvalue format2 bigcell

% IKNOS_DA: find diving data and reduce matrix accordingly
[want,newdepth,dt]=iknos_find_dive(matrix2(:,coltime),timemultiple,depth2,depthmultiple);
if ~isempty(dt)
    matrix2(:,coldepth)=newdepth(:,1);
    id1=dt(:,2)-dt(:,1)+1;
    id2=cumsum(id1);
    id3=[1;id2(1:size(id2,1)-1,1)+1];
    clear dt;
    dt=[id3,id3+id1-1];
    matforplot=[matrix2(:,coltime),matrix2(:,coldepth)];
    matrix=matrix2(want,:);
    clear want depth2 newdepth matrix2

    %% IKNOS_DA: add surface zero values if they do not exist.
    firstnonzero=matrix( dt(matrix(dt(:,1),coldepth)>intervaldepth,1) ,:);
    lastnonzero=matrix( dt(matrix(dt(:,2),coldepth)>intervaldepth ,2) ,:);
    if isempty(firstnonzero)==0
        firstnonzero(:,1)=firstnonzero(:,1)-(intervaltime./86400);
        firstnonzero(:,2)=0;
    end
    if isempty(lastnonzero)==0
        lastnonzero(:,1)=lastnonzero(:,1)+(intervaltime./86400);
        lastnonzero(:,2)=0;
    end
    matrix=sortrows([matrix;firstnonzero;lastnonzero],1);
    clear firstnonzero lastnonzero ;

    %% IKNOS_DA: Re-calculate dive start and end indexes (dt, 2 columns)
    dt=[];
    as=matrix(:,coldepth)~=0; %% at this stage, each dive should have a zero at the begining and the end
    dt=iknos_setones(as); clear as;

    dt(:,1)=dt(:,1)-1;
    dt(:,2)=dt(:,2)+1;

    chkvector=ones(size(dt,1),1);
    for i=1:size(dt,1)
        if max(matrix(dt(i,1):dt(i,2),coldepth))<depthmultiple*intervaldepth
            matrix(dt(i,1):dt(i,2),coldepth)=0;
            chkvector(i)=0;
        end
    end
    dt=dt(find(chkvector),:);

    % IKNOS_DA: find start and end indexes of bottom phases (bt, 2 columns)
    % disp(['bt=iknos_find_bottom(matrix',BotString,');']); %use to debug
    eval(['bt=iknos_find_bottom(matrix',BotString,');']);

    %% IKNOS_DA: Plot to check dive selection and dive handles
    fig2=figure(2);
    set(fig2,'visible','off');
    plot(matforplot(:,1),-matforplot(:,2),'-ob','MarkerSize',3) , hold on , plot(matrix(dt(:,1),coltime),-matrix(dt(:,1),coldepth),'gs','MarkerFaceColor','g') , ...
        hold on , plot(matrix(dt(:,2),coltime),-matrix(dt(:,2),coldepth),'dy','MarkerFaceColor','y'),...
        hold on , plot(matrix(bt(:,1),coltime),-matrix(bt(:,1),coldepth),'or',matrix(bt(:,2),coltime),-matrix(bt(:,2),coldepth),'or','MarkerFaceColor','r'),...
        hold on , datetick('x',1), grid on

    %% IKNOS_DA: Create cell array for analysis
    for i=1:size(dt,1)
        tab{i,1}=matrix(dt(i,1):dt(i,2),:) ; % first col : data all dive
        tab{i,2}=matrix(dt(i,1):bt(i,1),:) ; % Second col : data descent phase
        tab{i,3}=matrix(bt(i,1):bt(i,2),:) ; % third col : data bottom phase
        tab{i,4}=matrix(bt(i,2):dt(i,2),:) ; % fourth col : data ascent phase
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% IKNOS_DA: results calculation

    %%%%%%%%%%% BASIC PARAMETERS %%%%%%%%%%%%%%
    for i=1:size(dt,1)
        %% PDI
        if i~=size(dt,1)
            pdi=round( (tab{i+1,1}(1:coltime) - max(tab{i,1}(:,coltime))) * 86400 ) ;
        else
            pdi=NaN ;
        end
        %% IDZ
        if i==1
            idz=0;
        else
            idz= max(tab{i,1}(:,coldepth))>max(tab{i-1,1}(:,coldepth))-max(tab{i-1,1}(:,coldepth))*(depth_zone/2)/100 &...   % IDZ=logic array 0 or 1
                max(tab{i,1}(:,coldepth))<max(tab{i-1,1}(:,coldepth))+max(tab{i-1,1}(:,coldepth))*(depth_zone/2)/100 ;
        end

        %%%%%%%%%%%%  basic (minimum) parameters  %%%%%%%%%%%%%%%%%%%%%%
        result1(i,:)=[  tab{i,1}(1:coltime) , ...                                    % dive time
            max(tab{i,1}(:,coldepth)) , ...                                          % max depth
            (size(tab{i,1}(:,coltime),1)-1)*intervaltime , ...                       % dive duration (s)
            (size(tab{i,3}(:,coltime),1)-1)*intervaltime , ...                       % bott time (s)
            (size(tab{i,2}(:,coltime),1)-1)*intervaltime , ...                       % descent time
            max(tab{i,2}(:,coldepth)) / ((size(tab{i,2}(:,coltime),1)-1)*intervaltime) , ...  % descent rate
            (size(tab{i,4}(:,coltime),1)-1)*intervaltime , ...                       % ascent time
            max(tab{i,4}(:,coldepth)) / ((size(tab{i,4}(:,coltime),1)-1)*intervaltime) , ...  % asccent rate
            pdi  , ...                                                               % PDI
            iknos_count_wiggles(sign(diff(tab{i,2}(:,coldepth))))  , ...             % Depth Wiggles Descent
            iknos_count_wiggles(sign(diff(tab{i,3}(:,coldepth))))  , ...             % Depth Wiggles Bot
            iknos_count_wiggles(sign(diff(tab{i,4}(:,coldepth))))  , ...             % Depth Wiggles Ascent
            sum(abs(diff(tab{i,3}(:,coldepth)))) ,...                                % TotVertDistBot
            max(tab{i,3}(:,coldepth))-min(tab{i,3}(:,coldepth)) , ...                % BottRange
            ((size(tab{i,3}(:,coltime),1)-1)*intervaltime)/(pdi+(size(tab{i,1}(:,coltime),1)-1)*intervaltime),...  % Efficiency
            idz ] ;

        %%%%%%%%%%% CONDITIONAL PARAMETERS %%%%%%%%%%%%%%
        %% ALIGHT
        if ismember('alight',variables,'rows')
            dat=tab{i,3}(~isnan(tab{i,3}(:,colalight)) ,colalight);
            dat2=tab{i,1}(~isnan(tab{i,3}(:,colalight)) ,coldepth);
            dat3=tab{i,1}(~isnan(tab{i,3}(:,colalight)) ,colalight);
            if ~isempty(dat)
                mla=mean(dat);  % Mean light at bottom
                lw=iknos_count_wiggles(sign(diff(dat))); % Light Wiggles
            else
                mla=NaN;
                lw=NaN;
            end
            [surfLL,kLL,eud]=iknos_euphotic_depth([dat2,dat3],NightDayLightCutoff);
            result2(i,:)=[mla , lw, surfLL, kLL, eud];
            clear dat
        end

        %% ITEMP or ETEMP
        if ismember('itemp',variables,'rows') && ~ismember('etemp',variables,'rows')
            dat=tab{i,3}(~isnan(tab{i,3}(:,colitemp)) ,colitemp);
            dat2=tab{i,2}(~isnan(tab{i,2}(:,colitemp)) ,colitemp);
            if ~isempty(dat)
                taeob=dat(size(dat,1),1);
            else
                taeob=NaN;
            end

            if ~isempty(dat2)
                sst=dat2(1,1);
            else
                sst=NaN;
            end
            result3(i,:)=[sst , taeob ]; % Temperature at beginning of dive and at end of Bottom (alternative Temp inertia high)

            clear dat  dat2

        elseif ismember('etemp',variables,'rows')
            dat=tab{i,3}(~isnan(tab{i,3}(:,coletemp)) ,coletemp);
            dat2=tab{i,2}(~isnan(tab{i,2}(:,coletemp)) ,coletemp);
            dat3=[tab{i,3}(~isnan(tab{i,3}(:,coletemp)) ,coldepth);tab{i,4}(~isnan(tab{i,4}(:,coletemp)) ,coldepth)];
            dat4=[tab{i,3}(~isnan(tab{i,3}(:,coletemp)) ,coletemp);tab{i,4}(~isnan(tab{i,4}(:,coletemp)) ,coletemp)];
            if ~isempty(dat)
                taeob=mean(dat);
            else
                taeob=NaN;
            end

            if ~isempty(dat2)
                sst=dat2(1,1);
            else
                sst=NaN;
            end

            TD=iknos_thermocline_depth([dat3 dat4],ThermoclineGradient);

            result3(i,:)=[sst , taeob , TD]; % Temperature at beginning of dive and at end of Bottom (alternative Temp inertia low)
            clear dat dat2
        end

        %% SPEED
        if ismember('speed',variables,'rows')

            dat1=tab{i,1}(~isnan(tab{i,1}(:,colspeed)) ,colspeed);
            if ~isempty(dat1)
                ms=max(dat1) ;
            else
                ms=NaN ;
            end
            dat2=tab{i,2}(~isnan(tab{i,2}(:,colspeed)) ,colspeed);
            if ~isempty(dat2) && mean(dat2)~=0
                mssd=mean(dat2);
                da=rad2deg(real(asin( max(tab{i,2}(:,coldepth))/ (mssd*(size(tab{i,2}(:,coltime),1)-1)*intervaltime)))) ;
            elseif  ~isempty(dat2) && mean(dat2)==0
                mssd=mean(dat2);
                da=NaN ;
            else
                mssd=NaN ;
                da=NaN ;
            end
            dat3=tab{i,3}(~isnan(tab{i,3}(:,colspeed)) ,colspeed);
            if ~isempty(dat3)
                mssb=mean(dat3) ;
                soa=sum(sign(diff(dat3))==1);
            else
                mssb=NaN ;
                soa=NaN ;
            end

            dat4=tab{i,4}(~isnan(tab{i,4}(:,colspeed)) ,colspeed);
            if ~isempty(dat4) && mean(dat4)~=0
                mssa=mean(dat4) ;
                aa=rad2deg(real(asin( max(tab{i,4}(:,coldepth))/ (mssa*(size(tab{i,4}(:,coltime),1)-1)*intervaltime))));
            elseif ~isempty(dat4) && mean(dat4)==0
                mssa=mean(dat4) ;
                aa=NaN ;
            else
                mssa=NaN ;
                aa=NaN ;
            end

            result4(i,:)=[mssd , ...   % Mean swim speed descent
                mssb , ...             % Mean swim speed bottom
                mssa , ...             % Mean swim speed asccent
                ms , ...               % Max speed
                soa ,...               % Sum of accelerations during bottom
                da ,...                % Descent Angle (from surface)
                aa];                   % Ascent Angle (from surface)
            clear dat1 dat2 dat3 dat4
        end
    end

    %% Prepare writing
    %     timevect=round( datevec( matrix(dt(:,1),1) ,0)  ) ;
    timevect=round( datevec( matrix(dt(:,1),1) )  ) ;
    if cut==1
        wanted=find(result1(:,1)>=from_time & result1(:,1)<to_time);
        timevect=timevect(wanted,:);
        result1=result1(wanted,:);
    end
    result1 = flipud(rot90(result1));
    timevect = flipud(rot90(timevect));

    if ismember('alight',variables,'rows')
        if cut==1
            result2=result2(wanted,:);
        end
        result2 = flipud(rot90(result2));
    end

    if ismember('itemp',variables,'rows') || ismember('etemp',variables,'rows')
        if cut==1
            result3=result3(wanted,:);
        end
        result3 = flipud(rot90(result3));
    end

    if ismember('speed',variables,'rows')
        if cut==1
            result4=result4(wanted,:);
        end
        result4 = flipud(rot90(result4));
    end

    %% Write statfile
    fid = fopen(outputstatfile,'w');
    eval(str3);
    eval(str4);
    fclose(fid);

else
    %% IKNOS_DA: Plot to check dive selection and dive handles
    fig2=figure(2);
    set(fig2,'visible','off');
    fid = fopen(outputstatfile,'w');
    fclose(fid);
end

%% FUNCTION : GET PARAMETERS
function param=yt_getParameters(inputfile,dataformat,ZocString,ParamLineZoc,timemultiple,depthmultiple,depth_zone,...
    ParamLineBot,wantfile,NightDayLightCutoff,ThermoclineGradient,intervaltime,intervaldepth,version,ProcessTime)

param = sprintf('%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s',...
    '%[FILE/FORMAT]',...
    ['%   Input file = ', inputfile ],...
    ['%   Input Data Format = ', dataformat],...
    '%[ZERO OFFSET CORRECTION]',...
    ParamLineZoc,...
    '%[DIVE ANALYSIS]',...
    ['%   TimeMultiple = ',num2str(timemultiple) ],...
    ['%   DepthMultiple = ',num2str(depthmultiple)],...
    ['%   DepthZone = ',num2str(depth_zone)],...
    ParamLineBot,...
    ['%   WantFile = ', wantfile],...
    ['%   NightDayLightCutoff = ',num2str(NightDayLightCutoff)],...
    ['%   ThermoClineGradient = ',num2str(ThermoclineGradient)],...
    '%[INFORMATION]',...
    ['%   Sampling Interval = ',num2str(intervaltime),' s'],...
    ['%   Depth Resolution = ',num2str(intervaldepth),' m'],...
    ['%   Minimum Duration of analyzed dives: ',num2str(timemultiple*intervaltime),' s'],...
    ['%   Minimum Depth of analyzed dives: ',num2str(depthmultiple*intervaldepth),' m'],...
    ['%   Date and Time Processed (Computer Time) = ', char(ProcessTime) ],...
    '%[VERSION]',...
    ['%   Program Version = ', version ],...
    '%');

param=cellstr(param);

%% END of main Function
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%