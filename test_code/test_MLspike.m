addpath('../Func/MLspike/')
ntrial = 6;
T = 30;
rate = 1;

% generate spikes
spikes = spk_gentrain(rate,T,'bursty','repeat',ntrial);


amin = .04;
amax = .1;
a = amin * exp(rand(1)*log(amax/amin)); % log-uniform distribution 

taumin = .4;
taumax = 1.6;
tau = taumin * exp(rand(1)*log(taumax/taumin));

sigmamin = .005;
sigmamax = .05;
sigma = sigmamin * exp(rand(1)*log(sigmamax/sigmamin));

dt = .02; % 50Hz acquisition
pcal = spk_calcium('par');
pcal.dt = dt;
pcal.a = a;
pcal.tau = tau;
pcal.saturation = .1; % saturation level is fixed
pcal.sigma = sigma; % noise level
pcal.drift.parameter = [5 .015]; % drift level (#harmonics and amplitude of them)

% generate calcium
calcium = spk_calcium(spikes,pcal);

pax = spk_autocalibration('par');
pax.dt = dt;
% (set limits for A and tau)
pax.amin = amin;
pax.amax = amax;
pax.taumin = taumin;
pax.taumax = taumax;
% (set saturation parameter)
pax.saturation = 0.1;
% (give real values to the algorithm for display purposes - they obviously won't be used in the estimation!)
pax.realspikes = spikes;
pax.reala = a;
pax.realtau = tau;
% (when running MLspike from spk_autocalibratio, do not display graph summary)
pax.mlspikepar.dographsummary = false;
% perform auto-calibration
[tauest, aest, sigmaest] = spk_autocalibration(calcium,pax);



% parameters
par = tps_mlspikes('par');
par.dt = dt;
% (use autocalibrated parameters)
par.a = aest;
par.tau = tauest;
par.finetune.sigma = sigmaest;
% (the OGB saturation and drift parameters are fixed)
par.saturation = 0.1;
par.drift.parameter = .01;
% (do not display graph summary)
par.dographsummary = false;
% spike estimation
[spikest, fit, drift] = spk_est(calcium,par);