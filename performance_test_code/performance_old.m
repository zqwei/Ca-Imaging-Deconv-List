% I incorporte some performance test from FRI code
% Only take into account the peak of the histograms
sspp       = [];
threshold  = 0.45 * max_detect;
for ith_t = 1 : hist_len
    if hist_sp(ith_t) > threshold
        if ( ith_t < hist_len && (hist_sp(ith_t) >= hist_sp(ith_t+1)) ) ...
        && ( ith_t > 1       && (hist_sp(ith_t) >  hist_sp(ith_t-1)) )
            t_i  = hist_t(ith_t);
            inds = find(t_k > (t_i - delta_t/2) & t_k < (t_i + delta_t/2));
            sspp = [sspp; mean(t_k(inds))];
        end
    end
end

% Retrieve the amplitudes of the spikes
ap   = retrieve_amplitudes(noisy_signal, t, sp, 7*T_s, .5);
aapp = retrieve_amplitudes(noisy_signal, t, sspp, 7*T_s, .5);

% Remove spikes with an amplitude smaller than a threshold
max_amp = max(noisy_signal);
sspp(aapp < 0.3 * max_amp) = [];
aapp(aapp < 0.3 * max_amp) = [];

% Compare the detected spikes with the real spikes
num_sp   = length(sp);
hit_sp   = false(num_sp, 1);
sspp_ids = [];
sspp_cpy = sspp;
delta_t  = 2*T_s;
for ith_sp = 1 : num_sp
    t_i  = sp(ith_sp);
    inds = find(sspp_cpy > (t_i - delta_t/2) & sspp_cpy < (t_i + delta_t/2));
    
    if ~isempty(inds)
        hit_sp(ith_sp) = true;
        sspp_ids       = [sspp_ids; find(sspp == sspp_cpy(inds(1)))];
        
        % Remove this spike from detected spikes
        sspp_cpy(inds(1)) = [];
        
        if length(inds) > 1
            warning('More than one spike detected in the neighbourhood of a real spike');
        end
    end
end

% Accuracy of detected spikes
hit_rate  = sum(hit_sp) / length(hit_sp) * 100;
false_pos = length(sspp_cpy);
mse       = mean( (sp(hit_sp) - sspp(sspp_ids)).^2 );
disp('')
disp('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
disp(['++++ SLIDING WINDOW Ca transient detection algorithm double consistency'])
disp(['++++ win_len1 = ' num2str(win_len1) ', win_len2 = ' num2str(win_len2)])
disp(['Total number of real spikes     : ' num2str(num_sp)])
disp(['Total number of detected spikes : ' num2str(length(sspp))])
disp(['Real spikes detected            : ' num2str(sum(hit_sp))])
disp(['MSE of spike locations          : ' num2str(mse)])
disp(['RMSE of spike locations         : ' num2str(sqrt(mse))])
disp(['Spike detection rate            : ' num2str(hit_rate) '%'])
disp(['False positives                 : ' num2str(false_pos)])
disp(['False positives rate            : ' num2str(false_pos/len) ' Hz'])
disp(' ')
