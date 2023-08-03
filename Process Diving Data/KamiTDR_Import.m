% Created by: Rachel Holser (rholser@ucsc.edu)
% Created on: 02-Jan-2023
%
%Version 1.0

function KamiTDR_Import(filename,StartJulDate)

% Import dive data
import=readtable(filename,'HeaderLines',7);
% Import start date from KamiIndex.csv and calculate Date/Time for each depth
EndJulDate=StartJulDate+((size(import,1)-1)*5)/86400;
import.JulDates=transpose(StartJulDate:(5/86400):EndJulDate);
import.Date=datestr(import.JulDates,'dd-mmm-yyyy');
import.Time=datestr(import.JulDates,'HH:MM:SS');
% combine into table for export
Data=table(import.Date,import.Time,import.DEPTH);
Data.Properties.VariableNames={'Date','Time','Depth'};
% save as csv
filename=strcat(strtok(filename,'Depth'),'tdr.csv');
writetable(Data,filename)
end