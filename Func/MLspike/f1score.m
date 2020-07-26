function ER = f1score(miss,falsep,nsptrue,nspest)
% function ER = f1score(nmiss,nfalsep,nsptrue,nspest)
% function ER = f1score(miss,falsep)

if nargin==0, help f1score, return, end

if nargin==4
    miss = fn_float(miss)./fn_float(nsptrue);
    falsep = fn_float(falsep)./fn_float(nspest);
end

miss(isnan(miss)) = 0; % no real spikes: no miss!
falsep(isnan(falsep)) = 0; % no spike detected: no false positive!
ss = 1-miss;
pr = 1-falsep;
ER = 1 - 2*ss.*pr./(ss+pr);
ER(ss+pr==0) = 1; % there are real spikes and detected spikes, but none of them do match!! 
