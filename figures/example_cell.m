%
% Single cell AP triggered fluorescence analysis
% 
% Figure 3CDE, S2, Wei et al., 2020
%
% 1. Code for 6s-TG is provided; where one can change accordingly
%    to obtain a 6f-TG plot
% 2. Create Plots folder if necessary for PlotDir
%
% author: Ziqiang Wei
% email: weiz@janelia.hhmi.org
%
% 


function example_cell(cell_id)
    addpath('../Func/')
    setDir;
    load('../TempDat/DataListCells.mat');

    fs=10000; % ephys sample rate
    interval_pre=1000*fs/1000; %1000ms
    interval_post=500*fs/1000; %500ms
    bin=200*fs/1000;   %200ms

    % data structure for nAP record
    s=struct('nAP',{0,1,2,3,4,5},'ca_waveform',[],'t_ca',[]);
    nAP=[0,1,2,3,4,5];
    
    summary.nspike(1:5)=0;
    summary.amp(1:5)=0;
    summary.tpeak(1:5)=0;
    summary.decay_half(1:5)=0;
    summary.efficiency(1:5)=0;
    summary.dprime(1:5)=0;
    summary.spike_width(1:5)=0;

    % load data for cell at cellid
    spkTime    = totCell(cell_id).spk;
    fmean_comp = double(totCell(cell_id).dff);
    t_frame    = totCell(cell_id).CaTime;
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
            t_ca(:,n)=t_frame(idx+(-10:59))-ind_isolate(n)/fs;
            
            tspace=mean(diff(t_ca(:,n)));
            tt=(-10:59)*tspace;
            ca_int=interp1(t_ca(:,n),ca_waveform(:,n),tt,'linear','extrap');
            ca_waveform(:,n)=ca_int;                    
            t_ca(:,n)=tt;
        end
        s(k).t_ca=[s(k).t_ca,t_ca(:, valid_)];
        s(k).ca_waveform=[s(k).ca_waveform,ca_waveform(:, valid_)];
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Figure 3C -- nAP triggered fluorescence
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    subplot(1, 3, 1); hold on;
    color_list = {'k', 'r', 'b', 'g', 'm', 'c'};
    df_f=rawf2df_f(s(1).ca_waveform,1:10);
    t_ca=s(1).t_ca;
    plot(t_ca,df_f,'color',[0.5, 0.5, 0.5],'linewidth',1);
    plot(mean(t_ca,2),median(df_f,2),'color',[0.5, 0.5, 0.5],'linewidth',4)

    for k=2:6
        df_f=rawf2df_f(s(k).ca_waveform,1:10);
        t_ca=s(k).t_ca;
        plot(t_ca,df_f,color_list{k-1},'linewidth',1);
        plot(mean(t_ca,2),median(df_f,2),color_list{k-1},'linewidth',4)
        if size(t_ca,2)>0
            [rise_half,decay_half,time_to_peak,peak_value]=fit_dynamic_fitting(median(df_f,2),mean(t_ca,2),0,0);
        end
        amplitude(k)=mean(max(df_f(1:56,:), [],1));
        [~,idx]=max(median(df_f,2));
        sem(k-1)=std(df_f(idx,:))/sqrt(size(df_f,2));
        summary.nspike(k-1)=size(df_f,2);
        summary.amp(k-1)=max(median(df_f,2));
        summary.ampsem(k-1)=sem(k-1);
        summary.tpeak(k-1)=time_to_peak;
        summary.decay_half(k-1)=decay_half;
    end
    % ylim([-0.1,1.2]);
    xlim([-0.2,0.61]); 
    set(gca,'linewidth',1);
    box off
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Figure 3D -- nAP triggered fluorescence peak df/f
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(1, 3, 2)
    hold on
    for k=1:6
        df_f=rawf2df_f(s(k).ca_waveform,1:10);
        plot(ones(size(df_f, 2),1)*(k-1),max(df_f(1:56,:), [],1),'ok', 'linewid', 2);
    end
    plot(1:5, amplitude(2:6), '-or', 'linewid', 4)
    xlim([-0.4,5.1]);
    set(gca,'linewidth',1);
    box off

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Figure 3E -- ROC curve for spike detection
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(1, 3, 3)
    df_f_list = [];
    for k=2:6
        df_f=rawf2df_f(s(k).ca_waveform,1:10);
        df_f_list = [df_f_list, df_f];
    end

    spk_dff = max(df_f_list(1:56,:), [],1);
    nospk_dff = max(rawf2df_f(s(1).ca_waveform,1:10), [], 1);
    nospk_dff_ = max(df_f_list(1:10,:), [],1);
    nospk_dff = [nospk_dff, nospk_dff_];
    label_dff = [true(length(spk_dff),1);false(length(nospk_dff),1)];
    [X,Y] = perfcurve(label_dff,[spk_dff'; nospk_dff'],true); %, 'XVals', 0:0.1:1
    
    plot(X, Y,'-k','linewidth',2)
    hold on;
    plot([0,1],[0,1],'-k')
    xlim([0,1]);
    ylim([0,1]);
    set(gca, 'xTick', 0:0.5:1, 'yTick', 0:0.5:1)
    set(gca,'linewidth',1);
    box off