% F(t)              = a*[Ca](t)  + b
% -------------------------------------------------------------------------
% Ziqiang Wei
% weiz@janelia.hhmi.org
% 


function [CaTraces] = func_getCaTraces_quadratic(SpikeTimes, ca_times, param)

    a               = param(1);
    b               = param(2);
    c               = param(3);
    tau_d           = param(4);  % decay
    tau_r           = param(5);  % rise

    nTime           = length(ca_times);
    CaTraces        = zeros(nTime, 1);
    
    for nSpike      = 1:length(SpikeTimes)
        nSpikeTime  = SpikeTimes(nSpike);
        tAfterSpike = ca_times(ca_times>nSpikeTime);
        CaTraces(ca_times>nSpikeTime) = CaTraces(ca_times>nSpikeTime) + ...
                                            exp(-(tAfterSpike-nSpikeTime)/tau_d).* ...
                                            (1-exp(-(tAfterSpike-nSpikeTime)/tau_r));
    end

    CaTraces           = a*CaTraces.^2 + b*CaTraces + c;