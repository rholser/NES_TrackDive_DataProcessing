
function TD=iknos_thermocline_depth(MatrixIn,G,DepthLimit,IterationGradient,Plot01)
%YT_THERMOCLINE_DEPTH finds the thermocline depth of a depth/temperature
%  matrix (in column), using a gradient limit of "G". It is important to
%  note that this function differs from "oceanographic toolbox" function in
%  the sense that it is supposed to work with animal derived temperature
%  data. This means: more noise, any kind of dive depth...etc.
%
%USAGE: TD=iknos_thermocline_depth(MatrixIn,G,DepthLimit,IterationGradient);
%
%INPUT:
% MatrixIn: 2 columns vector with depth values in the first column and
%   temperature values in the second column.
%   Matrix is the only required input, the others are optionals.
%
% G (optional, default=0.05): Gradient to use to determine thermocline depth. 
%   Unit is: degrees Centigrade per meter of depth.
%
% DepthLimit (optional, default=0): returns NaN if the cast is not deeper than DepthLimit.
%
% IterationGradient (optional, default=1). In a serie of at least 3
%   consecutive decreases or increases in temperature (any potential place
%   for a thermocline to happen) this parameters defines how many values of
%   "delta Temperature" (per meter) you want to select as a thermocline. This
%   is used to constraint some noisy data at the surface: noisy data will not
%   contain as many "delta T" as the thermocline zone. This has to be defined
%   based on the stability of your data (no rule).
% 
% Plot01 (optional, default=0): if you ask for, a plot is output. Don't ask
%   for a plot if you are doing a batch process!
%
%CREDIT:
%  Yann Tremblay (The IKNOS Toolbox)
%   tremblay@biology.ucsc.edu
%   based on advices from oceanographer Raphael Kudela (UCSC)
%
%  Modified 10 February 2006: mostly adjustment for type of data obtained
%  using SMRU tags (summary data with inflection points).
%
%NOTES: Very few input checking at this stage: read the help carefully and
%   make sure you input the right things !
%

%% Data checking (very basic)
if nargin<1 | nargin>5
    error('Ilegual number of input arguments');
end

% Set defaults
if nargin==1
    G=0.05;
    DepthLimit=0;
    IterationGradient=1;
    Plot01=0;
end
if nargin==2
    DepthLimit=0;
    IterationGradient=1;
    Plot01=0;
end
if nargin==3
    IterationGradient=1;
    Plot01=0;
end
if nargin==4
    Plot01=0;
end

if length(G)>1 | isempty(G)
    error('Temperature gradient must be a single value');
end

if size(MatrixIn,2)~=2 
    error('Matrix size is not valid');
end


%% START
if isempty(MatrixIn) | size(MatrixIn,1)==1
    TD=NaN;
else
% format the matrix in a regular cast format (one value per depth)
    matrix=iknos_cast_format(MatrixIn);     % This gives a sorted matrix with one value every meter
    
% make sure there is enought data to perform calculations
    if max(matrix(:,1))>=DepthLimit+3 % if at least 3 data points over "lim"
        
% calculate delta temperature (per meter)
    deriv=diff(matrix(:,2));  % lim:end
    
% a thermocline must involve at least 3 consecutive temperature changes in
% the same direction (3 warmings or 3 coolings).
Successive_decrease_or_increase=3;  

% Logic vectors of the signs: we treat separately the thermoclines from
% warm to colder and from cold to warmer.
    chk1=sign(deriv)==1;
    chk2=sign(deriv)==-1;

% Get the indexes of the start and end of these events
    ind1=iknos_setones(chk1,Successive_decrease_or_increase);
    ind2=iknos_setones(chk2,Successive_decrease_or_increase);
    
% Initialize: If not changed, these will be NaN
    want1=NaN;
    want2=NaN;

% find index for the first positive temperature change containing at least
% "IterationGradient" times the gradient value
    if ~isempty(ind1)
        for i=1:size(ind1,1)
            if sum(abs(deriv(ind1(i,1):ind1(i,2)))>=G)>=IterationGradient;
                add=find(abs(deriv(ind1(i,1):ind1(i,2)))>=G);
                add=add(1);
            want1=ind1(i,1)+add;
            break
            end
        end
    end
    
% find index for the first negative temperature change containing at least
% "IterationGradient" times the gradient value
    if ~isempty(ind2)
        for i=1:size(ind2,1)
            if sum(abs(deriv(ind2(i,1):ind2(i,2)))>=G)>=IterationGradient;
                add=find(abs(deriv(ind2(i,1):ind2(i,2)))>=G);
                add=add(1);
            want2=ind2(i,1)+add;
            break
            end
        end
    end

% between the index for positive and negative changes, we select the
% smallest index (because it corresponds to the shallowest depth
    want=min([want1 want2]);
    
        if ~isnan(want)
            TD=matrix(want,1);
        else
             TD=NaN;
        end
        
    else
        TD=NaN;
    end
end

%% Plot
if Plot01
plot([min(matrix(:,2)) max(matrix(:,2))],[-TD -TD],'-b','LineWidth',4)
hold on
plot(matrix(:,2),-matrix(:,1),'-','color',[0 0.8 0],'LineWidth',2.5)
hold on
plot(MatrixIn(:,2),-MatrixIn(:,1),'or','MarkerFaceColor','r')
hold on
iknos_ax
xlabel('Temperature (C)')
ylabel('Depth (m)')
title(['Gradient threshold = ',num2str(G),' C/m - Iteration of gradient = ',num2str(IterationGradient)]);
end


%% Following is part of the development...
%%%%%%%%%%%%%%%%%Method1
%     want=find(abs(deriv)>G);
%     if ~isempty(want) % & matrix(want(1,1),1)>=5
%         want=want(1,1)+lim;

%%%%%%%%%%%%%%%%method 2
%     chk1=deriv>=G;
%     chk2=deriv<=-G;
%     
%     ind1=iknos_setones(chk1,2);
%     ind2=iknos_setones(chk2,2);
%     
%     want1=NaN;
%     want2=NaN;
%     
%     if ~isempty(ind1)
%         want1=ind1(1,1)+lim;
%     end
%     if ~isempty(ind2)
%         want2=ind2(1,1)+lim;
%     end
%         
%     want=min([want1 want2]);
%     if ~isnan(want) % & matrix(want(1,1),1)>=5

