function fit_smc_oopsi(nCell)

load('DataListCells.mat')
warning('off', 'all');

dat     = totCell(nCell);
dff     = double(dat.dff);
caTime  = double(dat.CaTime);
dt      = caTime(1) - caTime(0);
fr      = 1/dt;
% smc-oopsi
V.fast_iter_max    = 100;
V.smc_iter_max     = 100;
V.dt               = 1/fr;
V.T                = length(dff);
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
P.A     = 50;
P.n     = 1;  
P.k_d   = 200; 

[smc, fast, F, estF] = smc_oopsi(dff, V, P); %#ok<ASGLU>
smc.F                = F;
smc.F_est            = estF;
smc.freq             = V.freq;
smc.Nspikehist       = V.Nspikehist;

V.freq               = 2;
[smc_freq_2, ~, F, estF] = smc_oopsi(dff, V, P);
smc_freq_2.F             = F;
smc_freq_2.F_est         = estF;
smc_freq_2.freq          = V.freq;
smc_freq_2.Nspikehist    = V.Nspikehist;

V.freq               = 4;
[smc_freq_4, ~, F, estF] = smc_oopsi(dff, V, P);
smc_freq_4.F             = F;
smc_freq_4.F_est         = estF;
smc_freq_4.freq          = V.freq;
smc_freq_4.Nspikehist    = V.Nspikehist;

% V.freq               = 1;
% V.Nspikehist         = 1;
% [smc_Nspike_1, ~, F, estF] = smc_oopsi(dff, V, P);
% smc_Nspike_1.F             = F;
% smc_Nspike_1.F_est         = estF;
% smc_Nspike_1.freq          = V.freq;
% smc_Nspike_1.Nspikehist    = V.Nspikehist;

save(['Smc_oopsi_fit_Cell_' num2str(nCell)], 'smc', 'fast', 'smc_freq_2', 'smc_freq_4')

end
