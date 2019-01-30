# Parameters for V:

* fast_iter_max    : max iteration for fast oopsi (default = 1) for parameter initialization
* smc_iter_max     : max iteration for smc (default = 1)
* dt               : 1/frame rate
* preprocess       : high-pass filtering (preprocessing)
* n_max            : max number of spike in a bin
* T                : number of time steps (length(F))
* Ncells           : # of cells in image (default: 1)
* Npixels          : # of pixels in ROI

## Parameters for V in fast-oopsi

* fast_poiss       : whether observations are Poisson
* fast_nonlin      : whether using nonlinear F([Ca++]) function
* est_sig          : whether to estimate sig
* est_lam          : whether to estimate lam
* est_gam          : whether to estimate gam; decayish, ie, tau=dt/(1-gam) (default = 0)
* est_a            : whether to estimate a
* est_b            : whether to estimate b
* fast_thr         : whether to threshold spike train before estimating 'a' and 'b'
* fast_ignore_post : whether to ignore the posterior, and just keep the last iteration

## Parameters for V in smc-oopsi
* est_c            : tau_c, A, C_0
* est_t            : tau_c (useful when data is poor)
* est_n            : b,k
* est_h            : w
* est_F            : alpha, beta
* scan             : epi or scan
* Nparticles       : # particles
* Nspikehist       : # of spike history terms
* condsamp         : whether to use conditional sampler
* ignorelik        : epi or scan
* true_n           : if true spikes are not available
* x                : stimulus
* T_o              : # of observations
* freq             : superresolution frequency


```Matlab
fr                 = 60; % Hz
V.fast_iter_max    = 10;
V.smc_iter_max     = 1000;
V.dt               = 1/fr;
V.T                = length(F);
V.preprocess       = 1;
V.n_max            = 2;
V.Ncells           = 1;
V.Npixels          = 1;

% parameters for fast-oopsi
V.fast_thr         = 0;
V.fast_ignore_post = 0;
% default parameters in Vogelstein paper:
% for brevity of code, I consider the 'if' condition using default value
% V.fast_nonlin    = 0;
% V.fast_poiss     = 0;
% V.est_sig        = 1;
% V.est_lam        = 1;
% V.est_gam        = 0;
% V.est_a          = 1;
% V.est_b          = 1;


% parameters for smc-oopsi
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
```

# Parameters for P:
* A   : initialize jump in [Ca++] after spike
* n   : Hill coefficient
* k_d : dissociation constant
* k   : approx. how many spikes underly this trace

```Matlab
P.A     = 50;
P.n     = 1;  
P.k_d   = 200; 
```
    
        
    %% define some stuff needed for est_MAP function



