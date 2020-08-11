function [rise_half,decay_half,time_to_peak,peak_value]=fit_dynamic(traces,t_im,t_first_stim,disp_flag)


ss=size(traces);
traces=reshape(traces,ss(1),[]);

ntraces=size(traces,2);
len=size(traces,1);

stim_ind=interp1(t_im,1:length(t_im),t_first_stim,'nearest');

for i=1:ntraces
    trace=traces(:,i);
    [peak_v,maxind]=max(trace(stim_ind:end));
    maxind=maxind+stim_ind-1;
    time_to_peak(i)=t_im(maxind)-t_first_stim;
    peak_value(i)=peak_v;
    
    half_ind=find(trace(stim_ind:maxind)>peak_v/2);
    
    if ~isempty(half_ind)
        half_ind=half_ind(1)+stim_ind-1;
        rise_half(i)=interp1([trace(half_ind-1),trace(half_ind)+eps],t_im((half_ind-1):half_ind),peak_v/2);
        rise_half(i)=rise_half(i)-t_first_stim;
    else
        rise_half(i)=0;
    end
    
    
    decay_phase=trace(maxind:end);
    decay_phase=decay_phase/decay_phase(1);
    [tau]=fit_exp_decay_fixamp_time(decay_phase,t_im(maxind:end));
    if(disp_flag)
        figure;plot(t_im(maxind:end),decay_phase);hold on;
        
        ttt=t_im(maxind:end);
        hold on;plot(ttt,exp(-(ttt-ttt(1))/tau),'r');
    end
    decay_half(i)=tau*log(2);
end

ss1=ss(2:end);
if length(ss1)<2
    ss1=[ss1,1];
end

rise_half=reshape(rise_half,ss1);
decay_half=reshape(decay_half,ss1);
time_to_peak=reshape(time_to_peak,ss1);
peak_value=reshape(peak_value,ss1);