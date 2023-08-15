function [SurfLL,KLL,Zeu]=iknos_EuphoticDepth(matrix,NightDayLightCutoff)
%%iknos_EuphoticDepth returns surface light (SurfLL), coefficient of light attenuation (KLL) and 
% the euphotic depth (Zeu) from a TDR dataset.
% Coefficient of attenuation and euphotic depth are returned only for
% daylight dives.
%
%INPUTS:
% the input matrix must be a 2 columns matrix with depth in first column
% and light in the second column.
% NightDayLightCutoff: Value to select between night and day dives (150 by
% default (works for Wildlife Computers MK( tags scale). It corresponds to
% light at the surface, of course.
%
%OTHER FUNCTIONS USED:
% iknos_cast_format from the IKNOS toolbox
%
%CREDIT:
% Yann Tremblay (The IKNOS toolbox)
% Raphael Kudela for the initial version of the code
% created 11 November 2004
%

if nargin<1 | nargin>2
    error('Illegal number of input argument');
elseif nargin==1
NightDayLightCutoff=150;
end

if isempty(matrix) | size(matrix,1)==1
        KLL=NaN;
        Zeu=NaN;
        SurfLL=NaN;
        elseif size(matrix,2)~=2
    error('Input matrix must have 2 columns, with depth and light respectively');
else
    matrix=iknos_cast_format(matrix);

%We first take data from 3 to 25 m to calculate temporary surface light and
%attenuation coefficient. This permits to avoid the effects of spiky light
%values at surface.
lim=4;

if max(matrix(:,1))<=25
    mymax=max(matrix(:,1));
else
    mymax=25;
end

if mymax<10
        surfLL=NaN;

else
        foo=find(matrix(:,1) < mymax & matrix(:,1) > lim);
        warning off
    p=polyfit(matrix(foo,1),matrix(foo,2),1);
    
    if p(2) < 1
        surfLL=NaN; 
        kLL=NaN;
    else
            surfLL=p(2);
            kLL=1/p(1);
    end
        
%     foo=(1:max(matrix(:,1)))';
end
    
% This section ignores surfLL data <NightDayLightCutoff, which are night-time data
    if surfLL < NightDayLightCutoff | isnan(surfLL)
        KLL=NaN;
        Zeu=NaN;
        SurfLL=matrix(1,2);
%         flag(i)=1;
    else
        
                warning off
        
        Zeu=log2(surfLL*.001./surfLL)./kLL;
        foo=find(matrix(:,1) < Zeu & matrix(:,1) > lim);
        p=polyfit(matrix(foo,1),matrix(foo,2),1);

        
        if p(2) < 1
            SurfLL=NaN;
            KLL=NaN;
%             flag(i)=1;
        else
            SurfLL=p(2);
            KLL=1/p(1);
%             flag(i)=0;
        end
        
    end
        
end
        
        