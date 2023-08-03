function add=iknos_findmode(mat,interval)
% YT_FINDMODE find the modal value of a vector, using its frequency
% distribution and a bin size of a given size (interval).
%
%NOTE:
% This calculation is different than finding the absolute modal value.
%
%CREDIT:
% Created by Yann Tremblay (The IKNOS Toolbox).
%

    minimum=min(mat);
    bin=min(mat):interval:max(mat) ;
    if size(bin,2)==1;
        bin=bin-interval:interval:bin+interval ;
    end
    [count , bin2]=hist(mat,bin);
    add=bin2(1,find(count==max(count)));
    if size(add,2)>1 
        add=add(1,1);
    end