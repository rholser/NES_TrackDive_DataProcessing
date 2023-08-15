
function [depth2,correction,ParamLineZoc]=iknos_zoc(time,depth,varargin)
%% YT_ZOC is an internal function to the YT_IKNOS_DA.M function.
% This is the section that Zero Offset the depth data series.
%
% Example varargin inputs to zoc:
%
%     'ZocMinMax'  ,  [-10 2500]  % values out of this depth range (m) will be trimmed
%
%     'ZocWindow'  ,  'auto'   % Input needs to be in hours. Used to find approximate
%       depth surface. Value should be at least the longest expected dive
%       cycle for the species. Default value ('auto') will calculate a window
%       using the maximum depth in the file and a descent dpees of 0.5 m/s.
%
%     'ZocSpeedFilter'  ,  5      % maximum allowable speed for vertical 
%       movement, in m/s. If exceeded, adjacent values will be averaged to
%       replace erroneous measurement (bad sensor readings)
%
%     'ZocWidthForMode'  ,  'auto'   % the search for an approximate surface 
%       is restricted to between the minimum (shallowest) value defined in 
%       'ZocMinMax' and 'ZocWidthForMode'. This excludes the bottom of
%       dives, where repeated similar depths could appear as a "surface".
%       This value has the unit "number of times depth resolution." 
%
%     'ZocModeMax'  ,  ZocWidthForMode/2    % Limit for the approximate
%       surface value. Default assumes that surface will be not be below half
%       of ZocWidthForMode. Unit is "number of times depth resolution."
%
%     'ZocSurfWidth'  ,  'auto'    % all data points below "approximate
%       surface + ZocSurfWidth" belong to a dive and not a surface segment.
%       Unit is "number of times depth resolution." This is used to define
%       precise surfaces dive by dive after finding the approximate surface
%       using ZocWidthForMode.
%
%     'ZocDiveSurf'  ,  6     % Default value is 6, unit is "number of
%       times depth resolution." Surface point at the beginning and end of
%       each dive must be betweeen "approximate surface" and "approximate
%       surface + ZocDiveSurf."
%
% CREDIT:
% Created sometime in 2003 or 2004, by Yann Tremblay (The IKNOS toolbox).
% need: iknos_resolution iknos_setones
%
% VERSION: 2.0
%
%  Modified 09-Dec-2022 (Arina Favilla): changed iknos_resolution() to
%                                        either resolution_DepthRes() or resolution_SamplingRate(),
%                                        added ParamLineZoc to output
%  Renamed 16-Dec-2022 (Arina Favilla): renamed from yt_zoc to zoc 
%  Modified 17-Dec-2022 (R. Holser): replaced strvcat with char
%                                    added documentation of varargin inputs
%                                    removed some code that was commented out
%   Modified 03-Aug-2023 (R.Holser): replaced "yt_" function names with
%                                   "iknos_" names


ZocMinMax=[-10 2500];
ZocWindow='auto';
ZocSpeedFilter=5;
ZocWidthForMode='auto'; % unit is "number of times depth resolution"
ZocModeMax=ZocWidthForMode/2; % unit is "number of times depth resolution"
ZocSurfWidth='auto';
ZocDiveSurf=6;
ParamLineZoc=''; 

if nargin>2
    try
        for i=1:2:size(varargin,2)-1
            if  ismember(varargin{i},char('ZocMinMax','ZocWindow','ZocSpeedFilter','ZocWidthForMode','ZocModeMax','ZocSurfWidth','ZocDiveSurf'),'rows')
                eval([varargin{i},'=[',num2str(varargin{i+1}),'];']);
            else   
                error('  ')
            end
        end
    catch
        error('Illegal optional inputs for function iknos_zoc');
    end
end

ParamLineZoc=char(ParamLineZoc,['%   ', 'ZocMinMax' , ' = [' num2str(ZocMinMax) ,']' ]); % added by Arina

% dept=find(depth>ZocMinMax(1,1) & depth<ZocMinMax(1,2));
% maxd=max(depth(find(depth>ZocMinMax(1,1) & depth<ZocMinMax(1,2)),1));
if strcmpi(ZocWindow,'auto')
    ZocWindow=max(depth(depth>ZocMinMax(1,1) & depth<ZocMinMax(1,2),1))/0.5*3/3600;
    if ZocWindow<(1/12) %% that is 5 minutes
        ZocWindow=1/12;
    end
    ParamLineZoc=char(ParamLineZoc,['%   ', 'ZocWindow' , ' = ' num2str(ZocWindow) ]); % added by Arina
end
disp(['ZOC_window=',num2str(ZocWindow*60),' minutes.']);

