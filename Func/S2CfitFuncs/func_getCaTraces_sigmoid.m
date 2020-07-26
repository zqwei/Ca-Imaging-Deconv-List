function [CaTraces, CaTracesOrg] = func_getCaTraces_sigmoid(SpikeTimes, ca_times, param)
 
% SpikeTimes -- {n_rep,1}

Fm = param(1);
Ca0 = param(2);
beta = param(3);
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
CaTraces=Fm./(1+exp(-(CaTraces-Ca0)*beta));

end