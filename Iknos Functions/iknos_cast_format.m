
function res=iknos_cast_format(matrix)
% res=iknos_cast_format(matrix); format a matrix of [depth,value1,value2] obtained with
% animal borne recorders in a CTD cast format.
%
% INPUTS:
% matrix must have depth in first column (positive values), and any other number of data
% recorded along the depth axis.
%
% OUTPUT:
% res has depth every meter from 0 to max(depth) in first column and the
% corresponding interpolated values in the adjacent columns.
% Interpolation is done using hermite spline (pchip). PCHIP was chosen because it has no
% overshoots and less oscillation if the data are not smooth, compared to SPLINE.
% When several values for a single depth valus are recorded, the median is
% calculated for this depth.
%
% CREDIT:
% Created by Yann Tremblay (The IKNOS toolbox)
% Created October 11th 2004.
% Modified 29 April 2005: when input data had NaNs (or too many NaNs), the
% Pchip interpolation didn't work. This was accounted for.

if size(matrix,2)<2
    error('Input matrix must have 2 columns minimum');
end

if ~isempty(matrix)
    
    if size(matrix,1)~=1

    matrix=sortrows(matrix,1);
    
  %% This was added because some smru casts does not have values for
  %% surface, and this is bad for the interpolation
        if matrix(1,1)~=0
            matrix=[matrix;[0 matrix(1,2:end)]];
        end
    
    repete=diff(matrix(:,1))==0;
    ID=iknos_setones(repete);
    if ~isempty(ID)
        ID(:,2)=ID(:,2)+1;
        fin=size(ID,1);
        add=[];
        unic=ones(size(matrix,1),1);
        for i=1:fin
            add=[add;median(matrix(ID(i,1):ID(i,2),:))];
            unic(ID(i,1):ID(i,2),1)=0;
        end
        matrix=sortrows([matrix(find(unic),:);add],1);
    end

    XX=0:max(matrix(:,1));
    YY=[];
    for i=2:size(matrix,2)
        
        test=sum(isnan(matrix(:,i)));
        if size(matrix,1)-test<2
            YY=[YY ; nan(1,size(XX,2))];
            else
            YY = [YY ; pchip(matrix(:,1),matrix(:,i),XX)];
        end 
        
     end
    
    res=[XX;YY]';

    else
    res=matrix;
    end
else
        res=[];
 end