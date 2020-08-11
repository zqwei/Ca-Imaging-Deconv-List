function [event,last_spike]=find_nspike_event(peak,n,bin,interval_pre,interval_post)
fs=10000;

% interval_pre=1000*fs/1000; %1000ms
% interval_post=250*fs/1000; %100ms
% bin=200*fs/1000;   %500ms

ind=find(peak);
event=zeros(size(peak));
last_spike=zeros(size(peak));
for i=2:(length(ind)-n)   
    if (ind(i+n-1)-ind(i))<bin   % if first spike and last spike occur within bin     
        if (ind(i)-ind(i-1))>interval_pre    % if the previous spike occur > 1000ms earlier than first spike
            if (ind(i+n)-ind(i+n-1))>interval_post  % if the next train start >1000ms after the last spike
                event(ind(i))=1;
                last_spike(ind(i+n-1))=1;
            end
        end
    end
end