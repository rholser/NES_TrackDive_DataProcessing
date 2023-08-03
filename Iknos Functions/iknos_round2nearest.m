
function out=iknos_round2nearest(a,nearest)
%%YT_ROUND2NEAREST rounds to the first multiple of "nearest".
% nearest must be positive.
%
%CREDIT:
%Created by Yann Tremblay , February 2004
% modified August 2004, august 2005
%

 if nargin==2 
        if ~isnumeric(a) || ~isnumeric(nearest) 
            error('Input ''a'' and ''nearest'' must be numerical.');
        end
else
      error('Illegal number of  input arguments');
 end
    
%% START

if nearest<=0
    error('In: yt_round2nearest, illegal input: "nearest"');
elseif nearest<1
out=floor(a)+ (round( (a-floor(a))./ nearest ).* nearest);
elseif nearest==1
    out=round(a);
else
    out=round(a./nearest).*nearest;
end

%% END