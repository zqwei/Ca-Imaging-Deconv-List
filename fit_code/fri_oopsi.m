%
% this function runs Fast rate of innovation algorithm
% Main paper: Jon Oñativia, Simon R. Schultz, and Pier Luigi Dragotti, A 
%             Finite Rate of Innovation algorithm for fast and accurate 
%             spike detection from two-photon calcium imaging. (J. Neural 
%             Eng. 10 (2013) 046017)
% Original by Jon Oñativia
% http://www.commsp.ee.ic.ac.uk/~jo210/src/ca_transient.zip
% Revised by Ziqiang Wei
% weiz AT janelia DOT hhmi DOT org
%

%% main code
function fri = fri_oopsi(dff, tau, fr)
    T_s = 1/fr;
    f_s = fr;
    T   = T_s;
    t   = (1:length(dff))*T_s;
    t   = t'
    
    t_k1     = [];
    a_k1     = [];
    win_idx1 = [];
    t_k2     = [];
    a_k2     = [];
    win_idx2 = [];
    % First iteration, big window size and K estimated from S matrix
    win_len1 = 32;
    [t_k1, a_k1, win_idx1] = ca_detect_sliding_emom(dff, ...
                                                    t, ...
                                                    win_len1, ...
                                                    tau, ...
                                                    T, ...
                                                    'estimate');
    t_k = t_k1;
    % Second iteration, small window and fixed K
    win_len2 = 8;
    K_fix    = 1;
    [t_k2, a_k2, win_idx2] = ca_detect_sliding_emom(dff, ...
                                                    t, ...
                                                    win_len2, ...
                                                    tau, ...
                                                    T, ...
                                                    'fixed', ...
                                                    K_fix);
    t_k = [t_k; t_k2];
    % Count the number of detected exponentials within a time interval
    hist_res   = 1; % => produce the histogram with a higher res than original_t
    T_h        = T_s / hist_res;
    hist_t     = (t(1) : T_h : t(end))';
    hist_len   = length(hist_t);
    delta_t    = 1 * T_h;
    hist_sp    = zeros(hist_len, 1);
    max_detect = win_len1 + win_len2;
    for ith_t = 1 : hist_len
        t_i = hist_t(ith_t);
        inds           = find(t_k > (t_i - delta_t/2) & t_k < (t_i + delta_t/2));
        hist_sp(ith_t) = length(inds);
    %     if hist_sp(ith_t) > threshold
    %         sspp = [sspp; mean(t_k(inds))];
    %     end
    end
    % Only take into account the peak of the histograms
    sspp       = [];
    threshold  = 0.45 * max_detect;
    for ith_t = 1 : hist_len
        if hist_sp(ith_t) > threshold
            if ( ith_t < hist_len && (hist_sp(ith_t) >= hist_sp(ith_t+1)) ) ...
            && ( ith_t > 1       && (hist_sp(ith_t) >  hist_sp(ith_t-1)) )
                t_i  = hist_t(ith_t);
                inds = find(t_k > (t_i - delta_t/2) & t_k < (t_i + delta_t/2));
                sspp = [sspp; mean(t_k(inds))]; %#ok<AGROW>
            end
        end
    end
    % Retrieve the amplitudes of the spikes
    aapp = retrieve_amplitudes(dff, t, sspp, 7*T_s, .5);
    % Remove spikes with an amplitude smaller than a threshold
    max_amp = max(dff);
    sspp(aapp < 0.3 * max_amp) = [];
    aapp(aapp < 0.3 * max_amp) = [];
    fri.spk    = sspp;
    fri.spkAmp = aapp;
    
    caTime     = zeros(size(dff));
    for nSpk   = 1:length(sspp)
        spkTime = sspp(nSpk);
        expDecay = exp(-(t-spkTime)/tau);
        expDecay(expDecay>1) = 0;
        caTime  = caTime + aapp(nSpk)* expDecay;
    end
    fri.F_est  = caTime;
end


%%
function [t_k, a_k, win_idx, K_i] = ca_detect_sliding_emom(original_signal, ...
                                                        original_t, ...
                                                        win_len, ...
                                                        tau, ...
                                                        T, ...
                                                        mode, ...
                                                        param1, ...
                                                        param2)
