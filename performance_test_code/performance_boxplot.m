addpath('../Func/plotFuncs')

load('removeList.mat')
load('../KS_dat_fit/DataListCells.mat');
load('../TempDat/ParamsFitCells_S2CModel_linear_nofix.mat')
linearParas  = paras;
linearParas(removeList)  = [];
load('../TempDat/ParamsFitCells_S2CModel_sigmoid_Fmfix.mat')
sigmoidParas = paras;
sigmoidParas(removeList) = [];
load('../TempDat/ParamsFitCells_S2CModel_Fmfix.mat')
hillParas    = paras;
hillParas(removeList)    = [];
spk        = zeros(length(totCell), 1);
evMat      = zeros(length(totCell), 3);
for nCell  = 1:length(totCell)
    dff    = totCell(nCell).dff;
    normalized_dff  = normalized_dat(dff);
    spk(nCell)      = length(totCell(nCell).spk)/240;
    evMat(nCell, 2) = corr(normalized_dff, normalized_dat(linearParas(nCell).fitCaTraces));
    evMat(nCell, 1) = corr(normalized_dff, normalized_dat(sigmoidParas(nCell).fitCaTraces));
    evMat(nCell, 3) = corr(normalized_dff, normalized_dat(hillParas(nCell).fitCaTraces));
end

clear paras

expression  = {'virus', 'virus', 'transgenic', 'transgenic'};
CaIndicator = {'GCaMP6f', 'GCaMP6s', 'GCaMP6f', 'GCaMP6s'};
group    = nan(length(totCell), 1);
for nGroup = 1:length(expression)    
    indexExpression = strcmp(expression{nGroup}, {totCell.expression});
    indexCaInd      = strcmp(CaIndicator{nGroup}, {totCell.CaIndicator});
    group(indexExpression & indexCaInd)     = nGroup;
end



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

for nGroup = 1:4
    figure
    boxplot([evMat(group==nGroup, :), dffPerformance(group==nGroup, :)]);
    set(gca, 'TickDir', 'out')
    set(gca, 'xTick', 1:13)
    xlim([0.5 13.5])
    ylim([-0.2 1.1])
    setPrint(8, 6, ['performance_' expression{nGroup} '_' CaIndicator{nGroup}], 'pdf')
end