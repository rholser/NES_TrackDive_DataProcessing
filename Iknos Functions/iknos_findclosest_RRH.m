%Last Updated: 7-sep-2019 - to use old interpolation function

function res=iknos_findclosest_RRH(indexOfA,closestToB)
%
% yt_findclosest(indexOfA,closestToB) outputs a matrix of the same size as
% 'closestToB', containing the indexes of the values in 'indexOfA' closest
% to each element in 'closestToB'.
%
% EXAMPLE:
%   res=yt_findclosest([1;3;4;5;7;8;11;14;17;15;17;18],[2;11.1;17;25])
%   returns res=[2;7;11;12]
%
% GOOD TO KNOW:
%  - note for example that element 2 is considered closest to 3 than to 1.
%  - Similarly, 4.5 will be considered closest to 5 than to 4.
%  - When several values exist in 'indexOfA', the greater index will be
%       returned.
%  - Order of output indexes follows the order of the input.
%  - Make sure that input vectors do not contain any empty values. Those
%        are totally ignored, and then the indexes do not take them into account.
%  - NaN are not accepted in indexOfA. In "closestToB", NaN are equivalent
%        to zeros.
%
% CREDIT: Created by Yann Tremblay (The Iknos Toolbox)
%   with help by James Ganong, 2nd of April 2005.
%
% HISTORY:
%  April 2007: slight modification for improving speed.
%

% try
indexOfA=indexOfA(:);

% if any(closestToB<min(indexOfA) | closestToB>max(indexOfA))
%    disp('%%%%%%%%%%%%%%%%%%%%%')
%    disp('WARNING:')
%    disp('Some values in closestToB are out of the range of indexOfA')
% end

indexOfA=[-inf;indexOfA;inf];
%this line was changed from original by Rachel Holser 02-Sep-2019:
%indexOfA=[-inf;indexOfA;inf] (current interp1 does not allow inf or NaN) 

[b,i]=unique(indexOfA);
nearestAvalues= old_interp1(b,b,closestToB,'nearest');
nearestAindexes= old_interp1(b,1:length(b),nearestAvalues,'nearest');
res=i(nearestAindexes)-1;
if sum(isinf(closestToB))~=0
    res(isinf(closestToB))=res(isinf(closestToB))-1;
end


% catch
% % This was my initial attempt to solve the problem. Work well if no
% % repetition in indexOfA... meaning: sometime crashed!
% % However, this code is very very fast.
% % I keep it here for eventual educational use.
% %
% %Carefull: no input verification.
% % Values in closestToB must be encompassed by values in indexOfA
% matr=zeros(length(indexOfA)+length(closestToB),5);
% matr(:,1:2)= sortrows([indexOfA,zeros(length(indexOfA),1) ; closestToB , ones(length(closestToB),1)],1);
% matr(:,3:4)= [ [diff(matr(:,1)) ; NaN] , [NaN ; diff(matr(:,1))] ] ;
% matr(:,5)=matr(:,4)-matr(:,3);
% want1=[ find(matr(:,2)==1 & matr(:,5)<0)-1 ; ...
%     find(matr(:,2)==1 & matr(:,5)>=0)+1 ;  ...
%     find(matr(:,2)==1 & isnan(matr(:,5)))-1];
% want1=want1(find(want1~=0));
% res=unique(find(ismember(indexOfA,matr(want1,1))));
% end