% -------------------------------------------------------------------------
% Recover a stream of decaying exponentials with constant tau with a 
% sliding window. All the decaying exponentials have the same constant. 
% The amount of decaying exponentials for a given window position can be 
% estimated from the signal, given by an oracle (we know the locations of 
% the exponentials), or considered to be fixed and equal for every 
% positions.
%
% USAGE:
%  [t_k, a_k, win_idx, max_K] = ca_detect_sliding_window(original_signal, ...
%                                                        original_t, ...
%                                                        win_len, ...
%                                                        tau, ...
%                                                        mode, ...
%                                                        param1, ...
%                                                        param2)
%
% INPUT:
%  - original_signal : Input signal with the stream of noisy decaying exps.
%  - original_t      : Time stamps of the signal's samples.
%  - win_len         : Size of the sliding window.
%  - tau             : Constant of the decaying exponentials
%                      (exp(-(t-t_k)/tau)).
%  - T               : Sampling period.
%  - mode            : Mode to estimate the number of exponentials within
%                      a window. Can be 'estimate' (number of exponentials 
%                      estimated from the signal), 'oracle' (the locations
%                      are provided) or 'fixed' (same number of exponential
%                      for every window positions).
%  - params          : If mode='oracle' this parameter provides the true
%                      positions of the exponentials.
%                      If mode='fixed' this parameter is a scalar that 
%                      provides the number of exponentials within a window.
%
% OUTPUT:
%  - t_k             : Locations of the retrieved locations.
%  - a_k             : Amplitude of the retrieved locations.
%  - win_idx         : Window for wich each t_k and a_k have been
%                      retrieved.
%  - K_i             : Vector with detected K within window each.
%
% -------------------------------------------------------------------------
if nargin < 5 || nargin > 8
    error('ca_detect_sliding_window:err_arg', 'The number of input arguments is incorrect.')
elseif nargin == 5
    mode = 'estimate';
end
if strcmp(mode, 'estimate')
    mode = 1;
elseif strcmp(mode, 'oracle')
    sp   = param1;
    mode = 2;
elseif strcmp(mode, 'fixed')
    K_fix = param1;
    mode  = 3;
elseif strcmp(mode, 'partial_oracle_fixed') % oracle only for K=0
    sp    = param1;
    K_fix = param2;
    mode  = 4;
elseif strcmp(mode, 'partial_oracle_estimate') % oracle only for K=0
    sp    = param1;
    mode  = 5;
end
% Sampling period and time window length
T_s     = mean(diff(original_t));
TTs     = T / T_s;
N       = win_len;
tot_len = length(original_t);
% Add 'win_len' zeros before and after the signal
% original_signal = [zeros(win_len,1); original_signal; zeros(win_len,1)];
% t_00            = original_t(1) - win_len * T_s;
% t_01            = original_t(1) - T_s;
% t_end0          = original_t(end) + T_s;
% t_end1          = original_t(end) + win_len * T_s;
% original_t      = [(t_00:T_s:t_01)'; original_t; (t_end0:T_s:t_end1)'];
% Time-resolution increase to improve beta and psi kernels precision
over_samp = 512;
T_s2      = T / over_samp;
% Construct the kernel
P            = N / 2;
m            = 0:P;
alpha_0      = -1j * pi / 2;
lambda       = 1j * pi / P;
alpha_vec    = alpha_0 + lambda * m;
[phi, t_phi] = generate_e_spline(alpha_vec, T_s2, T); %#ok<ASGLU>
t_diric = (0:T_s2/T:P+1)'*2*pi/(P+1);
t_diric = t_diric - (t_diric(end)-t_diric(1))/2;
b       = diric(t_diric, (P+1));
phi     = real(b);
% Compute psi(t) = beta_-alphaT(t) * phi(t)
alpha                 = 1 / tau;
[beta_alphaT, t_beta] = generate_e_spline(-alpha*T, T_s2, T);
beta_alphaT_rev       = [0; beta_alphaT(end:-1:2)];
t_beta_rev            = -t_beta(end:-1:1);
t_0                   = t_phi(1) + t_beta_rev(1);
t_end                 = t_phi(end) + t_beta_rev(end);
psi                   = T_s2 * conv(phi, beta_alphaT_rev);
t_psi                 = (t_0:T_s2:t_end)';
% Time interval that we consider (exponential reproduction interval)
if mod(N, 2) == 0
    n1 = -N/2;
    n2 = N/2 - 1;
