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

for nCell  = 1:length(totCell)
    load([tempFitDir 'Fast_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'FRI_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'MCMC_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'Peel_oopsi_fit_Cell_' num2str(nCell) '.mat'])
    load([tempFitDir 'MLSpike_fit_Cell_' num2str(nCell) '.mat'])
    
    expression = totCell(nCell).expression;
    CaIndicator = totCell(nCell).CaIndicator;
    
    if strcmp(CaIndicator, 'GCaMP6f') && strcmp(expression, 'virus')
        fileFold = 'MV16fAAV';
    elseif strcmp(CaIndicator, 'GCaMP6s') && strcmp(expression, 'virus')
        fileFold = 'MV16sAAV';
    elseif strcmp(CaIndicator, 'GCaMP6f') && strcmp(expression, 'transgenic')
        fileFold = 'MV1GP517';
    elseif strcmp(CaIndicator, 'GCaMP6s') && strcmp(expression, 'transgenic')
        fileFold = 'MV1GP43';
    end
    
    if ~exist(fileFold, 'dir')
        mkdir(fileFold)
    end
    
    spkTime      = totCell(nCell).spk;
    spk          = ones(size(spkTime));
    spk_file     = [fileFold '/' totCell(nCell).cellName '_' num2str(totCell(nCell).nRep, '%03d') '_spk.csv'];
    writetable(table(spkTime, spk), spk_file);
    
    time         = totCell(nCell).CaTime;    
%     raw_dff      = normalized_dat(totCell(nCell).dff);
%     S2C_Linear   = normalized_dat(S2C_linear_Function(nCell).fitCaTraces);
%     S2C_Hill     = normalized_dat(S2C_Hill_Function(nCell).fitCaTraces);
%     S2C_Sigmoid  = normalized_dat(S2C_Sigmoid_Function(nCell).fitCaTraces);
%     C2S_Nonnegative_Wienner_Filter = normalized_dat(wiener.F_est_nonneg)';
%     C2S_Fast_OOPSI = normalized_dat(fast.F_est)';
%     C2S_Finite_Rate_Innovation = normalized_dat(fri.F_est);
%     C2S_Constrained_OOPSI_AR1 = normalized_dat(cf1.c)';
%     C2S_Constrained_OOPSI_AR2 = normalized_dat(cf2.c)';
%     C2S_Constrained_OOPSI_AR3 = normalized_dat(cf3.c)';
%     C2S_Constrained_OOPSI_MCMC = normalized_dat(cont.F_est)';
%     C2S_Peel_Linear = normalized_dat(peel.model)';
%     C2S_Peel_NonLinear = normalized_dat(peelNL.model)';
    raw_dff      = totCell(nCell).dff;
    raw_dff(raw_dff<-max(raw_dff)) = nan;
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
%     C2S_Peel_NonLinear = peelNL.model';
    C2S_MLSpike = est.F_est;
    
    calcium_file  = [fileFold '/' totCell(nCell).cellName '_' num2str(totCell(nCell).nRep, '%03d') '_dff.csv'];
    
%     calcium_table = table(time, raw_dff, S2C_Linear, S2C_Hill, S2C_Sigmoid, C2S_Nonnegative_Wienner_Filter, ...
%         C2S_Fast_OOPSI, C2S_Finite_Rate_Innovation, C2S_Constrained_OOPSI_AR1, C2S_Constrained_OOPSI_AR2, ...
%         C2S_Constrained_OOPSI_AR3, C2S_Constrained_OOPSI_MCMC, C2S_Peel_Linear, C2S_Peel_NonLinear, C2S_MLSpike);
    calcium_table = table(time, raw_dff, S2C_Linear, S2C_Hill, S2C_Sigmoid, C2S_Nonnegative_Wienner_Filter, ...
        C2S_Fast_OOPSI, C2S_Finite_Rate_Innovation, C2S_Constrained_OOPSI_AR1, C2S_Constrained_OOPSI_AR2, ...
        C2S_Constrained_OOPSI_AR3, C2S_Constrained_OOPSI_MCMC, C2S_Peel_Linear, C2S_MLSpike);
        
    writetable(calcium_table, calcium_file);
    
end