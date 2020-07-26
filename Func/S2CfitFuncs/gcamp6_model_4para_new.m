function para_final =  gcamp6_model_4para_new(spk, dff, t_frame, para_start, p_fix_index)
    
    x.spk           = spk;
    x.dff           = dff;
    x.t_frame       = t_frame;
    p_fix           = para_start;
    p_fix(~p_fix_index) = nan;
    pfit_start      = para_start(~p_fix_index);
    options         = optimset('Display','off','TolX',1e-5,'TolFun',1e-2);
    pfit_final      = fminsearch(@(p_fit) func_error(x, p_fix, p_fit), pfit_start, options);
    para_final      = p_fix;
    para_final(isnan(para_final)) = pfit_final;
end

function mse   = func_error(x, p_fix, p_fit)
    CaTraces   = func_getCaTraces(x.spk, x.t_frame, p_fix, p_fit);
    mse        = sum((CaTraces - x.dff).^2);
%     fprintf('MSE value: %f\n', mse)
end

function CaTraces = func_getCaTraces(SpikeTimes, ca_times, p_fix, p_fit)

    param = p_fix;
    param(isnan(param)) = p_fit;
    
    Fm = param(1);
    Kd = param(2);
    n = param(3);
    tau_d = param(4);  % decay
    tau_r = param(5);  % rise
    ntime=length(ca_times);
    n_rep = size(SpikeTimes,1);
    CaTraces = nan(ntime, n_rep);
    
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

    CaTraces=Fm*(CaTraces.^n)./(Kd.^n+CaTraces.^n);

end