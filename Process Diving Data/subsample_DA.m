%output = subsample_DA_V4_2(filename,filenameDA)
%
% filename:  the complete file name of the file ending DAprep_full.csv produced by 
%            change_format_DA_V4_2
% 
% Created by: Rachel Holser (rholser@ucsc.edu), based on P.Robinson's 2009 script
% Created: Dec-2019
%
% Function to subsample TDR data that has been cleaned up through change_format_DA, and run IKNOS 
% dive analysis (DA), including zero-offset correction (zoc), on sumsampled data  
%
% Requires prepared files: *DAprep_full.csv 
%                          *DAstring.csv
%                          *full_iknos_rawzoc_data.csv
%
% Requires functions: iknos_da
%                     DA_data_compiler_RRH
%                     yt_findclosest_RRH
%                     resolution_DepthRes
%
% Version 4.2: incorportates new SMRU tdr_clean files and uses datetime rather than datenum 
%              wherever possible
%
% Update Log: 
% 29-Dec-2022 - Updated matlab function useage
%               Incorporated new running surface detection for
%               parameterizing zoc.m (now Step 3.2)
%               Added QC figures
% 03-Jul-2023 - Changed to iknos_da_V2
%               Added outFolder and built more flexible file read/naming
% 31-May-2023 - More outFolder updates.  Changed min depth to 25 m

