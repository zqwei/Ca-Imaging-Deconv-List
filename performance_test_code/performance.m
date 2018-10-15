tempFitDir = '../tempDatOOPSI/';
plotDir = '../plotExampleNeuron/';
load('../KS_dat_fit/DataListCells.mat');
xlimMin = 0;
xlimMax = 50;

dffPerformance = zeros(length(totCell), 10);
spkPerformance = zeros(length(totCell), 10);

for nCell  = 1:length(totCell)
    load([tempFitDir 'Fast_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'FRI_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'MCMC_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'Peel_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'MLSpike_fit_Cell_' num2str(nCell) '.mat'])
    t_vec  = totCell(nCell).CaTime;
    spk    = totCell(nCell).spk;
    dff    = totCell(nCell).dff;
    t_frame = t_vec;
    normalized_dff     = normalized_dat(dff);
    n_spk              = hist(spk, t_frame);
    n_spk              = n_spk/max(n_spk);
    corr_dff = corr(normalized_dff, normalized_dat(wiener.F_est_nonneg)');
    dffPerformance(nCell, 1) = corr_dff;
    
    corr_dff = corr(normalized_dff, normalized_dat(fast.F_est)');
    dffPerformance(nCell, 2) = corr_dff;
    
    corr_dff = corr(normalized_dff, normalized_dat(fri.F_est));
    dffPerformance(nCell, 3) = corr_dff;

    corr_dff = corr(normalized_dff, normalized_dat(cf1.c)');
    dffPerformance(nCell, 4) = corr_dff;

    corr_dff = corr(normalized_dff, normalized_dat(cf2.c)');
    dffPerformance(nCell, 5) = corr_dff;
    
    corr_dff = corr(normalized_dff, normalized_dat(cf3.c)');
    dffPerformance(nCell, 6) = corr_dff;

    corr_dff = corr(normalized_dff, normalized_dat(cont.F_est)');
    dffPerformance(nCell, 7) = corr_dff;

    corr_dff = corr(normalized_dff, normalized_dat(peel.model)');
    dffPerformance(nCell, 8) = corr_dff;

    corr_dff = corr(normalized_dff, normalized_dat(peelNL.model)');
    dffPerformance(nCell, 9) = corr_dff;
    
    corr_dff = corr(normalized_dff, est.F_est);
    dffPerformance(nCell, 10) = corr_dff;

    corr_dff = corr(n_spk', wiener.d'/max(wiener.d),'type','Spearman');
    spkPerformance(nCell, 1) = corr_dff;

    corr_dff = corr(n_spk', fast.d'/max(fast.d),'type','Spearman');
    spkPerformance(nCell, 2) = corr_dff;

    fri_spk   = hist(fri.spk, t_frame);
    if max(fri_spk) > 0
        fri_spk   = fri_spk/max(fri_spk);
    else
        fri_spk   = fri_spk';
    end
    corr_dff = corr(n_spk', fri_spk','type','Spearman');
    spkPerformance(nCell, 3) = corr_dff;
    
    corr_dff = corr(n_spk', cf1.spikes'/max(cf1.spikes),'type','Spearman');
    spkPerformance(nCell, 4) = corr_dff;

    corr_dff = corr(n_spk', cf2.spikes'/max(cf2.spikes),'type','Spearman');
    spkPerformance(nCell, 5) = corr_dff;
    
    corr_dff = corr(n_spk', cf3.spikes'/max(cf3.spikes),'type','Spearman');
    spkPerformance(nCell, 6) = corr_dff;

    corr_dff = corr(n_spk', cont.spk'/max(cont.spk),'type','Spearman');
    spkPerformance(nCell, 7) = corr_dff;

    corr_dff = corr(n_spk', peel.spiketrain'/max(peel.spiketrain),'type','Spearman');
    spkPerformance(nCell, 8) = corr_dff;

    corr_dff = corr(n_spk', peelNL.spiketrain'/max(peelNL.spiketrain),'type','Spearman');
    spkPerformance(nCell, 9) = corr_dff;
    
    if ~isempty(est.spk)
        ml_n_spk = hist(est.spk, t_frame);
        corr_dff = corr(n_spk', ml_n_spk','type','Spearman');
    else
        corr_dff = nan;
    end
    spkPerformance(nCell, 10) = corr_dff;
end







expression  = {'virus', 'virus', 'transgenic', 'transgenic'};
CaIndicator = {'GCaMP6f', 'GCaMP6s', 'GCaMP6f', 'GCaMP6s'};
group    = nan(length(totCell), 1);
for nGroup = 1:length(expression)    
    indexExpression = strcmp(expression{nGroup}, {totCell.expression});
    indexCaInd      = strcmp(CaIndicator{nGroup}, {totCell.CaIndicator});
    group(indexExpression & indexCaInd)     = nGroup;
end

groups = group * ones(1, 10);
figure;
scatter(spkPerformance(:), dffPerformance(:),[],groups(:),'filled')
xlabel('spk. corr.')
ylabel('dff corr.')
xlim([0 0.4])
ylim([0 1])
% setPrint(8, 6, 'xcorr_performance')
% setPrint(8, 6, 'xcorr_performance','png')

groupColor = [         0    0.4470    0.7410
    0.9290    0.6940    0.1250
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840];

nTitles = {'wiener', 'fast', 'fri', 'cvx(1)', 'cvx(2)', 'cvx(3)', 'mcmc', 'peel', 'peel(NL)'};
figure;
[~, ax, ~] = gplotmatrix(dffPerformance, [], group, groupColor, 'oooo', [], 'off', [], nTitles, nTitles);
for nAx   = 1:length(nTitles)
    for mAx = 1:length(nTitles)
        if nAx ~= mAx
            axes(ax(mAx, nAx)); %#ok<LAXES>
            hold on;
            plot ([0 1], [0 1], '--k','linewid', 1.0);
            hold off;
            xlim(ax(mAx, nAx), [0 1]);
            ylim(ax(mAx, nAx), [0 1]);
        end            
    end
end
% setPrint(8*5, 6*5, 'dff_performance')
% setPrint(8*5, 6*5, 'dff_performance','png')

figure;
[~, ax, ~] = gplotmatrix(spkPerformance, [], group, groupColor, 'oooo', [], 'off', [], nTitles, nTitles);
for nAx   = 1:length(nTitles)
    for mAx = 1:length(nTitles)
        if nAx ~= mAx
            axes(ax(mAx, nAx)); %#ok<LAXES>
            hold on;
            plot ([0 1], [0 1], '--k','linewid', 1.0);
            hold off;
            xlim(ax(mAx, nAx), [0 1]);
            ylim(ax(mAx, nAx), [0 1]);
        end            
    end
end
% setPrint(8*5, 6*5, 'spk_performance')
% setPrint(8*5, 6*5, 'spk_performance','png')

load('../KS_dat_fit/ParamsFitCells_S2CModel_Fmfix.mat', 'paras');
numSpk = arrayfun(@(x) length(x.spk)/x.CaTime(end), totCell, 'uniformoutput', false);
numSpk = cell2mat(numSpk);
parasFmFix = paras;
ev_snr = [parasFmFix.ev];
figure;
scatter(spkPerformance(:, 7), dffPerformance(:, 7), [], ev_snr, 'filled')
colorbar
xlabel('spk. corr.')
ylabel('dff corr.')
xlim([0 0.4])
ylim([0.4 1])
title('EV from S2C model')
setPrint(8, 6, 'ev_snr_performance')
setPrint(8, 6, 'ev_snr_performance','png')

figure;
scatter(spkPerformance(:, 7), dffPerformance(:, 7), [], numSpk, 'filled')
colorbar
xlabel('spk. corr.')
ylabel('dff corr.')
xlim([0 0.4])
ylim([0.4 1])
title('Spiking rate')
setPrint(8, 6, 'fr_performance')
setPrint(8, 6, 'fr_performance','png')


load('../KS_dat_fit/ParamsFitCells_S2CModel_Fmfix.mat', 'paras');
varDFF = arrayfun(@(x) std(x.dff), totCell, 'uniformoutput', false);
varStdDFF = arrayfun(@(x) std(x.dff)/(max(x.dff)-min(x.dff)), totCell, 'uniformoutput', false);
varDFF = cell2mat(varDFF);
varStdDFF = cell2mat(varStdDFF);
figure;
scatter(spkPerformance(:, 7), dffPerformance(:, 7), [], log(varDFF), 'filled')
colorbar
xlabel('spk. corr.')
ylabel('dff corr.')
caxis([-2 1])
xlim([0 0.4])
ylim([0.4 1])
title('log of std. dff')
setPrint(8, 6, 'vardff_performance')
setPrint(8, 6, 'vardff_performance','png')

figure;
scatter(spkPerformance(:, 7), dffPerformance(:, 7), [], log(varStdDFF), 'filled')
colorbar
xlabel('spk. corr.')
ylabel('dff corr.')
xlim([0 0.4])
ylim([0.4 1])
title('log of std. norm. dff')
caxis([-3 -1.5])
setPrint(8, 6, 'varstddff_performance')
setPrint(8, 6, 'varstddff_performance','png')