else
    n1 = -(N-1)/2;
    n2 = (N-1)/2;
end
n_vec = (n1:n2)';
t1    = n1 * T;
t2    = (n2+1) * T - T_s;
t     = (t1:T_s:t2)';
% c_m_n parameters
c_m_n = get_c_m_n_exp(alpha_vec, n_vec, psi, t_psi, T);
t_phi = t_phi(1:over_samp/TTs:end);
phi   = real(phi(1:over_samp/TTs:end));

t_k      = [];
a_k      = [];
win_idx  = [];
step     = TTs;
num_wins = floor((tot_len-win_len)/step) + 1;
K_i      = zeros(num_wins,1);
ith_win  = 1;
for i_0 = 1 : step : tot_len-win_len*TTs+1
    % Time window of the input signal and real number of spikes in the window
    idx    = (i_0:i_0+win_len*TTs-1)';
    idx    = round(idx);
    t_x    = original_t(idx);
    x      = original_signal(idx);    
    if mode == 1
        % Exponentials recovery estimating K
        [tt_k, aa_k, K] = extract_decaying_exponentials(x, t_x, alpha, ...
                                                        phi, t_phi, ...
                                                        alpha_0, lambda, ...
                                                        T, c_m_n, n_vec);
    elseif mode == 2
        % Exponential recovery with oracle for K
        K_real = sum(sp >= t_x(1) & sp <= t_x(end));
        [tt_k, aa_k, K] = extract_decaying_exponentials(x, t_x, alpha, ...
                                                        phi, t_phi, ...
                                                        alpha_0, lambda, ...
                                                        T, c_m_n, n_vec, ...
                                                        K_real);
    elseif mode == 3
        % Exponential recovery with fixed K
        [tt_k, aa_k, K] = extract_decaying_exponentials(x, t_x, alpha, ...
                                                        phi, t_phi, ...
                                                        alpha_0, lambda, ...
                                                        T, c_m_n, n_vec, ...
                                                        K_fix);
    elseif mode == 4
        % Exponential recovery with partial oracle and fixed K
        K_real = sum(sp >= t_x(1) & sp <= t_x(end));
        if K_real == 0
            tt_k = [];
            aa_k = [];
            K    = 0;
        else
            [tt_k, aa_k, K] = extract_decaying_exponentials(x, t_x, alpha, ...
                                                        phi, t_phi, ...
                                                        alpha_0, lambda, ...
                                                        T, c_m_n, n_vec, ...
                                                        K_fix);
        end
    elseif mode == 5
        % Exponential recovery with partial oracle and estimated K
        K_real = sum(sp >= t_x(1) & sp <= t_x(end));
        if K_real == 0
            tt_k = [];
            aa_k = [];
            K    = 0;
        else
            [tt_k, aa_k, K] = extract_decaying_exponentials(x, t_x, alpha, ...
                                                        phi, t_phi, ...
                                                        alpha_0, lambda, ...
                                                        T, c_m_n, n_vec);
        end

    end
    % Store value of K
    K_i(ith_win) = K;
    t_k     = [t_k; tt_k]; %#ok<AGROW>
    a_k     = [a_k; aa_k]; %#ok<AGROW>
    win_idx = [win_idx; i_0*ones(K,1)]; %#ok<AGROW>
    ith_win = ith_win + 1;
end
end

%%
function [t_k, a_k, K] = extract_decaying_exponentials(x, t_x, alpha, ...
                                                       phi, t_phi, ...
                                                       alpha_0, lambda, ...
                                                       T, ...
                                                       c_m_n, n_vec, ...
                                                       K, reps_per_k)
