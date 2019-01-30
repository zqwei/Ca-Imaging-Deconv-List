tempFitDir = '../tempDat/';
plotDir = '../plotExampleNeuron/';
load('../KS_dat_fit/DataListCells.mat');
xlimMin = 0;
xlimMax = 50;

for nCell  = 1:length(totCell)
    load([tempFitDir 'Fast_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'FRI_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'MCMC_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'Peel_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    
    t_vec  = totCell(nCell).CaTime;
    spk    = totCell(nCell).spk;
    dff    = totCell(nCell).dff;
    t_frame = t_vec;
    normalized_dff     = normalized_dat(dff);
    n_spk              = hist(spk, t_frame);
    n_spk              = n_spk/max(n_spk);

    figure;
    subplot(3, 3, 1)
    hold on
    plot(t_vec, normalized_dff, '-k', 'linewid', 1);
    plot(t_vec, normalized_dat(wiener.F_est_nonneg), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, normalized_dat(wiener.F_est_nonneg)');
    title({'wiener'; ['corr. ' num2str(corr_dff, '%.2f')]})

    subplot(3, 3, 2)
    hold on
    plot(t_vec, normalized_dff, '-k', 'linewid', 1);
    plot(t_vec, normalized_dat(fast.F_est), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, normalized_dat(fast.F_est)');
    title({'fast'; ['corr. ' num2str(corr_dff, '%.2f')]})
    

    subplot(3, 3, 3)
    hold on
    plot(t_vec, normalized_dff, '-k', 'linewid', 1);
    plot(t_vec, normalized_dat(fri.F_est), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, normalized_dat(fri.F_est));
    title({'fri'; ['corr. ' num2str(corr_dff, '%.2f')]})
    
    subplot(3, 3, 4)
    hold on
    plot(t_vec, normalized_dff, '-k', 'linewid', 1);
    plot(t_vec, normalized_dat(cf1.c), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, normalized_dat(cf1.c)');
    title({'cvx (ar1)'; ['corr. ' num2str(corr_dff, '%.2f')]})

    subplot(3, 3, 5)
    hold on
    plot(t_vec, normalized_dff, '-k', 'linewid', 1);
    plot(t_vec, normalized_dat(cf2.c), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, normalized_dat(cf2.c)');
    title({'cvx (ar2)'; ['corr. ' num2str(corr_dff, '%.2f')]})
    
    subplot(3, 3, 6)
    hold on
    plot(t_vec, normalized_dff, '-k', 'linewid', 1);
    plot(t_vec, normalized_dat(cf3.c), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, normalized_dat(cf3.c)');
    title({'cvx (ar3)'; ['corr. ' num2str(corr_dff, '%.2f')]})

    subplot(3, 3, 7)
    hold on
    plot(t_vec, normalized_dff, '-k', 'linewid', 1);
    plot(t_vec, normalized_dat(cont.F_est), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, normalized_dat(cont.F_est)');
    title({'mcmc'; ['corr. ' num2str(corr_dff, '%.2f')]})


    subplot(3, 3, 8)
    hold on
    plot(t_vec, normalized_dff, '-k', 'linewid', 1);
    plot(t_vec, normalized_dat(peel.model), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, normalized_dat(peel.model)');
    title({'peel linear'; ['corr. ' num2str(corr_dff, '%.2f')]})

    subplot(3, 3, 9)
    hold on
    plot(t_vec, normalized_dff, '-k', 'linewid', 1);
    plot(t_vec, normalized_dat(peelNL.model), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, normalized_dat(peelNL.model)');
    title({'peel nonlinear'; ['corr. ' num2str(corr_dff, '%.2f')]})
    
    setPrint(8*3, 6*3, [plotDir 'DFFTrace_' num2str(nCell)])
    setPrint(8*3, 6*3, [plotDir 'DFFTrace_' num2str(nCell)], 'png')

    
    
    
    
    
    
    figure;
    subplot(3, 3, 1)
    hold on
    bar(t_vec, n_spk);
    plot(t_vec, wiener.d/max(wiener.d),'-r','linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(n_spk', wiener.d'/max(wiener.d),'type','Spearman');
    title({'wiener'; ['corr. ' num2str(corr_dff, '%.2f')]})

    subplot(3, 3, 2)
    hold on
    bar(t_vec, n_spk);
    plot(t_vec, fast.d/max(fast.d), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(n_spk', fast.d'/max(fast.d),'type','Spearman');
    title({'fast'; ['corr. ' num2str(corr_dff, '%.2f')]})
    

    subplot(3, 3, 3)
    hold on
    bar(t_vec, n_spk);
    fri_spk   = hist(fri.spk, t_frame);
    if max(fri_spk) > 0
        fri_spk   = fri_spk/max(fri_spk);
    else
        fri_spk   = fri_spk';
    end
    plot(t_vec, fri_spk, '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(n_spk', fri_spk','type','Spearman');
    if isnan(corr_dff); corr_dff=0; end
    title({'fri'; ['corr. ' num2str(corr_dff, '%.2f')]})
    
    subplot(3, 3, 4)
    hold on
    bar(t_vec, n_spk);
    plot(t_vec, cf1.spikes/max(cf1.spikes), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(n_spk', cf1.spikes'/max(cf1.spikes),'type','Spearman');
    title({'cvx (ar1)'; ['corr. ' num2str(corr_dff, '%.2f')]})

    subplot(3, 3, 5)
    hold on
    bar(t_vec, n_spk);
    plot(t_vec, cf2.spikes/max(cf2.spikes), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(n_spk', cf2.spikes'/max(cf2.spikes),'type','Spearman');
    title({'cvx (ar2)'; ['corr. ' num2str(corr_dff, '%.2f')]})
    
    subplot(3, 3, 6)
    hold on
    bar(t_vec, n_spk);
    plot(t_vec, cf3.spikes/max(cf3.spikes), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(n_spk', cf3.spikes'/max(cf3.spikes),'type','Spearman');
    title({'cvx (ar3)'; ['corr. ' num2str(corr_dff, '%.2f')]})

    subplot(3, 3, 7)
    hold on
    bar(t_vec, n_spk);
    plot(t_vec, cont.spk/max(cont.spk), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(n_spk', cont.spk'/max(cont.spk),'type','Spearman');
    title({'mcmc'; ['corr. ' num2str(corr_dff, '%.2f')]})


    subplot(3, 3, 8)
    hold on
    bar(t_vec, n_spk);
    plot(t_vec, peel.spiketrain/max(peel.spiketrain), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, peel.spiketrain'/max(peel.spiketrain),'type','Spearman');
    title({'peel linear'; ['corr. ' num2str(corr_dff, '%.2f')]})

    subplot(3, 3, 9)
    hold on
    bar(t_vec, n_spk);
    plot(t_vec, peelNL.spiketrain/max(peelNL.spiketrain), '-r', 'linewid', 1)
    box off
    xlim([xlimMin xlimMax])
    ylim([0 1])
    corr_dff = corr(normalized_dff, peelNL.spiketrain'/max(peelNL.spiketrain),'type','Spearman');
    title({'peel nonlinear'; ['corr. ' num2str(corr_dff, '%.2f')]})
    
    setPrint(8*3, 6*3, [plotDir 'SpkiTrace_' num2str(nCell)])
    setPrint(8*3, 6*3, [plotDir 'SpkTrace_' num2str(nCell)], 'png')
    
    close all
end