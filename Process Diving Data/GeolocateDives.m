%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by: Rachel Holser (rholser@ucsc.edu)
% Created on: 22-Aug-2022
% Update Log: 
% 16-Dec-2022 - added geolocation for TDR2 and TDR3 files.
% 02-Jan-2022 - corrected source file formats to include location on disk
% 21-Apr-2023 - added datetime to DiveStat csv's
%               force interpolation to end at end of track
%
% Required functions:  iknos_interpol_linear_2 (IKNOS toolbox)
%                      SolarAzEl
%                      (https://github.com/Chrismarsh/umbra/blob/master/matlab/SolarAzEl.m)
%
% Preparation:
%      Use CompileMetdata.m to create MetaData.mat
%      Create All_Filenames.mat using CompileFilenames.m6
%      Process all tracking and diving data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
load MetaData.mat
load All_Filenames.mat

for i=1:size(MetaDataAll,1)

    disp([MetaDataAll.FieldID{i} '_' num2str(MetaDataAll.TOPPID(i))])

    % Find filenames with the current TOPPID
    trackfile=strcat(TrackAniMotumFiles.folder(TrackAniMotumFiles.TOPPID==MetaDataAll.TOPPID(i)),...
        '\',TrackAniMotumFiles.filename(TrackAniMotumFiles.TOPPID==MetaDataAll.TOPPID(i)));
    tdr1file=strcat(TDRDiveStatFiles.folder(TDRDiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),...
        '\',strtok(TDRDiveStatFiles.filename(TDRDiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),'.'),'_QC.csv');
    tdr1subfile=strcat(TDRSubDiveStatFiles.folder(TDRSubDiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),...
        '\',strtok(TDRSubDiveStatFiles.filename(TDRSubDiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),'.'),'_QC.csv');
    tdr2file=strcat(TDR2DiveStatFiles.folder(TDR2DiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),...
        '\',strtok(TDR2DiveStatFiles.filename(TDR2DiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),'.'),'_QC.csv');
    tdr2subfile=strcat(TDR2SubDiveStatFiles.folder(TDR2SubDiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),...
        '\',strtok(TDR2SubDiveStatFiles.filename(TDR2SubDiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),'.'),'_QC.csv');
    tdr3file=strcat(TDR3DiveStatFiles.folder(TDR3DiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),...
        '\',strtok(TDR3DiveStatFiles.filename(TDR3DiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),'.'),'_QC.csv');
    tdr3subfile=strcat(TDR3SubDiveStatFiles.folder(TDR3SubDiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),...
        '\',strtok(TDR3SubDiveStatFiles.filename(TDR3SubDiveStatFiles.TOPPID==MetaDataAll.TOPPID(i)),'.'),'_QC.csv');

    row=find(TagMetaDataAll.TOPPID==MetaDataAll.TOPPID(i));
    if TagMetaDataAll.SatTagQC(row)<4

        %Load aniMotum processed track
        Track=readtable(trackfile);
        try
            Track=removevars(Track,{'Var1'});
        end
        %Rename columns for consistency
        Track.Properties.VariableNames = {'TOPPID','DateTime','Lon',...
            'Lat','x','y','x_se_km','y_se_km','u','v','u_se_km','v_se_km','s','s_se'};
        %Convery DateTime to JulDate
        Track.JulDate=datenum(Track.DateTime);

        %load DiveStat files and interpolate track to it
        if ~isempty(tdr1file)
            %load dive statistics file
            Dive1Stat=readtable(tdr1file);
            %Convert julian date to datetime
            Dive1Stat.DateTime=datetime(Dive1Stat.JulDate,"ConvertFrom","datenum");
            %Check if tracking data extend across entire dive record
            ind=find(Dive1Stat.DateTime>Track.DateTime(end));
            %If track is shorter than dive record, only populate the sections of the dive record
            %with tracking data
            if ~isempty(ind)
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=NaN;
                Dive1Stat.Lat(1:ind(1))=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=NaN;
                Dive1Stat.Lon(1:ind(1))=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=NaN;
                Dive1Stat.Lat_se_km(1:ind(1))=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=NaN;
                Dive1Stat.Lon_se_km(1:ind(1))=Dive1LatLonSE(:,3);
            %If track is as long as dive record, populate all
            else
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(:));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(:));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=Dive1LatLonSE(:,3);
            end
            %Calculate solar elevation from lat/lon/date/time of each
            %dive
            [Az,El]=SolarAzEl(datestr(Dive1Stat.JulDate,'yyyy/mm/dd HH:MM:SS'),...
                Dive1Stat.Lat,Dive1Stat.Lon,0);
            %Add solar elevation to dive statistics
            Dive1Stat.SolarEl=El;
            %Write dive statistics back to file
            writetable(Dive1Stat,tdr1file);
            clear Az El
        end

        %Repeat the above steps for subsampled TDR data files
        if ~isempty(tdr1subfile)
            %load dive statistics file
            Dive1Stat=readtable(tdr1subfile);
            %Convert julian date to datetime
            Dive1Stat.DateTime=datetime(Dive1Stat.JulDate,"ConvertFrom","datenum");
            ind=find(Dive1Stat.DateTime>Track.DateTime(end));
            if ~isempty(ind)
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=NaN;
                Dive1Stat.Lat(1:ind(1))=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=NaN;
                Dive1Stat.Lon(1:ind(1))=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=NaN;
                Dive1Stat.Lat_se_km(1:ind(1))=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=NaN;
                Dive1Stat.Lon_se_km(1:ind(1))=Dive1LatLonSE(:,3);
            else
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(:));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(:));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=Dive1LatLonSE(:,3);
            end
            %Calculate solar elevation from lat/lon/date/time of each
            %dive
            [Az,El]=SolarAzEl(datestr(Dive1Stat.JulDate,'yyyy/mm/dd HH:MM:SS'),...
                Dive1Stat.Lat,Dive1Stat.Lon,0);
            %Add solar elevation to dive statistics
            Dive1Stat.SolarEl=El;
            %Write dive statistics back to file
            writetable(Dive1Stat,tdr1subfile);
            clear Az El
        end
        %load DiveStat2 files and interpolate track to it
        if ~isempty(tdr2file)
            %load dive statistics file
            Dive1Stat=readtable(tdr2file);
            %Convert julian date to datetime
            Dive1Stat.DateTime=datetime(Dive1Stat.JulDate,"ConvertFrom","datenum");
            ind=find(Dive1Stat.DateTime>Track.DateTime(end));
            if ~isempty(ind)
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=NaN;
                Dive1Stat.Lat(1:ind(1))=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=NaN;
                Dive1Stat.Lon(1:ind(1))=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=NaN;
                Dive1Stat.Lat_se_km(1:ind(1))=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=NaN;
                Dive1Stat.Lon_se_km(1:ind(1))=Dive1LatLonSE(:,3);
            else
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(:));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(:));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=Dive1LatLonSE(:,3);
            end
            %Calculate solar elevation from lat/lon/date/time of each
            %dive
            [Az,El]=SolarAzEl(datestr(Dive1Stat.JulDate,'yyyy/mm/dd HH:MM:SS'),...
                Dive1Stat.Lat,Dive1Stat.Lon,0);
            %Add solar elevation to dive statistics
            Dive1Stat.SolarEl=El;
            %Write dive statistics back to file
            writetable(Dive1Stat,tdr2file);
            clear Az El
        end

        %Repeat the above steps for subsampled TDR data files
        if ~isempty(tdr2subfile)
            %load dive statistics file
            Dive1Stat=readtable(tdr2subfile);
            %Convert julian date to datetime
            Dive1Stat.DateTime=datetime(Dive1Stat.JulDate,"ConvertFrom","datenum");
            ind=find(Dive1Stat.DateTime>Track.DateTime(end));
            if ~isempty(ind)
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=NaN;
                Dive1Stat.Lat(1:ind(1))=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=NaN;
                Dive1Stat.Lon(1:ind(1))=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=NaN;
                Dive1Stat.Lat_se_km(1:ind(1))=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=NaN;
                Dive1Stat.Lon_se_km(1:ind(1))=Dive1LatLonSE(:,3);
            else
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(:));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(:));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=Dive1LatLonSE(:,3);
            end
            %Calculate solar elevation from lat/lon/date/time of each
            %dive
            [Az,El]=SolarAzEl(datestr(Dive1Stat.JulDate,'yyyy/mm/dd HH:MM:SS'),...
                Dive1Stat.Lat,Dive1Stat.Lon,0);
            %Add solar elevation to dive statistics
            Dive1Stat.SolarEl=El;
            %Write dive statistics back to file
            %Write dive statistics back to file
            writetable(Dive1Stat,tdr2subfile);
            clear Az El
        end
        %load DiveStat files and interpolate track to it
        if ~isempty(tdr3file)
            %load dive statistics file
            Dive1Stat=readtable(tdr3file);
            %Convert julian date to datetime
            Dive1Stat.DateTime=datetime(Dive1Stat.JulDate,"ConvertFrom","datenum");
            ind=find(Dive1Stat.DateTime>Track.DateTime(end));
            if ~isempty(ind)
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=NaN;
                Dive1Stat.Lat(1:ind(1))=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=NaN;
                Dive1Stat.Lon(1:ind(1))=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=NaN;
                Dive1Stat.Lat_se_km(1:ind(1))=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=NaN;
                Dive1Stat.Lon_se_km(1:ind(1))=Dive1LatLonSE(:,3);
            else
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(:));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(:));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=Dive1LatLonSE(:,3);
            end
            %Calculate solar elevation from lat/lon/date/time of each
            %dive
            [Az,El]=SolarAzEl(datestr(Dive1Stat.JulDate,'yyyy/mm/dd HH:MM:SS'),...
                Dive1Stat.Lat,Dive1Stat.Lon,0);
            %Add solar elevation to dive statistics
            Dive1Stat.SolarEl=El;
            %Write dive statistics back to file
            %Write dive statistics back to file
            writetable(Dive1Stat,tdr3file);
            clear Az El
        end

        %Repeat the above steps for subsampled TDR data files
        if ~isempty(tdr3subfile)
            %load dive statistics file
            Dive1Stat=readtable(tdr3subfile);
            %Convert julian date to datetime
            Dive1Stat.DateTime=datetime(Dive1Stat.JulDate,"ConvertFrom","datenum");
            ind=find(Dive1Stat.DateTime>Track.DateTime(end));
            if ~isempty(ind)
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=NaN;
                Dive1Stat.Lat(1:ind(1))=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=NaN;
                Dive1Stat.Lon(1:ind(1))=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(1:ind(1)));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=NaN;
                Dive1Stat.Lat_se_km(1:ind(1))=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=NaN;
                Dive1Stat.Lon_se_km(1:ind(1))=Dive1LatLonSE(:,3);
            else
                %Lat/lon from linear interpolation of processed track based on time
                Dive1LatLon = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','Lat',...
                    'Lon'})),Dive1Stat.JulDate(:));
                %Add lat to dive statistics
                Dive1Stat.Lat(:)=Dive1LatLon(:,2);
                %Add lon to dive statistics
                Dive1Stat.Lon(:)=Dive1LatLon(:,3);
                %Lat/lon errors from linear interpolation of processed track based on time
                Dive1LatLonSE = iknos_interpol_linear_2(table2array(Track(:,{'JulDate','y_se_km',...
                    'x_se_km'})),Dive1Stat.JulDate(:));
                %Add lat_se to dive statistics
                Dive1Stat.Lat_se_km(:)=Dive1LatLonSE(:,2);
                %Add lon_se to dive statistics
                Dive1Stat.Lon_se_km(:)=Dive1LatLonSE(:,3);
            end
            %Calculate solar elevation from lat/lon/date/time of each
            %dive
            [Az,El]=SolarAzEl(datestr(Dive1Stat.JulDate,'yyyy/mm/dd HH:MM:SS'),...
                Dive1Stat.Lat,Dive1Stat.Lon,0);
            %Add solar elevation to dive statistics
            Dive1Stat.SolarEl=El;
            %Write dive statistics back to file
            %Write dive statistics back to file
            writetable(Dive1Stat,tdr3subfile);
            clear Az El
        end
    %if there is no tracking data, create lat/lon/solarEl variables in TDR
    %files and population with NaN
    else
        if ~isempty(tdr1file)
            Dive1Stat=readtable(tdr1file);
            Dive1Stat.DateTime=datetime(Dive1Stat.JulDate,"ConvertFrom","datenum");
            Dive1Stat.Lat(:)=NaN;
            Dive1Stat.Lon(:)=NaN;
            Dive1Stat.Lat_se_km(:)=NaN;
            Dive1Stat.Lon_se_km(:)=NaN;
            Dive1Stat.SolarEl(:)=NaN;
            writetable(Dive1Stat,tdr1file);
        end

        if ~isempty(tdr1subfile)
            Dive1SubStat=readtable(tdr1subfile);
            Dive1SubStat.DateTime=datetime(Dive1SubStat.JulDate,"ConvertFrom","datenum");
            Dive1SubStat.Lat(:)=NaN;
            Dive1SubStat.Lon(:)=NaN;
            Dive1SubStat.Lat_se_km(:)=NaN;
            Dive1SubStat.Lon_se_km(:)=NaN;
            Dive1SubStat.SolarEl(:)=NaN;
            writetable(Dive1SubStat,tdr1subfile);
        end

        if ~isempty(tdr2file)
            Dive2Stat=readtable(tdr2file);
            Dive2Stat.DateTime=datetime(Dive2Stat.JulDate,"ConvertFrom","datenum");
            Dive2Stat.Lat(:)=NaN;
            Dive2Stat.Lon(:)=NaN;
            Dive2Stat.Lat_se_km(:)=NaN;
            Dive2Stat.Lon_se_km(:)=NaN;
            Dive2Stat.SolarEl(:)=NaN;
            writetable(Dive2Stat,tdr2file);
        end

        if ~isempty(tdr2subfile)
            Dive2SubStat=readtable(tdr2subfile);
            Dive2SubStat.DateTime=datetime(Dive2SubStat.JulDate,"ConvertFrom","datenum");
            Dive2SubStat.Lat(:)=NaN;
            Dive2SubStat.Lon(:)=NaN;
            Dive2SubStat.Lat_se_km(:)=NaN;
            Dive2SubStat.Lon_se_km(:)=NaN;
            Dive2SubStat.SolarEl(:)=NaN;
            writetable(Dive2SubStat,tdr2subfile);
        end

        if ~isempty(tdr3file)
            Dive3Stat=readtable(tdr3file);
            Dive3Stat.DateTime=datetime(Dive3Stat.JulDate,"ConvertFrom","datenum");
            Dive3Stat.Lat(:)=NaN;
            Dive3Stat.Lon(:)=NaN;
            Dive3Stat.Lat_se_km(:)=NaN;
            Dive3Stat.Lon_se_km(:)=NaN;
            Dive3Stat.SolarEl(:)=NaN;
            writetable(Dive3Stat,tdr3file);
        end

        if ~isempty(tdr3subfile)
            Dive3SubStat=readtable(tdr3subfile);
            Dive3SubStat.DateTime=datetime(Dive3SubStat.JulDate,"ConvertFrom","datenum");
            Dive3SubStat.Lat(:)=NaN;
            Dive3SubStat.Lon(:)=NaN;
            Dive3SubStat.Lat_se_km(:)=NaN;
            Dive3SubStat.Lon_se_km(:)=NaN;
            Dive3SubStat.SolarEl(:)=NaN;
            writetable(Dive3SubStat,tdr3subfile);

        end
    end
    clear tdr1file tdr1subfile tdr2file tdr2subfile tdr3file tdr3subfile trackfile
end

