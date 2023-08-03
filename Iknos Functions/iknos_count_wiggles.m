function wig=iknos_count_wiggles(vector)
%% YT_COUNT_WIGGLES counts the number of "ups and downs" in a time serie of
%% values.
%
%NOTE: This code was originally designed to be used as an internal function
%   of the YT_IKNOS_DA program.
%
%   There is no error checking at this stage.
%
% CREDIT:
% Created by Yann Tremblay (The IKNOS Toolbox).
%
vector=vector(:);
if size(vector,1)<3 ;
        wig=1;
else
    for j=1:size(vector,1)
        if j==1 & vector(j,1)==0 ;
            vector(j,1)=1 ;
        elseif vector(j,1)==0 ;
            vector(j,1)=vector(j-1,1) ;
        end
    end
    aa=vector==1;   
    b=[aa(1,1) ; aa(1:size(aa,1)-1,1)];
    wig=sum(abs(b-aa));
    if aa(1,1)==0 ;
        wig=wig+1;
    end
    if aa(size(aa,1),1)==1 ;
        wig=wig+1;
    end
end