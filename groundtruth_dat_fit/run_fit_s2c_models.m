%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This code can fit one of the following model
% 1. Linear model
% 2. Quadratic model
% 3. Hill function model
% 4. Sigmoid model
%
% Uncommenting the model as you need before fitting
%
% author: Ziqiang Wei
% email: weiz@janelia.hhmi.org
%
% 07/26/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


addpath('../Func');
addpath('../Func/S2CfitFuncs');
setDir;
load('DataListCells.mat', 'totCell');
% load([TempDatDir 'ParamsFitCells_S2CModel_nofix.mat'], 'paras');
% parasOld = paras;
% clear paras;
paras = repmat(struct('cellName',1, 'nRep', 1, 'expression', 'virus',...
                        'CaIndicator', 'GCaMP6f', 'FmNorm', nan, ...
                        'Fm',1, 'Ca0', 1, 'beta', 1, 'tau_r', 1, 'tau_d', 1),length(totCell), 1); 
                    
p_fit_index      = [false, false, false, true, true]; % Fm, Kd, n, tau_d, tau_r
for nCell        = 1:length(totCell)  
    spk          = totCell(nCell).spk;
    dff          = totCell(nCell).dff;
    if isa(dff, 'single'); dff = double(dff); end
    para_start   = [20   20.4788    1.1856    parasOld(nCell).tau_d    parasOld(nCell).tau_r];
    t_frame      = totCell(nCell).CaTime;
    
    %%%%%%%% linear model
    % para_start                   = [20   0    1    0.2107];
    % para_final                   = gcamp6_linear_model({spk}, dff, para.t_frame, para_start);
    % fitCaTraces                     = func_getCaTraces_linear({spk},para.t_frame,para_final);
    
    %%%%%%%% quadratic model
    % para_start                   = [20  0  0  1  0.2107];
    % para_final                   = gcamp6_quadratic_model({spk}, dff, para.t_frame, para_start);
    % fitCaTraces                     = func_getCaTraces_quadratic({spk},para.t_frame,para_final);
    
    %%%%%%%% Hill model
    % para_start   = [20   20.4788    1.1856    1    0.2107];
    % para_final                 = gcamp6_model_4para_new({spk}, dff, t_frame, para_start, p_fit_index);
    % fitCaTraces                = func_getCaTraces_general_new({spk}, t_frame,para_final);
    
    %%%%%%%% sigmoid model
    para_final                 = gcamp6_model_sigmoid({spk}, dff, t_frame, para_start, p_fit_index);
    fitCaTraces                = func_getCaTraces_sigmoid({spk}, t_frame,para_final);
    
    paras(nCell).cellName      = totCell(nCell).cellName;
    paras(nCell).nRep          = totCell(nCell).nRep;
    paras(nCell).expression    = totCell(nCell).expression;
    paras(nCell).CaIndicator   = totCell(nCell).CaIndicator;
    paras(nCell).Fm            = para_final(1);
    paras(nCell).Ca0           = para_final(2);
    paras(nCell).beta          = para_final(3);
    paras(nCell).tau_d         = para_final(4);
    paras(nCell).tau_r         = para_final(5);
    paras(nCell).fitCaTraces   = fitCaTraces;
    paras(nCell).ev            = 1- sum((fitCaTraces-dff).^2)/length(dff)/var(dff);
    paras(nCell).var            = var(dff);
    disp([paras(nCell).ev paras(nCell).var max(dff)])
end

save([TempDatDir 'ParamsFitCells_S2CModel_sigmoid_nofix.mat'], 'paras');