function [CaTraces, CaTracesOrg] = func_getCaTraces_general_new(SpikeTimes, ca_times, param)
 
% SpikeTimes -- {n_rep,1}

Fm = param(1);
Kd = param(2);
n = param(3);
tau_d = param(4);  % decay
tau_r = param(5);  % rise


ntime=length(ca_times);
CaTraces = [];
n_rep = size(SpikeTimes,1);
for i=1:n_rep
    
    spk_time_tmp =SpikeTimes{i,1};          
    ca_trace_tmp =zeros(ntime,1);
    
    for k=1:ntime
        s=spk_time_tmp(spk_time_tmp<ca_times(k));
        for j=1:length(s)
            ca_trace_tmp(k)=ca_trace_tmp(k)+exp(-(ca_times(k)-s(j))/tau_d)*(1-exp(-(ca_times(k)-s(j))/tau_r));
        end        
    end
    
    CaTraces(:,i) = ca_trace_tmp;
    
end
CaTracesOrg = CaTraces;
CaTraces=Fm*(CaTraces.^n)./(Kd.^n+CaTraces.^n);

% CaTraces=CaTraces+1;
% 
% time = time(201:end-200);
% PSTH = PSTH(201:end-200);
% time = time(26:end-25);
% PSTH = PSTH(26:end-25);
% time = time(101:end-100);
% PSTH = PSTH(101:end-100);

end