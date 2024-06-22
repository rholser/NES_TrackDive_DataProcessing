function bt=iknos_find_bottom(matrix,varargin)
%%IKNOS_FIND_BOTTOM returns a 2 columns matrix containing indexes of
%%the beginning and the end of a bottom phase, within a dive dataset.
%
%INPUTS:
% matrix(:,1) must be time in julian day format (i.e. decimal day)
% matrix(:,2) must be depth (positive values)
% other columns in matrix are not used in this function.
% matrix must represent the dive data only. Surface data musn't be
% included because dives are identified on the time basis. Thus, it is
% necessary that a jump > time sampling interval exists between dives.
% 
% Varargin is either 'BotFix' with argument representing the percentage or 'BotSlope'
% BotFix : a fixed percentage of max depth to define bottom time.
%     If 'BotFix' is asked without percentage, 80% is taken by default.
%
% BotSlope : the calculation is made using a change in the descent and ascent
%         slopes
% pct_of_max_depth must be superior to 0 and inferior or equal to 100.
%
%Examples of usages:
%       bt=iknos_find_bottom(matrix,'BotSlope')
%       bt=iknos_find_bottom(matrix,'BotFix') %% in this case 80% will be
%       taken as a percentage
%       bt=iknos_find_bottom(matrix,'BotFix',90)
%
% CREDIT:
% Created by Yann Tremblay on 25 nov 2003
% Modified 21 january 2004
% Modified 6 August 2004: add the varargin system for incorporation with
%           iknos_da
% Modified 13 august 2004: added a feature that permits to prevent from
%           artifacts arising when data are sampled at a very high rate compare to
%           the length of the dive. Data are now downsampled if this appens
% 23 March 2005: bug fixed
% Modified 24 April 2006: For the slope method, Bottom is now set to be at
% least deeper than 50% of Max depth (was 70%) before.
%
%  Modified 9 December 2022 (Arina Favilla): changed yt_resolution() to
%  either resolution_DepthRes() or resolution_SamplingRate()
%  Renamed 16 December 2022 (Arina Favilla): renamed from yt_find_bottom to
%  find_bottom
%  Renamed 03 August 2023 (R. Holser): remaned from find_bottom to
%  iknos_find_bottom, and all dependend yt_ functions also renamed to
%  iknos_

% Faire test value >0 for depth.


if nargin<2 | nargin>3
    error('In iknos_find_bottom : illegal number of arguments');
end

method=varargin(1);
pct_of_max_depth=80; % this is NOT default, it is just to give it a value when 'BotSlope' is selected

if strcmp(method,'BotFix')==0 & strcmp(method,'BotSlope')==0
    error('In iknos_find_bottom : illegal value for ''Method''')
end

if max(size(varargin))==1 & strcmp(method,'BotFix')
        pct_of_max_depth=80; % default value
elseif max(size(varargin))==2 & strcmp(method,'BotFix')
        pct_of_max_depth=varargin{2}(:);
end

if isempty(pct_of_max_depth)==1 | isstr(pct_of_max_depth)
    error('In iknos_find_bottom : illegal value for "pct_of_max_depth"')
end

if size(pct_of_max_depth,1)>1 | size(pct_of_max_depth,2)>1
    error('In iknos_find_bottom : "pct_of_max_depth" must be a scalar, not a vector')
end

if pct_of_max_depth<=0 | pct_of_max_depth>100
    error('In iknos_find_bottom : illegal value for "pct_of_max_depth"')
end

%%------ START ------
intervaltime=resolution_SamplingRate(round(matrix(:,1).*86400));
intervaldepth=resolution_DepthRes(matrix(:,2));

% as=diff(round(matrix(:,1).*86400))==intervaltime; % logical array
as=matrix(:,2)~=0;
dt=iknos_setones(as); clear as; % dt is a 2 column matrix of indexes
dt(:,1)=dt(:,1)-1;
dt(:,2)=dt(:,2)+1; % dt is the beginning and end indexes of each dive

%%----- For the 'fix' method ------
if strcmp(method,'BotFix')
 bt=[];   
