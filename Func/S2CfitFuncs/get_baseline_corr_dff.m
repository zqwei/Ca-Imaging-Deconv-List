function df_f       = get_baseline_corr_dff(para)

    cont_ratio      = 0.7;
    fs              = 10000;
    interval_pre    = 500*fs/1000; %500ms
%     interval_post   = 1000*fs/1000; %250ms
%     bin             = 200*fs/1000;  %200ms

    peak            = para.peak;
    fmean           = para.fmean;
    fneuropil       = para.fneuropil;
%     filt            = para.filt;
    fmean_comp      = fmean-fneuropil*cont_ratio;



%  correct for baseline drift
%     [event,next_spike]=find_no_event(peak,(interval_pre)*6); 
    [~, next_spike] = find_no_event(peak,(interval_pre)*6); 
    idx_next_spike  = find(next_spike);
    t_f0            = zeros(size(idx_next_spike));
    f0              = zeros(size(idx_next_spike));
    
    for n           = 1:length(idx_next_spike)
        d           = para.t_frame-para.t_ephys(idx_next_spike(n));
        d(d>0)      = 0;
%         [m,id]=min(abs(d));
        [~,id]      = min(abs(d));
        t_f0(n)     = para.t_frame(id);
        f0(n)       = mean(fmean_comp(id+(-30:-1)));
    end
    
    if t_f0(end)    == para.t_frame(end)
%         baseline=interp1([0;t_f0],[f0(1);f0],para.t_frame,'cubic');
        baseline    = interp1([0;t_f0],[f0(1);f0],para.t_frame,'PCHIP');
    else
%         baseline=interp1([0;t_f0;para.t_frame(end)],[f0(1);f0;(f0(end))],para.t_frame,'cubic');
        baseline    = interp1([0;t_f0;para.t_frame(end)],[f0(1);f0;(f0(end))],para.t_frame,'PCHIP');
    end
    
    
    df_f            = (fmean_comp-baseline)./baseline;