% Compile_Metadata_netCDF is the first step in processing elephant seal biologging data. It complies metadata from 
% .csv files into a single .mat file (MetaData.mat) that is used throughout all processing steps and
% in final file assembly (both netCDF and mat file formats).
%
% Created by: R.Holser (rholser@ucsc.edu)
% Created on: Jun 2018
%
%Expected input files: startstop.csv (required for next steps)
%                       tagmetadata.csv (required for next steps)
%
% Version 1
% Update Log:
%   31-Dec-2022 - Updates imports for new startstop and tagmetadata fields
%   24-Jul-2023 - Made netCDF-specific version (no foraging success data)
%                 Adds user-selected output folder

clear

%% Read start/stop data
MetaDataAll=readtable('startstop_female_datapaper.csv');

%% Read tagging metadata
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 35);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["SealID", "TOPPID", "SatTagManufacturer", "SatTagType", "SatTagID", "SatTagPTT",...
    "SatTagQC", "SatTagComment", "TDR1Manufacturer", "TDR1Type", "TDR1ID", "TDR1Loc", "TDR1QC",...
    "TDR1Comments", "TDR2Manufacturer", "TDR2Type", "TDR2ID", "TDR2Loc", "TDR2QC", "TDR2Comments",...
    "TDR3Manufacturer", "TDR3Type", "TDR3ID", "TDR3Loc", "TDR3QC", "TDR3Comment", "Other1", "Other1Loc",...
    "Other1Comment", "Other2", "Other2Loc", "Other2Comment", "Other3", "Other3Loc", "Other3Comment"];
opts.VariableTypes = ["string", "double", "string", "string", "string", "double",...
    "double", "string", "string", "string", "string", "string", "double",...
    "string", "string", "string", "string", "string", "double", "string",...
    "string", "string", "string", "string", "double", "string", "string", "string",...
    "string", "string", "string", "string", "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["SealID", "SatTagManufacturer", "SatTagType", "SatTagID",...
    "SatTagComment", "TDR1Manufacturer", "TDR1Type", "TDR1ID", "TDR1Loc", "TDR1Comments",...
    "TDR2Manufacturer", "TDR2Type", "TDR2ID", "TDR2Loc", "TDR2Comments", "TDR3Manufacturer", "TDR3Type",...
    "TDR3ID", "TDR3Loc", "TDR3Comment", "Other1", "Other1Loc", "Other1Comment", "Other2", "Other2Loc",...
    "Other2Comment", "Other3", "Other3Loc", "Other3Comment"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["SealID", "SatTagManufacturer", "SatTagType", "SatTagID",...
    "SatTagComment", "TDR1Manufacturer", "TDR1Type", "TDR1ID", "TDR1Loc", "TDR1Comments",...
    "TDR2Manufacturer", "TDR2Type", "TDR2ID", "TDR2Loc", "TDR2Comments", "TDR3Manufacturer", "TDR3Type",...
    "TDR3ID", "TDR3Loc", "TDR3Comment", "Other1", "Other1Loc", "Other1Comment", "Other2", "Other2Loc",...
    "Other2Comment", "Other3", "Other3Loc", "Other3Comment"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["SatTagQC","TDR1QC", "TDR2QC", "TDR3QC"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["SatTagQC","TDR1QC", "TDR2QC", "TDR3QC"], "ThousandsSeparator", ",");

% Import the data
TagMetaDataAll = readtable("tagmetadata.csv", opts);

% Clear temporary variables
clear opts

%% Save all metadata structure into single .mat file for later use
outfolder=uigetdir('C:\','File Output Folder');
cd(outfolder);
save('MetaData.mat','MetaDataAll','TagMetaDataAll')
