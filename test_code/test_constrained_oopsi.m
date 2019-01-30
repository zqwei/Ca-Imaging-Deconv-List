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
% smc-oopsi
fr                 = 8; % Hz
tvec=0:V.dt:(T-1)*V.dt;

figure;
[c, b, c1, g, sn, sp] = constrained_foopsi(F);
subplot(211)
hold on
plot(tvec,F)
plot(tvec,c) % c is F_est
% title('constrained_foopsi')
subplot(212)
hold on
stem(tvec,N); 
plot(tvec,sp) %sp is n_bar in most of foopsi code
% title('constrained_foopsi')
