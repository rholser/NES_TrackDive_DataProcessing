function [want,newdepth,indexes]=iknos_find_dive(time,timemultiple,depth,depthmultiple)
% YT_FIND_DIVE is an internal function to the YT_IKNOS_DA program.
% Its use is pretty much restricted to it.
% control:
% depth doit etre clean...(yt_zoc), avec des zeros en surface)
% size time = size depth
% timemultiple and depthmultiple == entiers
% CREDIT:
%  Created by Yann Tremblay (2004, The IKNOS Toolbox).
% 20 June 2004: Bug solved.
% 7-9 August 2005: modified to account for the fact that some records have
% a bug in it: The sampling interval is sometimes changed to sampling
% interval + 1 second...
%
%  Modified 9 December 2022 (Arina Favilla): changed yt_resolution() to
%  either resolution_DepthRes() or resolution_SamplingRate()
%  Renamed 16 December 2022 (Arina Favilla): renamed from yt_find_dive to
%  find_dive

%%%-----DEPTH---------
    intervaldepth=resolution_DepthRes(depth); % changed by Arina

        if intervaldepth<0.1
        depth=iknos_round2nearest(depth,0.1);
        intervaldepth=0.1;
    elseif intervaldepth>0.1 & intervaldepth<0.2
         depth=iknos_round2nearest(depth,0.2);
         intervaldepth=0.2;
    elseif intervaldepth>0.2 & intervaldepth<0.3
         depth=iknos_round2nearest(depth,0.3);
         intervaldepth=0.3;
    elseif intervaldepth>0.3 & intervaldepth<0.4
         depth=iknos_round2nearest(depth,0.4);
         intervaldepth=0.4;
    elseif intervaldepth>0.4 & intervaldepth<0.5
         depth=iknos_round2nearest(depth,0.5);
         intervaldepth=0.5;
        end
    
if ~isempty(find(depth>=depthmultiple*intervaldepth)) %% i.e. there is some depth readings corresponding to dive depth criteria

 check_depth1=depth==0;
 check_depth2=depth==intervaldepth;
     
%%%-----TIME-----------
    intervaltime=resolution_SamplingRate(round(time.*86400));
    st=size(time,1);

% Does sampling is continuous (1) or not (0) ??
    if sum(diff(round(time.*86400)))/intervaltime==st-1
        continuous=1;
    else continuous=0;
    end

    
if continuous==0
        check_time=diff(round(time.*86400))<=intervaltime+1; % logical array
        check_time=[check_time;0]; %same size as check depth
        idt=iknos_setones(check_time); %% idt for "index time"
        idt(:,2)=idt(:,2)+1;

        idd=[];
        flagtotrash=[];
        for i=1:size(idt,1)
            check_depth=depth(idt(i,1):idt(i,2),1)>intervaldepth; 
            idd_add=iknos_setones(check_depth);  

            flgtrash_add=ones(size(idd_add,1),1);
            
        if ~isempty(idd_add)
            idd_add(:,:)=idd_add(:,:)+idt(i,1)-1;
            idd=[idd;idd_add];
            for k=1:size(idd_add,1)
                if max(depth(idd_add(k,1):idd_add(k,2),1))<depthmultiple*intervaldepth
                flgtrash_add(k,1)=0;
                end 
            end 
        flagtotrash=[flagtotrash;flgtrash_add];
        end  
        end

    idd=idd(find(flagtotrash),:);

    
% check_depth=depth(idt(i,1):idt(i,2),1)>=intervaldepth*depthmultiple;
% idd_add=iknos_setones(check_depth);   
% if isempty(idd_add)==0
% idd_add(:,:)=idd_add(:,:)+idt(i,1)-1;
% idd=[idd;idd_add];
% end

    sidd=size(idd,1);
    idd2=zeros(size(idd,1),size(idd,2));

%%% first case
   if idd(1,1)~=1
        a=find(check_depth1(1:idd(1,1),1));
        aa=find(check_depth2(1:idd(1,1),1));
        aaa=find( depth(1:idd(1,1),1)==min(depth(1:idd(1,1),1) ));
        b=find(check_time(1:idd(1,1),1)==0);
        
        if size(a,1)<2 & isempty(aa)==0
            idd2(1,1)=max([aa;b+1]); 
        elseif size(a,1)<2 & isempty(aa)
            idd2(1,1)=max([aaa;b+1]); 
        else
            idd2(1,1)=max([a;b+1]);
        end
    else
    idd2(1,1)=1;
    end
%%% last case
    if idd(sidd,2)~=st
        c=find(check_depth1(idd(sidd,2):st,1));
        cc=find(check_depth2(idd(sidd,2):st,1));
        ccc=find(depth(idd(sidd,2):st,1)==min(depth(idd(sidd,2):st,1)));
        d=find(check_time(idd(sidd,2):st,1)==0);
    if size(c,1)<2 & isempty(cc)==0
        idd2(sidd,2)=min([cc;d])+idd(sidd,2)-1;
    elseif size(c,1)<2 & isempty(cc)
        idd2(sidd,2)=min([ccc;d])+idd(sidd,2)-1;
    else
    idd2(sidd,2)=min([c;d])+idd(sidd,2)-1;    
    end
    else
    idd2(sidd,2)=idd(sidd,2);
    end  
