%
% this function runs MLspike
% Main paper: Deneux, T., Kaszas, A., Szalay, G., Katona, G., Lakner, T., 
%             Grinvald, A., ... & Vanzetta, I. (2016). Accurate spike 
%             estimation from noisy calcium signals for ultrafast three-
%             dimensional imaging of large neuronal populations in vivo. 
%             Nature communications, 7, 12190.
% https://github.com/MLspike
% Revised by Ziqiang Wei
% weiz AT janelia DOT hhmi DOT org
%

%% main code
function est = mlspike(dff, fr)
    
    addpath('../Func/MLspike/')
    
    amin = .04;
    amax = max(dff);
    taumin = .1;
    taumax = 3.0;
    
    pax = spk_autocalibration('par');
    pax.dt = 1/fr;
    % (set limits for A and tau)
    pax.amin = amin;
    pax.amax = amax;
    pax.taumin = taumin;
    pax.taumax = taumax;
    pax.eventtau = 1.0;
    % (set saturation parameter)
    pax.saturation = .5;
    pax.mlspikepar.dographsummary = false;
    pax.display = 'none';
    % perform auto-calibration
    aest = [];
    n_ = 0.0;
    while isempty(aest) && n_<=1.0
        n_ = n_ + 0.1;
        pax.eventa = amax * n_;
        [tauest, aest, sigmaest] = spk_autocalibration(dff,pax);
    end
    
    % parameters
    par = tps_mlspikes('par');
    par.dt = 1/fr;
    % (use autocalibrated parameters)
    if isempty(aest)
        aest = amax;
    end
    
    if isempty(tauest)
        tauest = 1.5;
    end
    
    par.a = aest;
    par.tau = tauest;
    par.finetune.sigma = sigmaest;
    % (the OGB saturation and drift parameters are fixed)
    par.saturation = 0;
    par.drift.parameter = .001;
    % (do not display graph summary)
    par.dographsummary = false;
    % spike estimation
    [spikest, fit, drift, parest] = spk_est(dff,par);
    
    est.spk    = spikest;
    est.drift  = drift;
    est.F_est  = fit;
    est.parest = parest; 
end