%%---Time checking
time=round(time.*86400); % time in seconds.
intervaltime=resolution_SamplingRate(time);
startime=min(time);
endtime=max(time);
time=time-startime; % just to reduce numbers and memory usage and eventually use time as index values
s=size(time,1);
% Does sampling is continuous (1) or not (0) ??
if sum(diff(time))/intervaltime==s-1
    continuous=1;
else 
    continuous=0;
end

%%---Get minimum interval depth (i.e. Depth resolution)
intervaldepth=resolution_DepthRes(depth);

    if intervaldepth<0.1
        depth=iknos_round2nearest(depth,0.1);
        intervaldepth=0.1;
    elseif intervaldepth>0.1 && intervaldepth<0.2
         depth=iknos_round2nearest(depth,0.2);
         intervaldepth=0.2;
    elseif intervaldepth>0.2 && intervaldepth<0.3
         depth=iknos_round2nearest(depth,0.3);
         intervaldepth=0.3;
    elseif intervaldepth>0.3 && intervaldepth<0.4
         depth=iknos_round2nearest(depth,0.4);
         intervaldepth=0.4;
    elseif intervaldepth>0.4 && intervaldepth<0.5
         depth=iknos_round2nearest(depth,0.5);
         intervaldepth=0.5;
    end

%%----Depth validity check
depth=iknos_takeoutspikes(depth,intervaldepth); % just for sensor hysteresis

% Valid depths only
test1=depth<ZocMinMax(1,1) | depth>ZocMinMax(1,2) ;
if sum(test1)~=0
    tocheck1=iknos_setones(test1);
    for i=1:size(tocheck1,1)
        if tocheck1(i,1)==1
            depth(tocheck1(i,1):tocheck1(i,2),1)=depth(tocheck1(i,2)+1,1);
        elseif tocheck1(i,2)==size(depth,1)
            depth(tocheck1(i,1):tocheck1(i,2),1)=depth(tocheck1(i,1)-1,1);
        else
            bat=(depth(tocheck1(i,1)-1,1)+depth(tocheck1(i,2)+1,1))/2;
            if intervaldepth<1
                depth(tocheck1(i,1):tocheck1(i,2),1)=floor(bat)+ (round( (bat-floor(bat))./ intervaldepth ).* intervaldepth) ;
            else
                depth(tocheck1(i,1):tocheck1(i,2),1)=round(bat);
            end
        end
    end
    disp(['Some data out of range [ ',num2str(ZocMinMax(1,1)),' to ',num2str(ZocMinMax(1,2)),' ] have been corrected.']);
end
clear test1 tocheck1 bat

% Ascent/descent rate filter
test2=abs(diff(depth))>=intervaltime*ZocSpeedFilter;  %% no more than 'ZocSpeedFilter' m/s between 2 points
if sum(test2)~=0
    tocheck2=iknos_setones(test2,2);
    for i=1:size(tocheck2,1)
        bet=(depth(tocheck2(i,1),1)+depth(tocheck2(i,2)+1,1))/2 ;
        if intervaldepth<1
            depth(tocheck2(i,1)+1:tocheck2(i,2),1)=floor(bet)+ (round( (bet-floor(bet))./ intervaldepth ).* intervaldepth) ;
        else depth(tocheck2(i,1)+1:tocheck2(i,2),1)=round(bet);
        end
    end
    disp('Some spikes in the depth data have been corrected');
end
clear test2 tocheck2 bet

%%---------------------------
% Create the grid vector. Grid represent indexes
if continuous==1
    if endtime-startime>(ZocWindow*3600)
       grid=(1:(ZocWindow*3600):(time(s,1)/intervaltime)+1 )' ;
       if grid(size(grid,1),1)<(time(s,1)/intervaltime)+1
           grid=[grid ; s];
       end
    else 
        grid=[1 ; s];
    end
else
    if s>(ZocWindow*3600)/intervaltime
       grid=(1:(ZocWindow*3600)/intervaltime:s)' ;
       if grid(size(grid,1),1)<s
           grid=[grid ; s];
       end
    else 
        grid=[1 ; s];
    end
end
fin=size(grid,1);   
grid=round(grid);