%%% Other cases
    for i=1:sidd-1
    e=find(check_depth1(idd(i,2):idd(i+1,1),1));
    ee=find(check_depth2(idd(i,2):idd(i+1,1),1));
    eee=find(depth(idd(i,2):idd(i+1,1),1)==min(depth(idd(i,2):idd(i+1,1),1)));
    f=find(check_time(idd(i,2):idd(i+1,1),1)==0);
    if size(e,1)<2 & isempty(ee)==0
        idd2(i,2)=min([ee;f])+idd(i,2)-1;
        idd2(i+1,1)=max([ee;f+1])+idd(i,2)-1;
    elseif size(e,1)<2 & isempty(ee)
        idd2(i,2)=min([eee;f])+idd(i,2)-1;
        idd2(i+1,1)=max([eee;f+1])+idd(i,2)-1;
    else
        idd2(i,2)=min([e;f])+idd(i,2)-1;
        idd2(i+1,1)=max([e;f])+idd(i,2)-1;
    end
    end
    
else  %% this is if continuous==1
    check_depth=depth>intervaldepth;
    idd=iknos_setones(check_depth);
    flagtotrash=ones(size(idd,1),1);
   if ~isempty(idd)
   for k=1:size(idd,1)
       if max(depth(idd(k,1):idd(k,2),1))<depthmultiple*intervaldepth
              flagtotrash(k,1)=0;
       end 
   end 
   end 
   
idd=idd(find(flagtotrash),:);
sidd=size(idd,1);
idd2=zeros(size(idd,1),2);

%%% first case
if idd(1,1)~=1
    a=find(check_depth1(1:idd(1,1),1));
    aa=find(check_depth2(1:idd(1,1),1));
    aaa=find( depth(1:idd(1,1),1)==min(depth(1:idd(1,1),1) ));
    if size(a,1)<2 & isempty(aa)==0
           idd2(1,1)=max(aa); 
    elseif size(a,1)<2 & isempty(aa)
           idd2(1,1)=max(aaa); 
    else
    idd2(1,1)=max(a);
    end
else
    idd2(1,1)=1;
end
%%% last case
if idd(sidd,2)~=st
    c=find(check_depth1(idd(sidd,2):st,1));
    cc=find(check_depth2(idd(sidd,2):st,1));
    ccc=find(depth(idd(sidd,2):st,1)==min(depth(idd(sidd,2):st,1)));
    if size(c,1)<2 & isempty(cc)==0
        idd2(sidd,2)=min(cc)+idd(sidd,2)-1;
    elseif size(c,1)<2 & isempty(cc)
        idd2(sidd,2)=min(ccc)+idd(sidd,2)-1;
    else
    idd2(sidd,2)=min(c)+idd(sidd,2)-1;    
    end
    else
    idd2(sidd,2)=idd(sidd,2);
end  

%%% Other cases
for i=1:sidd-1
    e=find(check_depth1(idd(i,2):idd(i+1,1),1));
    ee=find(check_depth2(idd(i,2):idd(i+1,1),1));
    eee=find(depth(idd(i,2):idd(i+1,1),1)==min(depth(idd(i,2):idd(i+1,1),1)));
    if size(e,1)<2 & isempty(ee)==0
    idd2(i,2)=min(ee)+idd(i,2)-1;
    idd2(i+1,1)=max(ee)+idd(i,2)-1;
    elseif size(e,1)<2 & isempty(ee)
    idd2(i,2)=min(eee)+idd(i,2)-1;
    idd2(i+1,1)=max(eee)+idd(i,2)-1;
    else
    idd2(i,2)=min(e)+idd(i,2)-1;
    idd2(i+1,1)=max(e)+idd(i,2)-1;
    end
end
    
end

keep=find((idd2(:,2)-idd2(:,1))>=timemultiple);

            if isempty(keep)
                disp('There is no dive corresponding to input criteria.')
                want=[]; newdepth=depth; indexes=[];
            else
              idd2=idd2(keep,:);
                if ~isempty(find(depth(idd2(:,1),1)==intervaldepth))
                depth(idd2(find(depth(idd2(:,1),1)==intervaldepth),1),1)=0;
                end
                if ~isempty(find(depth(idd2(:,2),1)==intervaldepth))
                depth(idd2(find(depth(idd2(:,2),1)==intervaldepth),2),1)=0;
                end

            %%% OUTPUTS---------
            sidd=size(idd2,1);
            want=[];
            for i=1:sidd
                if max(depth(idd2(i,1):idd2(i,2),1))>=depthmultiple*intervaldepth
               want=[want;(idd2(i,1):1:idd2(i,2))'];
                else
                    idd2(i,1:2)=NaN;
                    depth(idd2(i,1):idd2(i,2),1)=0;
                end
            end
            newdepth=depth;
            indexes=idd2(find(~isnan(idd2(:,1))),:);
            end

% find_dives=iknos_setones(check_depth,timemultiple+1); % Example: 4 points represent 3 minimum time intervals !
% sfind_dives=size(find_dives,1);
% mx_depth=zeros(sfind_dives,1);
% for i=1:sfind_dives
%     mx_depth(i)=max(depth(find_dives(i,1):find_dives(i,2),1));
% end
% 
% mindepth=depthmultiple*intervaldepth;
% find_dives=find_dives(find(mx_depth>=mindepth),:);
% sfind_dives=size(find_dives,1);
% 
% want=[];
% 
% for i=1:sfind_dives
%     a=find_dives(i,1); b=find_dives(i,2);
%     want=[want;(a-1:1:b+1)'];
% end

else %% this is: isempty(find(depth>=depthmultiple*intervaldepth))
    disp('There is no dive corresponding to input criteria.')
    want=[]; newdepth=depth; indexes=[];
end

% depthcheck=newdepth(want,1);
% id1=idd2(:,2)-idd2(:,1)+1;
% id2=cumsum(idd2(:,2)-idd2(:,1)+1);
% id3=[1;id2(1:size(id2,1)-1,1)+1];
% id3=[id3,id3+id1-1];


