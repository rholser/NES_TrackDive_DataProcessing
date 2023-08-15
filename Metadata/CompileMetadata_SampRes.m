clear
load('MetaData.mat')
load('All_Filenames.mat')

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 31);

% Specify range and delimiter
opts.DataLines = [19, 20];


opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["DiveNumber", "Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31"];
opts.SelectedVariableNames = "DiveNumber";
opts.VariableTypes = ["string", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31"], "EmptyFieldRule", "auto");


%% Extract frequency and resolution and add to TagMetaDataAll

TagMetaDataAll.TDR1_Res(:)=NaN;
TagMetaDataAll.TDR1_Freq(:)=NaN;
TagMetaDataAll.TDR2_Res(:)=NaN;
TagMetaDataAll.TDR2_Freq(:)=NaN;
TagMetaDataAll.TDR3_Res(:)=NaN;
TagMetaDataAll.TDR3_Freq(:)=NaN;

for i=1:size(TagMetaDataAll,1)
%for j=1:size(ind)
 %   i=ind(j);
    TOPPID=TagMetaDataAll.TOPPID(i);
    if sum(ismember(TDRDiveStatFiles.TOPPID,TOPPID))>0
        data=readtable(strcat(TDRDiveStatFiles.folder(TDRDiveStatFiles.TOPPID==TOPPID),'\',...
            TDRDiveStatFiles.filename(TDRDiveStatFiles.TOPPID==TOPPID)),opts);

        Res=extractAfter(data.DiveNumber(2),'= ');
        TagMetaDataAll.TDR1_Res(i)=double(extractBefore(Res,' m'));
        Freq=extractAfter(data.DiveNumber(1),'= ');
        TagMetaDataAll.TDR1_Freq(i)=double(extractBefore(Freq,' s'));
    end
    if sum(ismember(TDR2DiveStatFiles.TOPPID,TOPPID))>0
        data=readtable(strcat(TDR2DiveStatFiles.folder(TDR2DiveStatFiles.TOPPID==TOPPID),'\',...
            TDR2DiveStatFiles.filename(TDR2DiveStatFiles.TOPPID==TOPPID)),opts);

        Res=extractAfter(data.DiveNumber(2),'= ');
        TagMetaDataAll.TDR2_Res(i)=double(extractBefore(Res,' m'));
        Freq=extractAfter(data.DiveNumber(1),'= ');
        TagMetaDataAll.TDR2_Freq(i)=double(extractBefore(Freq,' s'));
    end
    if sum(ismember(TDR3DiveStatFiles.TOPPID,TOPPID))>0
        data=readtable(strcat(TDR3DiveStatFiles.folder(TDR3DiveStatFiles.TOPPID==TOPPID),'\',...
            TDR3DiveStatFiles.filename(TDR3DiveStatFiles.TOPPID==TOPPID)),opts);

        Res=extractAfter(data.DiveNumber(2),'= ');
        TagMetaDataAll.TDR3_Res(i)=double(extractBefore(Res,' m'));
        Freq=extractAfter(data.DiveNumber(1),'= ');
        TagMetaDataAll.TDR3_Freq(i)=double(extractBefore(Freq,' s'));
    end
    clear Freq Res
end

ind=find(TagMetaDataAll.TDR1QC<5 & isnan(TagMetaDataAll.TDR1_Res));

%for newer format DiveStat files
opts.DataLines = [16, 17];

for j=1:size(ind)
   i=ind(j);
    TOPPID=TagMetaDataAll.TOPPID(i);
    if sum(ismember(TDRDiveStatFiles.TOPPID,TOPPID))>0
        data=readtable(strcat(TDRDiveStatFiles.folder(TDRDiveStatFiles.TOPPID==TOPPID),'\',...
            TDRDiveStatFiles.filename(TDRDiveStatFiles.TOPPID==TOPPID)),opts);

        Res=extractAfter(data.DiveNumber(2),'= ');
        TagMetaDataAll.TDR1_Res(i)=double(extractBefore(Res,' m'));
        Freq=extractAfter(data.DiveNumber(1),'= ');
        TagMetaDataAll.TDR1_Freq(i)=double(extractBefore(Freq,' s'));
    end
    if sum(ismember(TDR2DiveStatFiles.TOPPID,TOPPID))>0
        data=readtable(strcat(TDR2DiveStatFiles.folder(TDR2DiveStatFiles.TOPPID==TOPPID),'\',...
            TDR2DiveStatFiles.filename(TDR2DiveStatFiles.TOPPID==TOPPID)),opts);

        Res=extractAfter(data.DiveNumber(2),'= ');
        TagMetaDataAll.TDR2_Res(i)=double(extractBefore(Res,' m'));
        Freq=extractAfter(data.DiveNumber(1),'= ');
        TagMetaDataAll.TDR2_Freq(i)=double(extractBefore(Freq,' s'));
    end
    if sum(ismember(TDR3DiveStatFiles.TOPPID,TOPPID))>0
        data=readtable(strcat(TDR3DiveStatFiles.folder(TDR3DiveStatFiles.TOPPID==TOPPID),'\',...
            TDR3DiveStatFiles.filename(TDR3DiveStatFiles.TOPPID==TOPPID)),opts);

        Res=extractAfter(data.DiveNumber(2),'= ');
        TagMetaDataAll.TDR3_Res(i)=double(extractBefore(Res,' m'));
        Freq=extractAfter(data.DiveNumber(1),'= ');
        TagMetaDataAll.TDR3_Freq(i)=double(extractBefore(Freq,' s'));
    end
    clear Freq Res
end

save('MetaData.mat','MetaDataAll','TagMetaDataAll')