% -------------------------------------------------------------------------
% Extract K decaying exponentials from the signal x(t) applying FRI
% methods (sampling with an exponential reproducting kernel phi(-t/T) at 
% instants t=nT). If the K parameter is not transmitted it will be 
% estimated from the exponential moments of x(t).
%
% Stream of decaying exponentials:
%         K-1
%  x(t) = sum a_k * exp(-alpha(t-t_k)) * u(t-t_k)
%         k=0
%
% Sampling process:
%  y_n = < x(t), phi(t/T-n)>
%  z_n = y_n - y_(n-1) * exp(-alpha*T)
%
% USAGE:
%  [t_k, a_k] = extract_decaying_exponentials(x, t_x, alpha, 
%                                             phi, t_phi, 
%                                             alpha0, lambda,
%                                             T, 
%                                             c_m_n, n_vec[,
%                                             K])
%
%
% INPUT:
%  - x       : Original input signal (stream of decaying exponentials).
%  - t_x     : x(t) signal's time stamps.
%  - alpha   : Exponential decay parameter.
%  - phi     : Exponential reproducing kernel (sampling kernel).
%  - t_phi   : Kernel's time stamps.
%  - T       : Sampling period.
%  - c_m_n   : Exponential reproducing coefficients.
%  - n_vec   : n indices for which the c_m_n coefficients have been
%              computed.
%  - K       : [Optional] Total number of decaying exponentials in x(t).
%
% OUTPUT:
%  - t_k     : Decaying exponentials' time locations.
%  - a_k     : Decaying exponentials' amplitudes.
%
% WARNING:
% x(t) and phi(t/T) must have the same temporal resolution, i.e.
% t(i+1) - t(i) = t_phi(i+1) - t_phi(i)
%
if nargin == 12 
    estimate_K = true; %#ok<*NASGU>
    sing_vals = K;
elseif nargin == 10
    estimate_K = true;
elseif nargin == 11
    estimate_K = false;
else
    error('Wrong number of arguments.')