%%-------------------------------------------------------
%% Find approx surface within the grid bin
surface1=[];
for i=1:fin-1
    depthmat=depth(grid(i,1):grid(i+1,1),1); % depth section by section
    minimum=min(depthmat);
    maxd=max(depthmat);

    %Automated ZocWidthForMode calculation
    if strcmpi(ZocWidthForMode,'auto')
        if maxd<=15
            if intervaldepth<1
                ZocWidthForMode=3*intervaldepth;
            else
                ZocWidthForMode=1.5*intervaldepth;
            end
        elseif maxd>=15 && maxd<=50
            if intervaldepth<1
                ZocWidthForMode=5*intervaldepth;
            else
                ZocWidthForMode=2.5*intervaldepth;
            end
        elseif maxd>=50 && maxd<=100
            if intervaldepth<1
                ZocWidthForMode=10*intervaldepth;
            else
                ZocWidthForMode=5*intervaldepth;
            end
        else %% maxd>=100
            if intervaldepth<1
                ZocWidthForMode=40*intervaldepth;
            else
                ZocWidthForMode=20*intervaldepth;
            end
        end
        ParamLineZoc=strvcat(ParamLineZoc,['%   ', 'ZocWidthForMode' , ' = ' num2str(ZocWidthForMode) ]); % added by Arina
    end

    loopmat=depthmat(depthmat<=(minimum+ZocWidthForMode),1); % Approx surface values
    % We find the mode of the surface values in the section
    add=iknos_findmode(loopmat,intervaldepth);
    flag=0;
    if add<=ZocMinMax(1,1)/2  %% this is to avoid future problems with weird negative spikes
        depth(grid(i,1)+find(depthmat<add)-1,1)=mean(loopmat) ;
        flag=1;
    end

    %%% Added June 29 2004 (for Turtle data)
    %     if add>=minimum+4*intervaldepth
    %         add=minimum+2*intervaldepth;
    %     end
    %%%%% end of added part%%%%%%

    % this is a constraint on "the aproximate surface value"
    % to avoid repeated values of bottom time of shallow dives
    % to be considered as surface.
    if add>=minimum+ZocModeMax*intervaldepth
        add=minimum+2*intervaldepth;
    end

    surface1=[surface1 ; add];
    clear depthmat loopmat minimum add
end
if flag==1
    disp('Some "surface data" were >= 5 meters in the air, and have been changed. Please check on graph if OK.');
end

clear depthmat loopmat minimum add flag

%---------------------
%% Create "limit" which is the threshold between dive and surface
limit=zeros(s,1);
for i=1:fin-1 % fin is the size of the grid
    a=grid(i,1);
    b=grid(i+1,1);
    minimum=min(depth(a:b,1));

    maximum1=max(depth(a:round((b-(b-a)/2)),1)); % first half of the depth data in this grid
    a1=find(depth(a:round((b-(b-a)/2)),1)==maximum1);
    a1=a1(1,1);
    maximum2=max(depth(round(a+(b-a)/2):b,1)); % second half of the depth data in this grid
    a2=find(depth(round(a+(b-a)/2):b,1)==maximum2);
    a2=a2(size(a2,1),1);
    diffmax=abs(maximum1-maximum2);
    if maximum1>=maximum2 && a1~=a && diffmax<10
        maximum=maximum1;
    elseif maximum2>maximum1 && a2~=b && diffmax<10
        maximum=maximum2;
    else
        maximum=max([maximum1,maximum2]);
    end

    if strcmp(ZocSurfWidth,'auto')
        if maximum<=5
            ZocSurfWidth=1;
        elseif maximum>5 && maximum<=10
            ZocSurfWidth= round(((maximum-minimum)/intervaldepth)/8); %% /8 means the upper 12.5%
        elseif   maximum>10 && maximum<=50
            ZocSurfWidth=round(((maximum-minimum)/intervaldepth)/10); %% /10 means the upper 10%
        elseif   maximum>50 && maximum<=100
            ZocSurfWidth=round(((maximum-minimum)/intervaldepth)/15); %% /15 means the upper 7.5%
        elseif   maximum>100 && maximum<=300
            ZocSurfWidth=round(((maximum-minimum)/intervaldepth)/20); %% /20 means the upper 5%
        else
            ZocSurfWidth=round(((maximum-minimum)/intervaldepth)/40); %% /40 means we search in the upper 2.5%
        end
        ParamLineZoc=strvcat(ParamLineZoc,['%   ', 'ZocSurfWidth' , ' = ' num2str(ZocSurfWidth) ]); % added by Arina
    end

    threshold=ZocSurfWidth*intervaldepth ;
    limit(a:b,1)=surface1(i,1)+threshold; % +threshold this is a floating limit for dive/surface detection within ZocWindow
end
    
clear a b  mult a1 a2 maximum1 maximum2 maximum minimum %------------
find_surf=zeros(s,1); % s is the size of the input data
find_surf(depth<limit,1)=1;
clear limit surface1 %------------------------------

