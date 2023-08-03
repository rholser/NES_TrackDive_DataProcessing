function res=iknos_takeoutspikes(a,x)
%YT_TAKEOUTSPIKES does what its name tells !
%  YT_TAKEOUTSPIKES(A,X), returns A, with spike values of size X or -X replaced with
%  adjacent value.
%  X can be a vector of several values.
%  In the case of time series data of sensor readings, this is useful to
%  remove "sensor noise". This function can be seen as a kind of smoothing.
%  Example:          a=[1;0;2;1;1;0;1;1;4;1;1;0;0]
%            diff(a)=[-1;2;-1;0;-1;1;0;3;-3;0;-1;0]
%  yt_takeoutspikes(a,3)= [1;0;2;1;1;0;1;1;1;1;1;0;0]
%  Element 4 was replaced by adjacent 1 because it created 2 changes of 3
%  and -3 successively (changes of -3 and 3 would have produced the same
%  result).
%  Firt and last point cannot be removed, as you need one point before and
%  after to define a spike !
%  CREDIT:
%  Created by Yann Tremblay on 02 November 2003.
%  Modified March 13th 2007: bug fixed.
%
%
if nargin==1 
  error('IKNOS_TAKEOUTSPIKES need 2 input arguments');
elseif nargin==2 
    if isnumeric(a)==0 | isnumeric(x)==0
        error('IKNOS_TAKEOUTSPIKES(a,x) :  a and x must be numerical values');
    end      
    if size(a,2)>1 & size(a,1)>1
        error('IKNOS_TAKEOUTSPIKES(a,x) :  a must be a vector, not a matrix');
    end
    if size(a,2)>1 & size(a,1)==1
    a=a';
    rawvector=1;
    elseif size(a,2)==1 & size(a,1)>=1
    rawvector=0;
    else
    rawvector=0;
    end  
elseif nargin>2 
        error('Too many input arguments');
end
    
%%%%%      START

if isempty(a)==0 & isnan(a)==0 & isempty(x)==0 & sum(isnan(x))==0
            
    temp=diff(a);
    s=size(temp,1);
    shift_temp=([temp(1,1);temp(1:s-1)]);

    b=zeros(s,1);
    c=zeros(s,1);
    d=zeros(s,1);
    
    b(intersect( find(ismember(abs(temp),x)) , find(ismember(abs(shift_temp),x)) ),1)=1;
    c(find(abs(temp)==abs(shift_temp)),1)=1;
    d(find(sign(temp)+sign(shift_temp)==0),1)=1;
    
    want=find(b==1 & c==1 & d==1);

    if isempty(want)
    res=a;
    else
    a(want,1)=a(want-1,1);
    res=a;
    end
else
    res=a;
end

if rawvector==1
    res=a';
end
    
%%%%% END of function YT_TAKEOUTSPIKES