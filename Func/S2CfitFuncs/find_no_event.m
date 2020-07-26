function [event,next_spike]=find_no_event(peak,interval)
fs=10000;

% interval_pre=1000*fs/1000; %1000ms
% interval_post=250*fs/1000; %100ms
% bin=200*fs/1000;   %500ms

ind=find(peak);
event=zeros(size(peak));
next_spike=zeros(size(peak));

for i=1:(length(ind)-1)
    if (ind(i+1)-ind(i))>interval
        position=round((ind(i)+ind(i+1))/2);
        event(position)=1;
        next_spike(ind(i+1))=1;
    end
end
