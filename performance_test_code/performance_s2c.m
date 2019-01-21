addpath('../Func/plotFuncs')
tempFitDir = '../tempDatOOPSI/';
plotDir = '../plotExampleNeuron/';
load('../KS_dat_fit/DataListCells.mat');

expression  = {'virus', 'virus', 'transgenic', 'transgenic'};
CaIndicator = {'GCaMP6f', 'GCaMP6s', 'GCaMP6f', 'GCaMP6s'};
group    = nan(length(totCell), 1);
for nGroup = 1:length(expression)    
    indexExpression = strcmp(expression{nGroup}, {totCell.expression});
    indexCaInd      = strcmp(CaIndicator{nGroup}, {totCell.CaIndicator});
    group(indexExpression & indexCaInd)     = nGroup;
end

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
    dff    = totCell(nCell).dff;
    t_frame = t_vec;
    normalized_dff     = normalized_dat(dff);
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
    
end

load('../KS_S2Cdat_fit/ParamsFitCells.mat');
s2cdffPerformance = zeros(length(totCell), 10);
temps2cFitDir = '../tempDatS2COOPSI/';
for nCell  = 1:length(totCell)
    load([temps2cFitDir 'Fast_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([temps2cFitDir 'FRI_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([temps2cFitDir 'MCMC_oopsi_fit_Cell_' num2str(nCell) '.mat'])
%     load([temps2cFitDir 'Peel_oopsi_fit_Cell_' num2str(nCell) '.mat'])
%     load([temps2cFitDir 'MLSpike_fit_Cell_' num2str(nCell) '.mat'])
    t_vec  = totCell(nCell).CaTime;
    dff    = totCell(nCell).dff;% paras(nCell).fitCaTraces;
    t_frame = t_vec;
    normalized_dff     = normalized_dat(dff);
    corr_dff = corr(normalized_dff, normalized_dat(wiener.F_est_nonneg)');
    s2cdffPerformance(nCell, 1) = corr_dff;
    
    corr_dff = corr(normalized_dff, normalized_dat(fast.F_est)');
    s2cdffPerformance(nCell, 2) = corr_dff;
    
    corr_dff = corr(normalized_dff, normalized_dat(fri.F_est));
    s2cdffPerformance(nCell, 3) = corr_dff;

    corr_dff = corr(normalized_dff, normalized_dat(cf1.c)');
    s2cdffPerformance(nCell, 4) = corr_dff;

    corr_dff = corr(normalized_dff, normalized_dat(cf2.c)');
    s2cdffPerformance(nCell, 5) = corr_dff;
    
    corr_dff = corr(normalized_dff, normalized_dat(cf3.c)');
    s2cdffPerformance(nCell, 6) = corr_dff;

    corr_dff = corr(normalized_dff, normalized_dat(cont.F_est)');
    s2cdffPerformance(nCell, 7) = corr_dff;

%     corr_dff = corr(normalized_dff, normalized_dat(peel.model)');
%     s2cdffPerformance(nCell, 8) = corr_dff;
% 
%     corr_dff = corr(normalized_dff, normalized_dat(peelNL.model)');
%     s2cdffPerformance(nCell, 9) = corr_dff;
%     
%     corr_dff = corr(normalized_dff, est.F_est);
%     s2cdffPerformance(nCell, 10) = corr_dff;
end


% for nGroup = 1:4
%     figure
%     boxplot([evMat(group==nGroup, :), dffPerformance(group==nGroup, :)]);
%     set(gca, 'TickDir', 'out')
%     set(gca, 'xTick', 1:13)
%     xlim([0.5 13.5])
%     ylim([-0.2 1.1])
%     setPrint(8, 6, ['performance_' expression{nGroup} '_' CaIndicator{nGroup}], 'pdf')
% end
rand_ = 1+rand(90, 1)*0.15;
figure
hold on
scatter(dffPerformance(:, 7), s2cdffPerformance(:, 7).*rand_, [], group)
plot([0 1], [0 1], '--k')
xlim([0 1])
ylim([0 1])
set(gca, 'TickDir', 'out')
xlabel('MCMC performance on raw data')
ylabel('MCMC performance on s2c data')
setPrint(8, 6, 'deconv_performance_on_s2c_data', 'pdf')

[p, h] = signrank(dffPerformance(:, 7), s2cdffPerformance(:, 7).*rand_)