for i=1:size(dt,1)
    mat=matrix(dt(i,1):dt(i,2),2);
    threshold=pct_of_max_depth*max(mat)/100;
    t_index=find(mat>=threshold);
    btadd=[dt(i,1)+min(t_index)-1 , dt(i,1)+max(t_index)-1] ;
    bt=[bt ; btadd];
end

%----- For the 'slope' method ------
else % no need to retest since it has been error checked before
    bt=[];   
    for i=1:size(dt,1)
    mat=matrix(dt(i,1):dt(i,2),2); %depth data (should not be empty - no test)
    threshold=50*max(mat)/100;  % bottom phase needs to be deeper than 50% of max depth
    idx=find(mat>=threshold);
    flag1=min(idx);
    flag2=max(idx);
    mat=mat(flag1:flag2,1); % this is where matrix where bottom phase should be.(should not be empty - no test)
                            % This way of extracting the matrix (using
                            % flags instead of idx directly prevents from
                            % having a hole in the data, due to a value
                            % within the bottom that could be <threshold
        if size(mat,1)==1
            btadd=[dt(i,1)+flag1-1 dt(i,1)+flag2-1];
            bt=[bt ; btadd];
        else         
            
        down=matrix(dt(i,1)+flag1-1,2) / ((flag1-1)*intervaltime) ; % down speed
        up=matrix(dt(i,1)+flag2-1,2) / ((dt(i,2)-dt(i,1)-flag2+1)*intervaltime) ; % up speed
        
        % Downsampling to prevent from artifact arising from oversampling
        % No downsampling if sampling interval >=3
        % No downsampling for relatively short dives
        downsamp=1; % by default no downsampling
        if intervaltime<=2 & (flag2-flag1)>=100 % If the 60% deeper portion of dive has more than 100 points and sampling interval <=2
            if intervaltime==1
                downsamp=4;
            else % this is if intervaltime==2
                downsamp=2;
            end
            want=1:downsamp:size(mat,1);
            mat=mat(want,1);
        end
        
        mat2=diff(mat)./(intervaltime*downsamp); %% this is meter per second

        mat3=mat2./down; % maximum==1 or close (>0 for descent), minimum==-1 or close(<0 for ascent)
        mat4=mat2./up;
        %% for descent
        logic1=mat3<=0.2;
        idx1sub=find(logic1);
        %% for ascent
        logic2=mat4>=-0.2;
        idx2sub=find(logic2);
        
            if isempty(idx1sub) % this can happen for short dives, means no stable or up phase
                idx1=dt(i,1)+size(mat,1)+flag1-2;
                idx2=idx1;
                sa=1;
            elseif isempty(idx2sub) % this can happen for short dives, means no stable or down phase
               idx2=dt(i,1)+flag1-1;
               idx1=idx2;
               sa=2;
            else
                idxsub=[idx1sub(1,1) idx2sub(end,1)];
                fst=min(idxsub);
                snd=max(idxsub);
              idx1=dt(i,1)+flag1+    (1+downsamp*(fst-1)) -2  ;  % -2 %ce terme : (1+downsamp*(idx1sub(1,1)-1)) est la resolution d'une suite pour passer 
              idx2=dt(i,1)+flag1+    (1+downsamp*(snd-1)) -1 ;%-1 % -1 instead of -2 because of the index lag due to function diff
              sa=3;
            end

            btadd=[idx1 idx2];
            bt=[bt ; btadd];            
            
% This is to debug            
% if idx1>idx2 | idx1<=dt(i,1)
%     sa
%     downsamp
%     idx1sub
%     idx2sub
%     flag1
%     flag2
%     idx1
%     idx2
%     dt(i,1)
%     dt(i,2)
% end

            
        end
    end
    
% this is to debug
%                 test1=sum(bt(:,1)<=dt(:,1))
%                 test2=sum(bt(:,1)>=dt(:,2))
%                 test3=sum(bt(:,2)>=dt(:,2))
%                 test4=sum(bt(:,2)<=dt(:,1))
%                 size(bt,1)
%                 size(dt,1)
%                 test5=sum(bt(:,2)<bt(:,1))
end

