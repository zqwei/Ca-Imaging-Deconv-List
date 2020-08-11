%
% Single cell AP triggered fluorescence analysis -- d-prime/sensitivity
% 
% Figure 3F, Wei et al., 2020
%
% 1. Code for 6s-TG is provided; where one can change accordingly
%    to obtain a 6f-TG plot
% 2. Create Plots folder if necessary for PlotDir
%
% author: Ziqiang Wei
% email: weiz@janelia.hhmi.org
%
% 


addpath('../Func/')
setDir;
load('../TempDat/DataListCells.mat');

fs=10000; % ephys sample rate
interval_pre=1000*fs/1000; %1000ms
interval_post=500*fs/1000; %500ms
bin=200*fs/1000;   %200ms

% get GP6s-TG cells
valid_cell = false(length(totCell), 1);
for ncell  = 1:length(totCell)
    if strcmp(totCell(ncell).expression, 'transgenic') && strcmp(totCell(ncell).CaIndicator, 'GCaMP6s')
        valid_cell(ncell)=true;
    end
end
cells = totCell(valid_cell);

% data structure for nAP record
s=struct('nAP',{0,1,2,3,4,5},'ca_waveform',[],'t_ca',[]);
nAP=[0,1,2,3,4,5];

% record list for dprime and cell names
dprime_list = []; % dprime
cell_list = []; % cell names

for ncell = 1:length(cells)
    % cell name
    cell_list = [cell_list; cells(ncell).cellName]; %#ok<AGROW>   
    
    % peak df/f
    spkTime    = cells(ncell).spk;
    fmean_comp = double(cells(ncell).dff);
    t_frame    = cells(ncell).CaTime;
    spike      = [];
    recording_len = ceil(t_frame(end));
    peak       = false(recording_len*fs, 1);
    peak(round(spkTime*fs)) = true;
    
    
    % find event
    for k=1:length(nAP)    
        if nAP(k)==0
            isolate=find_no_event(peak,(interval_pre)*4); 
        else
            isolate=find_nspike_event(peak,nAP(k),bin,interval_pre,interval_post);        
        end
        ind_isolate=find(isolate);
        ind_isolate(ind_isolate>2e6)=[];
        ca_waveform=zeros(70,length(ind_isolate));
        t_ca=zeros(70,length(ind_isolate));
        valid_=true(length(ind_isolate),1);
        for n=1:length(ind_isolate)
            [~,idx]=min(abs(t_frame-ind_isolate(n)/fs));
            try
                ca_waveform(:,n)=fmean_comp(idx+(-10:59)); 
            catch
                valid_(n)=false;
                continue;
            end
            t_ca(:,n)= t_frame(idx+(-10:59))-ind_isolate(n)/fs;
            tspace   = mean(diff(t_ca(:,n)));
            tt       = (-10:59)*tspace;
            ca_int   = interp1(t_ca(:,n),ca_waveform(:,n),tt,'linear','extrap');
            ca_waveform(:,n)=ca_int;                    
            t_ca(:,n)=tt;
        end
        s(k).t_ca    =[s(k).t_ca,t_ca(:, valid_)];
        s(k).ca_waveform=[s(k).ca_waveform,ca_waveform(:, valid_)];
    end
    
    % recorded variable d-prime 1AP vs 0AP
    df=rawf2df_f(s(2).ca_waveform,1:10);
    dfnoise=rawf2df_f(s(1).ca_waveform,1:10);
    dprime = (max(mean(df, 2))-max(mean(dfnoise, 2)))/std(dfnoise(:));
    dprime_list = [dprime_list; dprime];
end

% plot -- Figure 3F
figure;
dprime_list_ = grpstats(dprime_list, cell_list, 'mean');
histogram(dprime_list_, -5:0.25:4.5, 'EdgeColor', 'r', 'FaceColor', 'none')
% ylim([0, 4])
% xlim([0, 2.5])
box off
setPrint(8, 6, [PlotDir 'dprime_distribution_6s_TG'], 'pdf')