bornes=iknos_setones(find_surf,3);
sbornes=size(bornes,1);
clear find_surf

 %-----Create surface and surf_tim: They are XY variables for further interpolation of surface values 

 ParamLineZoc=strvcat(ParamLineZoc,['%   ', 'ZocDiveSurf' , ' = ' num2str(ZocDiveSurf) ]); % added by Arina

 surface=[];
 surf_tim_idx=[];
 for i=1:sbornes
     a=bornes(i,1); b=bornes(i,2);
     depthmat=depth(a:b,1);
     minimum=min(depthmat);
     surfdiff=diff(depthmat);
     abssurfdiff=abs(surfdiff);
     surfsign=sign(surfdiff);

     idx1= find( surfsign==1 & depthmat(1:size(depthmat,1)-1,1)<=(min(depthmat)+ZocDiveSurf*intervaldepth));
     if isempty(idx1)
         idx1=999999;
     else
         idx1=idx1(1,1);
     end

     idx5=find(surfsign==-1 & depthmat(1:size(depthmat,1)-1,1)<=(min(depthmat)+ZocDiveSurf*intervaldepth));
     if isempty(idx5)
         idx5=-999999;
     else
         idx5=idx5(size(idx5,1),1)+1;
     end

     want=find(abssurfdiff<mean(abssurfdiff)/2 & abssurfdiff~=0);
     if isempty(want)
         idx2=999999;
         idx6=-999999;
     else
         idx2=want(1,1);
         idx6=want(size(want,1),1);
     end

     want2=find(depthmat==minimum);
     if isempty(want2)
         idx3=999999;
         idx7=-999999;
     else
         idx3=want2(1,1);
         idx7=want2(size(want2,1),1);
     end

     want3=surfsign==0;
     if sum(want3)==0
         idx4=999999;
         idx8=-999999;
     elseif isempty(iknos_setones(want3,2))
         idx=iknos_setones(want3);
         ix=find(depthmat(idx(:,1),1)<=minimum+ZocDiveSurf*intervaldepth);
         if isempty(ix)==0
             idx4=idx(ix(1,1),1);
             idx8=idx(ix(size(ix,1),1),2);
         else
             idx4=999999;
             idx8=-999999;
         end
     else
         idx=iknos_setones(want3,2);
         ix=find(depthmat(idx(:,1),1)<=minimum+ZocDiveSurf*intervaldepth);
         if isempty(ix)==0
             idx4=idx(ix(1,1),1);
             idx8=idx(ix(size(ix,1),1),2);
         else
             idx4=999999;
             idx8=-999999;
         end
     end

     idxdeb=min([idx1, idx2, idx3, idx4]); %
     if idxdeb==999999 % this should never happen... but...
         idxdeb=1;
     end

     idxfin=max([idx5, idx6, idx7, idx8]);  %
     if idxfin==-999999 % this should never happen... but...
         idxfin=size(depthmat,1);
     end
     clear depthmat idx1 idx2 idx3 idx4 idx5 idx6 idx7 idx8 idx want want2 want3

%--find Surface and surf_tim    
    surface(size(surface,1)+1,1)=depth(a+idxdeb-1,1)    ;
    surf_tim_idx(size(surf_tim_idx,1)+1,1)=a+idxdeb-1     ;   
    surface(size(surface,1)+1,1)=depth(a+idxfin-1,1)    ;
    surf_tim_idx(size(surf_tim_idx,1)+1,1)=a+idxfin-1     ;   
    
    clear idxdeb idxfin
end       
clear minimum bin bin2 add count

surface=[surface(1,1);surface;surface(size(surface,1),1)];
tim_surf=[time(1,1);time(surf_tim_idx,1);time(s,1)];

[temp1,temp2,~]=unique(tim_surf);
tim_surf=temp1;
surface=surface(temp2,1);
clear temp1 temp2

if continuous==1
    tim_surf=tim_surf./time(s,1);
    hermite=pchip(tim_surf',100+surface');
    correction=ppval(hermite,(time./time(s,1))')-100;
    clear tim_surf hermite time
else
    tim_surf=tim_surf./time(s,1);
    tim_pchip=(0:1:time(s,1))./time(s,1);
    hermite=pchip(tim_surf',100+surface');
    correction=ppval(hermite,tim_pchip);
    tim_pchip=round(tim_pchip.*time(s,1));
    correction=correction(1,  ismember(tim_pchip,time) )-100;
    clear tim_surf hermite tim_pchip time
end

correction=correction';
    
% if intervaldepth<1
% %     correction=floor(correction)+ (round( (correction-floor(correction))./ intervaldepth ).* intervaldepth) ;   
%     correction=iknos_round2nearest(correction,intervaldepth);
% else correction=round(correction);
% end

depth2=depth-correction; % -intervaldepth
depth2(depth2<intervaldepth,1)=0;

depth2=iknos_round2nearest(depth2,intervaldepth);

%%% ----------- END OF IKNOS_ZOC ----------