end
% Temporal resolution
T_s = t_x(2) - t_x(1);
% Sampling indices (t = nT)
% n_vec = round(t(mod(t,T)==0)/T);
% Time stamps of the shifted signal x(t) (so x(t) is sampled according to 
% the exponential reproduction
t1   = n_vec(1) * T;
t2   = (n_vec(end)+1) * T - T_s;
t_xs = (t1:T_s:t2)';
L    = length(t_x);
% Compute y_n as y_n = <x(t),phi(t/T-n)>
y_n = zeros(length(n_vec), 1);
for it = 1:length(n_vec)
    idx_1         = round((t_phi(1) + n_vec(it) * T - t_xs(1)) / T_s) + 1;
    idx_2         = round((t_phi(end) + n_vec(it) * T - t_xs(1)) / T_s) + 1;
    idx           = (idx_1:idx_2)';
    idx           = mod(idx, L);
    idx(idx == 0) = L;

    y_n(it) = T_s * x(idx).' * phi;
end
z_n = y_n(2:end) - y_n(1:end-1) * exp(-alpha*T);

% Compute the moments of the signal
s_m = c_m_n(:,2:end) * z_n;
kk  = floor(length(s_m)/2) + 1;
% Estimate K parameter if not transmitted
if nargin == 10
    S   = toeplitz(s_m(kk:end), s_m(kk:-1:1));
    D   = svd(S);
    y_i = D / D(1);
    
    % Estimate K thresholding the eigenvalues
    K = sum(y_i > 0.3);
    
    % Estimate K from the max of the second derivative
%     K       = 0;
%     x_i     = (1:length(y_i))';
%     step    = 0.1;
%     x       = (1:step:9)';
%     y_pp    = spline(x_i, y_i, x); % cubic spline interpolation
%     d_y_pp  = diff(y_pp) / step;
%     d2_y_pp = diff(d_y_pp) / step;
%     [~, idx] = max(d2_y_pp);
%     K        = round(x(idx)) - 1;
    % K must be smaller than kk-1/2
    K = min([K kk-1]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% new test for estimating K
if nargin == 12
    S         = toeplitz(s_m(kk:end), s_m(kk:-1:1));
    [~, D, ~] = svd(S);
    y_i       = diag(D) / D(1,1);
    
    corr_sv = sing_vals * y_i;
%     max_k   = size(sing_vals,1)/reps_per_k;
%     k_est   = zeros(max_k, 1);
%     for k = 1 : max_k
%         k_est(k) = sum(corr_sv((k-1)*reps_per_k+1:k*reps_per_k));
%     end
%     [~, K] = max(k_est);
    [~, K] = max(corr_sv);
    K      = floor((K-1)/reps_per_k);
end
% end of new test for estimating K
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Locate the diracs using matrix pencil method
P   = length(n_vec) / 2;
u_k = acmp_p(s_m, K, round(P/2), P, 1);
t_k = real(T * log(u_k) / lambda);
% Find the amplitudes a_k
A = zeros(K, K);
for i = 0:K-1
    A(i+1,:) = u_k(1:K).^i;
end
B    = s_m(1:K);
B    = B(:);
ah_k = linsolve(A, B);
a_k  = ah_k .* exp(-alpha_0 * t_k / T);
% Round the time locations
% t_k = round(t_k / T_s) * T_s;
% Order chronologically and shift to "real" time stamps
[~, idx] = sort(t_k);
t_k = t_k(idx) + t_x(1) - t_xs(1);
a_k = a_k(idx);
end


%%
function uk = acmp_p(sm, K, M, P, p)
% -------------------------------------------------------------------------
% H = hankel(sm(1:L), sm(L:M+L-1));
% H = flipud(toeplitz(sm(M+1:1:P+1), sm(M+1:-1:1)));
H = fliplr(toeplitz(sm(M+1:1:P+1), sm(M+1:-1:1)));
% rho = max(abs(sm));
% phi1 = diag(rho.^(-[0:P-M]/2));
% phi2 = diag(rho.^(-[0:M]/2));
% H = phi1 * H * phi2;
[U,~,~] = svd(H,0);
U = U(:,1:K);
Z = pinv(U(1:end-p,:)) *U(p+1:end,:);
uk = (eig(Z)).^(1/p);
% uk = eig(Z);
end

%%
function [phi, t] = generate_e_spline(alpha_vec, T_s, T, mode)
% -------------------------------------------------------------------------
% Generate the exponential spline of order P+1 corresponding to a vector of
% alpha values and with a given temporal resolution. The resulting spline 
% is obtained in time domain computing the P convolutions of the P+1 zero 
% order E-splines:
%   phi_a_vec(t) = phi_a_0(t) * phi_a_1(t) * ... * phi_a_N(t)
%
% USAGE:
%  [phi, t] = generate_e_spline(alpha_vec, T_s[, T, mode])
%
% INPUT:
%  - alpha_vec : Vector of P+1 alpha values of the E=spline.
%  - T_s       : Time resolution of the spline.
%  - T         : Optional argument. Scale factor. Default T = 1.
%  - mode      : Optional argument. 'causal', 'symmetric' or 'anticausal'. 
%                Default mode = 'causal'.
%
% OUTPUT:
%  - phi       : Vector of size (P+1)/T + 1 with the values of the
%                E-spline.
%  - t         : Time stamps of the corresponding values of the phi vector.
%
if nargin < 2 || nargin > 4
    error('generate_e_spline:err_arg', 'The number of input arguments is incorrect.')
elseif nargin < 4
    mode = 'causal';
    if nargin < 3
        T = 1;
    end
end
N = length(alpha_vec) - 1;
% Convert alpha_vec into a row vector
alpha_vec = alpha_vec(:).';
% Apply scaling factor
T_s = T_s / T;
t_phi_1        = 0;
t_phi_2        = 1;
t_phi          = (t_phi_1:T_s:t_phi_2)';
sub_phi        = exp(t_phi * alpha_vec);
sub_phi(end,:) = 0;
phi   = [0; sub_phi(1:end-1,1)];
t_0   = t_phi(1);
t_end = t_phi(end);
for i = 1:N
    t_0   = t_0 + t_phi(1);
    t_end = t_end + t_phi(end);
    phi   = T_s * conv(phi, sub_phi(:,i+1));
end
t = (t_0:T_s:t_end)';
t = t * T;
if strcmp(mode, 'symmetric')
    t_mid      = (t(end) - t(1)) / 2;
    t          = t - t_mid;
    [~, i_max] = max(phi);
    if phi(i_max) ~= phi(t == 0)
        t = t - t(i_max);
    end
elseif strcmp(mode, 'anticausal')
    phi = phi(end:-1:1);
    t   = -t(end:-1:1);
end
end

%%
function c_m_n = get_c_m_n_exp(alpha_m, n, phi, t_phi, T, t_0)
% -------------------------------------------------------------------------
% Compute the c_m_n coefficients to reproduce exponentials with parameters
% given by the alpha_m vector using the exponential reproducing kernel phi:
%   exp(alpha_m*t) = sum_n ( c_m_n * phi(t-n) )
%
% USAGE:
%  c_m_n = get_c_m_n_exp(alpha_m, n, phi, t[, T, t_0])
%
% INPUT:
%  - alpha_m : Vector of size M with the parameters of the exponentials to 
%              be reproduced.
%  - n       : Vector of size N with the values where the summation will be
%              evaluated.
%  - phi     : Exponential reproducing kernel.
%  - t_phi   : Time stamps of the kernel.
%  - T       : Optional argument. Scale factor. Default T = 1.
%  - t_0     : Optional argument. t value where c_m_0 will be evaluated. Default t_0 = 0.
%
% OUTPUT:
%  - c_m_n   : Coefficients to reproduce the exponentials.
%
if nargin < 4 || nargin > 6
    error('get_c_m_n_exp:err_arg', 'The number of input arguments is incorrect.')
elseif nargin < 6
    t_0 = 0;
    if nargin < 5
        T = 1;
    end
end
% Rearrange the arguments (n row vector, alpha_m column vector)
n       = n(:).';
n_len   = length(n);
alpha_m = alpha_m(:);
T_s     = t_phi(2) - t_phi(1);
% Kernel's boundaries
t_1 = t_phi(1) / T;
t_2 = t_phi(end) / T;
% Compute c_m_0 vector
l     = ceil(t_0/T - t_2) : floor(t_0/T - t_1);
idx   = round( (t_0 - T * (t_1 + l)) / T_s) + 1;
phi_l = phi(idx);
num   = exp(alpha_m * t_0 / T);
den   = exp(alpha_m * l) * phi_l;
c_m_0 = num ./ den;
% Compute the remaining c_m_n from c_m_0
exp_mat = exp(alpha_m * n);
c_m_n   = exp_mat .* repmat(c_m_0, 1, n_len);
end

%%
function ap = retrieve_amplitudes(x, t, sp, delta_t, center)
% Temporal resolution
T_s = t(2) - t(1);
if nargin < 5
    center = 0.5;
    if nargin < 4
        delta_t = 7 * T_s;
    end
end
dt_before = delta_t * center;
dt_after  = delta_t * (1 - center);
num_spikes = length(sp);
ap         = zeros(size(sp));
for ith_sp = 1 : num_spikes
    sp_cur = sp(ith_sp);
    idx    = find(t >= sp_cur - dt_before & t <= sp_cur + dt_after);
    [ap_cur, locs] = findpeaks(x(idx));    
    if length(ap_cur) > 1
%         [min_dt, idx_min] = min(abs(t(locs + idx(1) - 1) - sp_cur));        
%         if t(locs(idx_min) + idx(1) - 1) > sp_cur
%             id = find( t(idx) == sp_cur + min_dt ) + idx(1) - 1;
%         else
%             id = find( t(idx) == sp_cur - min_dt ) + idx(1) - 1;
%         end         
%         ap(ith_sp) = x(id);
        ap(ith_sp) = max(ap_cur);        
%     elseif isempty(ap_cur)
%         warning(['No peaks found for the ' num2str(ith_sp) '-th spike'])
    elseif ~isempty(ap_cur)
        ap(ith_sp) = ap_cur;
    end
end
end