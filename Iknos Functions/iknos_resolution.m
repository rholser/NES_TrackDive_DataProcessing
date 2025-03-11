function res=iknos_resolution(a)
%YT_resolution finds the absolute value of the minimum non-zero difference
%  >= 0.001 between successive data, i.e. in time serie readings, the resolution.
%
% CREDIT:
%  Created by Yann Tremblay on 04 November 2003.
%  Modified 13 August 2004: a is round to 3 digits by default, to avoid
%  problems with double precision arithmetic numbers. As a result, no
%  resolution below 0.001 can be calculated !
%


if nargin==1 
    
    if ~isnumeric(a)  
    error('iknos_resolution(a): a must be numerical');
    end
    
    if size(a,2)>1 & size(a,1)>1
        error('iknos_resolution(a) :  a must be a vector, not a matrix');
    end
    
else
      error('Illegal number of  input arguments');
end

%%%    START

iknos_round2nearest(a,0.001);
temp=abs(diff(a));
res=min(   temp(  find(temp)  )  ); % find is used to avoid the zero value

%%% End of function