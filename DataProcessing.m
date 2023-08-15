% DataProcessing Consolidates all processing steps into one script.
%
% Requires MATLAB toolboxes: 
%       Mapping Toolbox
%       Statistics and Machine Learning
%
% Requires modified/custom functions and files:
%   IKNOS toolbox - functions for zero-offset correction and dive analysis
%   are required (included in GitHub repository)
%
%   For Dive Processing Step 1 (non-WC data imports):
%       smruTDR_import.m
%       KamiTDR_import.m
%       KamiIndex.csv
%
%   For Dive Processing Step 2 (full resolution ZOC and Dive Analysis):
%       DA_data_compiler.m
%       ChangeFormat_DA.m
%       MetaData.mat
%
%   For Dive Processing Step 3 (subsample to 8 sec, ZOC and Dive Analysis):
%       DA_data_compiler.m
%       subsample_DA.m
%       MetaData.mat
%
% This process should NOT be run in parallel (or in multiple instances of matlab) as the iknos_da 
% function may writes temporary files - if multiple instances are run, this could mix tdr records 
% together.
%
% Created by: Rachel Holser (rholser@ucsc.edu)
% Created on: 18-May-2022
%
% Version 4: 
%
% Dive Processing
% Step 1: load SMRU text files and convert to *tdr_raw.csv, then will check and correct for 
% broken dives and save as *_clean_tdr.csv
%
% Step 2: load all load each TDR file (SMRU, WC, or Little Leonardo) in the current directory,
% adjust the timedate formatting, check for major errors in the timeseries (depth spikes, backward
% time jumps (yes, they happen), etc.), truncate the record to deployment start and end time, and 
% will run iknos_da which will do a zero-offset correction and identify and calculate statistics 
% for each dive.
%
% Step 3: load full resolution outputs from Step 2, subsample it to 8 seconds if possible, and 
% run iknos_da on the subsampled data.
%
% Update Log:
% 29-Dec-2022 - changed function names and updated inputs for Step 3
% 02-Mar-2023 - small tweaks (A.Favilla)
% 12-Apr-2023 - adding all data processing steps and writing some DiveProcessing steps to run from
%               All_Filenames.mat
% 21-Jun-2023 - adding some notes and step for generating mat files
% 03-Jul-2023 - added filename change for SMRU tdr raw/clean files
% 24-Jul-2023 - Updated script and function names, added annotation, removed matfile creationg and 
%               added NetCDF creation scripts

%% Compile MetaData and Raw Filenames

CompileMetadata
CompileFilenames

%% Process Tracking Data

% Only NEED to run Split_MultiplePTTs if you have multiple tracks in a single file (this is quite common).
% Running Split_MultiplePTTs will NOT cause problems for single track files, so can run it to be
% safe.
Split_MultiplePTTs

% Combine argos and gps data and correctly format for input into aniMotum
prep_argos_and_gps_for_aniMotum

% Recompile filenames to correctly compile filenames for R script
CompileFilenames

%%%%%% Open R to run "run_aniMotum_forMatfiles.R"

% After aniMotum is complete, re-compile filenames
CompileFilenames

%% Process Diving Data
% Step 1a: SMRU tag data import
clear
SMRUfiles=dir('*tdr.txt');

for k=1:length(SMRUfiles)
    smruTDR_import(SMRUfiles(k).name)
end

% Step 1b - Kami tag data import
clear
Kamifiles=dir('*Kami.txt');
MetaData=readtable('KamiIndex.csv');
for k=1:size(files,1)
    %Get TOPPID from filename
    TOPPID=str2num(strtok(Kamifiles(k).name,'_'));
    StartTime=MetaData.StartTime(MetaData.TOPPID==TOPPID);
    StartDate=MetaData.StartDate(MetaData.TOPPID==TOPPID);
    StartJulDate=datenum(StartDate)+days(StartTime);
    KamiTDR_Import(Kamifiles(k).name,StartJulDate)
end

% Step 1c - Stroke tag data import
clear
Strokefiles=dir('*Stroke.txt');
MetaData=readtable('KamiIndex.csv');
for k=1:size(files,1)
    %Get TOPPID from filename
    TOPPID=str2num(strtok(Strokefiles(k).name,'_'));
    StartTime=MetaData.StartTime(MetaData.TOPPID==TOPPID);
    StartDate=MetaData.StartDate(MetaData.TOPPID==TOPPID);
    StartJulDate=datenum(StartDate)+days(StartTime);
    KamiTDR_Import(Strokefiles(k).name,StartJulDate)
end

% After TDR imports, re-compile filenames
CompileFilenames

%% Step 2: Load, prep file, and DA. Recompile filenames.
clear

load('All_Filenames.mat')
load('MetaData.mat');
files=[TDRRawFiles;TDR2RawFiles;TDR3RawFiles];

for k=1:size(files,1)
    %Find start and end time for each deployment in MetaData using TOPPID
    TOPPID=files.TOPPID(k);
    row=find(MetaDataAll.TOPPID==TOPPID);
    Start=MetaDataAll.DepartDate(row);
    End=MetaDataAll.ArriveDate(row);
    outFolder=files.folder(k);
    filename=files.filename(k);
    if contains(filename,'tdr_raw')
        filename=strcat(extractBefore(filename,'_raw'),'_clean.csv');
    end
    ChangeFormat_DA(filename,Start,End,TOPPID,outFolder);
end

CompileFilenames

%% Step 3: Subsample to 8 seconds and DA; recompile filenames
clear
load('All_Filenames.mat')
load('MetaData.mat');

files=[TDRCleanFiles;TDR2CleanFiles;TDR3CleanFiles];
filesZOC=[TDRZOCFiles;TDR2ZOCFiles;TDR3ZOCFiles];

for k=1:size(files,1)
    TOPPID=files.TOPPID(k);
    outFolder=files.folder(k);
    fileDA=strcat(extractBefore(files.filename(k),'_DAprep'),'_DAString.txt');
    subsample_DA(files.filename(k), fileDA, filesZOC.filename(filesZOC.TOPPID==TOPPID), TOPPID,outFolder)
end

CompileFilenames

%% Step 4: QC DiveStat Files and Generate QC flags for TDRs & Tracks

QC_DiveStat
QC_Flag

%% Step 5: Geolocate Dives

GeolocateDives

%% Step 6: Create netCDF Files

EsealData_NetCDF_Level1
EsealData_NetCDF_Level3

