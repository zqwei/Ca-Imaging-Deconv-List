warning('off', 'all');

% set simulation metadata
T       = 1000; % # of time steps
V.dt    = 1/8;  % time step size

% initialize params
P.a     = 1;    % observation scale
P.b     = 0;    % observation bias
tau     = 1.5;    % decay time constant
P.gam   = 1-V.dt/tau; % C(t) = gam*C(t-1)
P.lam   = 0.1;  % firing rate = lam*dt
P.sig   = 0.1;  % standard deviation of observation noise 

% simulate data
N = poissrnd(P.lam*V.dt*ones(T,1)); % simulate spike train
C = filter(1,[1 -P.gam],N);         % calcium concentration
F = P.a*C+P.b + P.sig*randn(T,1);   % observations

% fast oopsi
% [Nhat Phat] = fast_oopsi(F,V,P);



% smc-oopsi
fr                 = 8; % Hz
V.fast_iter_max    = 1;
V.smc_iter_max     = 100;
V.dt               = 1/fr;
V.T                = length(F);
V.preprocess       = 1;
V.n_max            = 2;
V.Ncells           = 1;
V.Npixels          = 1;
V.T_o              = V.T;
V.x                = ones(1,V.T);
V.est_c            = 1;
V.est_t            = 1;
V.est_n            = 1;
V.est_h            = 0;
V.est_F            = 1;
V.scan             = 0;
V.Nparticles       = 99;
V.Nspikehist       = 0;
V.condsamp         = 1;
V.ignorelik        = 1;
V.use_true_n       = 0;
V.freq             = 1;

Pest.A     = 50;
Pest.n     = 1;  
Pest.k_d   = 200; 

Fold       = F;

[smc, fast, F, estF] = smc_oopsi(F, V, Pest);
tvec=0:V.dt:(T-1)*V.dt;
Nfast = fast.n/max(fast.n);
Nfast(Nfast<0.1) = 0;
Nsmc = smc.M.nbar/max(smc.M.nbar);
Nsmc(Nsmc<0.1)=0;

subplot(211)
hold on
plot(tvec,F, 'linewid', 1)
plot(tvec,estF, 'linewid', 1)
plot(tvec,fast.C*fast.P.a + fast.P.b, 'linewid', 1)
xlim([0 100])
ylabel([0 1])
xlabel('time (sec)')
ylabel('normalized F')
box off
legend('raw', 'smc', 'fast')

subplot(212)
hold on
stem(tvec,N); 
stem(tvec,Nsmc)
stem(tvec,Nfast)
xlim([0 100])
ylabel([0 1])
xlabel('time (sec)')
ylabel('normalized # spk')
box off
setPrint(8, 6*2, 'smc_oopsi', 'png')
setPrint(8, 6*2, 'smc_oopsi')