function subsample_DA(filename,filenameDA,fullreszocfile,TOPPID,outFolder)
    
    %Step 1: Pull in data and DAstring from text files saved from
    %change_format_DA.m

    %Data to be subset
    data=readmatrix(strcat(outFolder,'\',filename));
    
    %DAstring
    m=size(data,2);
    fid=fopen(strcat(outFolder,'\',filenameDA));
    if m==7
        preDAstring=textscan(fid,'%s %s %s %s %s %s %s');
        DAstring=[preDAstring{1},preDAstring{2},preDAstring{3},preDAstring{4},...
            preDAstring{5},preDAstring{6},preDAstring{7}];
    elseif m==8
        preDAstring=textscan(fid,'%s %s %s %s %s %s %s %s');
    elseif m==9
        preDAstring=textscan(fid,'%s %s %s %s %s %s %s %s %s');
    elseif m==10
        preDAstring=textscan(fid,'%s %s %s %s %s %s %s %s %s %s');
    end
    fclose(fid);
    DAstring=char(preDAstring{1});
    for j=2:m
        DAstring=[DAstring ' ' char(preDAstring{j})];
    end
    
    %full res data for zoc parameter determination
    data_fullres=readtable(strcat(outFolder,'\',fullreszocfile),'HeaderLines',26,'ReadVariableNames',true);
    if ~contains(data_fullres.Properties.VariableNames(:),'time')
        data_fullres=readtable(strcat(outFolder,'\',fullreszocfile),'HeaderLines',22,'ReadVariableNames',true);
    end

    data_fullres.Time=datetime(data_fullres.time,'ConvertFrom','datenum');

    %Step 2: calculate sampling rate, choose subsample basaed on rate.
    %        NOTE: Only works for data sampling at 1, 2, or 4 seconds.
    %        Other rates will not be subsampled.
    SubSample=1;
    SamplingInt=round(mode(diff(data(:,6))));
    if SamplingInt==1
        SubSample=8;
    elseif SamplingInt==2
        SubSample=4;
    elseif SamplingInt==4
        SubSample=2;
    end
    
    %Step 3: Subsample, save files, and re-run DA
    if SubSample==8 || SubSample==4 || SubSample==2

        %Step 3.1: Automatic depth resolution detection
        DepthRes=resolution_DepthRes(data_fullres.depth);

        %Step 3.2: detect if dive surface intervals have offset >10m. 
        % Some individual TOPPIDs have been manually asigned due to weird surface
        % data found during visual inspection.
        running_surface = movmin(data_fullres.depth,hours(2),'SamplePoints',data_fullres.Time);
        [f,xi]=ecdf(running_surface); %figure; ecdf(running_surface,'Bounds','on');
        if size(xi,2)<3 && size(strfind(filename,'_tdr_clean'),1)>0
            minsurface=0; % SMRU tags
        elseif TOPPID==2013032 && size(strfind(filename,'-out-Archive'),1)>0% has weird surface data
            minsurface=0; % set manually through visual inspection
        elseif TOPPID==2006052 && size(strfind(filename,'-out-Archive'),1)>0% has weird surface data
            minsurface=0; % set manually through visual inspection
        elseif TOPPID==2013036 && size(strfind(filename,'-out-Archive'),1)>0% has weird surface data
            minsurface=0; % set manually through visual inspection
        elseif abs(xi(3)-xi(2))>10 % if there's a large jump, might be due to surface spikes
            minsurface=xi(3);
        else
            minsurface=interp1(f,xi,0.05);
        end

        %Step 3.3: Subsample data and save file
        data=data(1:SubSample:end,:);
        writematrix(data,strcat(outFolder,'\',extractBefore(filename,'full'), 'SubSample.csv'));

        %Step 3.4: Run IKNOS DA
        if minsurface<-10
            iknos_da(strcat(outFolder,'\',extractBefore(filename,'full'), 'SubSample.csv'),DAstring,4,...
                25/DepthRes,20,'wantfile_yes','ZocWindow',2,...
                'ZocWidthForMode',15,'ZocSurfWidth',10,'ZocDiveSurf',15,...
                'ZocMinMax',[minsurface-10,2200]);
        else
            iknos_da(strcat(outFolder,'\',extractBefore(filename,'full'), 'SubSample.csv'),DAstring,4,...
                25/DepthRes,20,'wantfile_yes','ZocWindow',2,...
                'ZocWidthForMode',15,'ZocSurfWidth',10,'ZocDiveSurf',15,'ZocMinMax',[-10,2200]);
        end
        %Step 4: Plot and save QC figs
        rawzocdatafile=strcat(outFolder,'\',extractBefore(filename,'full'),'SubSample_iknos_rawzoc_data.csv');
        rawzocdata=readtable(rawzocdatafile,'HeaderLines',26,'ReadVariableNames',true);
        if ~contains(rawzocdata.Properties.VariableNames(:),'time')
            rawzocdata=readtable(rawzocdatafile,'HeaderLines',22,'ReadVariableNames',true);
        end

        rawzocdata.Time=datetime(rawzocdata.time,'ConvertFrom','datenum');

        DiveStatfile=strcat(outFolder,'\',extractBefore(filename,'full'),'SubSample_iknos_DiveStat.csv');
        DiveStat=readtable(DiveStatfile,'HeaderLines',26,'ReadVariableNames',true);
        if ~contains(DiveStat.Properties.VariableNames(:),'PDI')
            DiveStat=readtable(DiveStatfile,'HeaderLines',22,'ReadVariableNames',true);
        end
        DiveStat.Time=datetime(DiveStat.Year,DiveStat.Month,DiveStat.Day,DiveStat.Hour,DiveStat.Min,DiveStat.Sec);

        figure(1);
        plot(rawzocdata.Time,rawzocdata.depth);
        hold on; set(gca,'YDir','reverse');
        plot(rawzocdata.Time,rawzocdata.CorrectedDepth,'b');
        scatter(DiveStat.Time,zeros(size(DiveStat,1),1),[],'go');
        scatter(DiveStat.Time+seconds(DiveStat.Dduration),zeros(size(DiveStat,1),1),[],'ro');
        text(DiveStat.Time,DiveStat.Maxdepth,num2str(DiveStat.DiveNumber),'Color','b');
        legend({'raw','zoc','Start dive','End dive'});
        title(['Raw vs ZOC: ' num2str(TOPPID)]);
        savefig(strcat(outFolder,'\',extractBefore(filename,'full'),'SubSample_Raw_ZOC.fig'));
        close;
    end
    clear minsurface SubSample SamplingInt DepthRes data DAstring data_fullres data rawzocdata DiveStat
end