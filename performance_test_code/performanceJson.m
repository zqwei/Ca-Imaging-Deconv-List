tempFitDir = '../tempDatOOPSI/';
load('../KS_dat_fit/DataListCells.mat');
load('../TempDat/ParamsFitCells_S2CModel_Fmfix.mat', 'paras');
S2C_Hill_Function = paras;
load('../TempDat/ParamsFitCells_S2CModel_sigmoid_Fmfix.mat', 'paras');
S2C_Sigmoid_Function = paras;
load('../TempDat/ParamsFitCells_S2CModel_linear_nofix.mat', 'paras');
S2C_linear_Function = paras;
load('removeList.mat');
saveId = true(size(paras));
saveId(removeList) = false;
S2C_Hill_Function = S2C_Hill_Function(saveId);
S2C_Sigmoid_Function = S2C_Sigmoid_Function(saveId);
S2C_linear_Function = S2C_linear_Function(saveId);

names = {'S2C Linear', 'S2C Hill', 'S2C Sigmoid', 'C2S Nonnegative Wienner Filter', 'C2S FOOPSI', 'C2S Finite Rate Innovation', 'C2S Constrained OOPSI AR1', 'C2S Constrained OOPSI AR2', 'C2S Constrained OOPSI AR3', 'C2S Constrained OOPSI MCMC', 'C2S Peel Linear', 'C2S MLSpike'}';
alias = {'S2C Linear', 'S2C Hill', 'S2C Sigmoid', 'NWF', 'FOOPSI', 'FRI', 'AR1', 'AR2', 'AR3', 'MCMC', 'Peel', 'MLS'}';
group = zeros(length(totCell), 1);
cellPerformance = zeros(length(totCell), length(names));
cellRank  = zeros(length(totCell), length(names));

for nCell  = 1:length(totCell)
    load([tempFitDir 'Fast_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'FRI_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'MCMC_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'Peel_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'MLSpike_fit_Cell_' num2str(nCell) '.mat'])
    
    expression = totCell(nCell).expression;
    CaIndicator = totCell(nCell).CaIndicator;
    
    if strcmp(CaIndicator, 'GCaMP6f') && strcmp(expression, 'virus')
        group(nCell) = 1;
    elseif strcmp(CaIndicator, 'GCaMP6s') && strcmp(expression, 'virus')
        group(nCell) = 2;
    elseif strcmp(CaIndicator, 'GCaMP6f') && strcmp(expression, 'transgenic')
        group(nCell) = 4;
    elseif strcmp(CaIndicator, 'GCaMP6s') && strcmp(expression, 'transgenic')
        group(nCell) = 3;
    end
    
    raw_dff      = totCell(nCell).dff;
    S2C_Linear   = S2C_linear_Function(nCell).fitCaTraces;
    S2C_Hill     = S2C_Hill_Function(nCell).fitCaTraces;
    S2C_Sigmoid  = S2C_Sigmoid_Function(nCell).fitCaTraces;
    C2S_Nonnegative_Wienner_Filter = wiener.F_est_nonneg';
    C2S_Fast_OOPSI = fast.F_est';
    C2S_Finite_Rate_Innovation = fri.F_est;
    C2S_Constrained_OOPSI_AR1 = cf1.c';
    C2S_Constrained_OOPSI_AR2 = cf2.c';
    C2S_Constrained_OOPSI_AR3 = cf3.c';
    C2S_Constrained_OOPSI_MCMC = cont.F_est';
    C2S_Peel_Linear = peel.model';
    C2S_MLSpike = est.F_est;
    
    dff_fit = [ S2C_Linear, S2C_Hill, S2C_Sigmoid, C2S_Nonnegative_Wienner_Filter, ...
        C2S_Fast_OOPSI, C2S_Finite_Rate_Innovation, C2S_Constrained_OOPSI_AR1, C2S_Constrained_OOPSI_AR2, ...
        C2S_Constrained_OOPSI_AR3, C2S_Constrained_OOPSI_MCMC, C2S_Peel_Linear, C2S_MLSpike];
    dff_fit = double(dff_fit);
    raw_dff = double(raw_dff);
        
    cellPerformance(nCell, :) = 1 - sum(bsxfun(@minus, dff_fit, raw_dff).^2)/length(raw_dff)/var(raw_dff);
    cellRank(nCell, :) = corr(dff_fit, raw_dff);
end

allcolor = ['#ffffff'; '#fff5eb';'#fee6ce';'#fdd0a2';'#fdae6b';'#fd8d3c';'#f16913';'#d94801';'#a63603';'#7f2704'];
singlecolor = ['#ffffff'; '#f7fcf5';'#e5f5e0';'#c7e9c0';'#a1d99b';'#74c476';'#41ab5d';'#238b45';'#006d2c';'#00441b'];

allPerformance = floor(mean(cellPerformance)'*100)/100;
allPerformanceColor = allcolor(max(ceil(allPerformance*10), 1), :);
allRank = floor(mean(cellRank)'*100)/100;
allRankColor = allcolor(max(ceil(allRank*10), 1), :);
Performance = floor(grpstats(cellPerformance, group, @mean)'*100)/100;
Rank = floor(grpstats(cellRank, group, @mean)'*100)/100;

fileID = fopen('performance.json','w');
fprintf(fileID, '[\n');
for nModel = 1:length(names)
    fprintf(fileID, '{\n');
    fprintf(fileID, '"name" : "%s",\n "alias": "%s",\n', names{nModel}, alias{nModel});
    fprintf(fileID, '"performance" : "%s",\n "rank": "%s",\n', num2str(allPerformance(nModel), '%.2f'), num2str(allRank(nModel), '%.2f'));
    fprintf(fileID, '"pcolor" : "%s",\n "rcolor": "%s",\n', allPerformanceColor(nModel, :), allRankColor(nModel, :));
    fprintf(fileID, '"other" : [\n');
    for nData = 1:4
        fprintf(fileID, '{\n');
        fprintf(fileID, '"performance" : "%s",\n "rank": "%s",\n', num2str(Performance(nModel, nData), '%.2f'), num2str(Rank(nModel, nData), '%.2f'));
        pcolor = singlecolor(max(ceil(Performance(nModel, nData)*10), 1), :);
        rcolor = singlecolor(max(ceil(Rank(nModel, nData)*10), 1), :);
        fprintf(fileID, '"pcolor" : "%s",\n "rcolor": "%s",\n', pcolor, rcolor);
        fprintf(fileID, '\n},');
    end
    fprintf(fileID, '\b\n]\n},');
end
fprintf(fileID, '\b\n]');
fclose(fileID);
