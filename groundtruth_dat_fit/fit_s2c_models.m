%
% Example neurons for neuronal trace from S2C model and C2S model
%
%
% This will later moved to Deconv Project


addpath('../Func');
addpath('../Func/S2CfitFuncs');
setDir;
load([TempDatDir 'DataListCells.mat'], 'totCell');
load([TempDatDir 'ParamsFitCells_S2CModel_nofix.mat'], 'paras');
parasOld = paras;
clear paras;
paras = repmat(struct('cellName',1, 'nRep', 1, 'expression', 'virus',...
                        'CaIndicator', 'GCaMP6f', 'FmNorm', nan, ...
                        'Fm',1, 'Ca0', 1, 'beta', 1, 'tau_r', 1, 'tau_d', 1),length(totCell), 1); 
                    
                    
                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% S2C model -- all fited
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
p_fit_index      = [false, false, false, true, true]; % Fm, Kd, n, tau_d, tau_r

                    
for nCell        = 1:length(totCell)  
    spk          = totCell(nCell).spk;
    dff          = totCell(nCell).dff;
    if isa(dff, 'single'); dff = double(dff); end
    t_frame      = totCell(nCell).CaTime;
    
    %%%%%%%% linear model
    para_start                   = [20   0    1    0.2107];
    para_final                   = gcamp6_linear_model(spk, dff, t_frame, para_start);
    fitCaTraces                  = func_getCaTraces_linear(spk, t_frame,para_final);
        
    paras(nCell).cellName      = totCell(nCell).cellName;
    paras(nCell).nRep          = totCell(nCell).nRep;
    paras(nCell).expression    = totCell(nCell).expression;
    paras(nCell).CaIndicator   = totCell(nCell).CaIndicator;
    paras(nCell).a             = para_final(1);
    paras(nCell).b             = para_final(2);
    paras(nCell).tau_d         = para_final(3);
    paras(nCell).tau_r         = para_final(4);
    paras(nCell).fitCaTraces   = fitCaTraces;
    paras(nCell).ev            = 1- sum((fitCaTraces-dff).^2)/length(dff)/var(dff);
    paras(nCell).var            = var(dff);
    disp([paras(nCell).ev paras(nCell).var max(dff)])
end

save([TempDatDir 'ParamsFitCells_S2CModel_linear_nofix.mat'], 'paras');

% for nCell        = 1:length(totCell)  
%     spk          = totCell(nCell).spk;
%     dff          = totCell(nCell).dff;
%     if isa(dff, 'single'); dff = double(dff); end
%     t_frame      = totCell(nCell).CaTime;
%     
%     %%%%%%%% linear model
%     para_start                   = [20  0  0  1  0.2107];
%     para_final                   = gcamp6_quadratic_model(spk, dff, t_frame, para_start);
%     CaTraces                     = func_getCaTraces_quadratic(spk,t_frame,para_final);
%         
%     paras(nCell).cellName      = totCell(nCell).cellName;
%     paras(nCell).nRep          = totCell(nCell).nRep;
%     paras(nCell).expression    = totCell(nCell).expression;
%     paras(nCell).CaIndicator   = totCell(nCell).CaIndicator;
%     paras(nCell).a             = para_final(1);
%     paras(nCell).b             = para_final(2);
%     paras(nCell).c             = para_final(3);
%     paras(nCell).tau_d         = para_final(4);
%     paras(nCell).tau_r         = para_final(5);
%     paras(nCell).fitCaTraces   = fitCaTraces;
%     paras(nCell).ev            = 1- sum((fitCaTraces-dff).^2)/length(dff)/var(dff);
%     paras(nCell).var            = var(dff);
%     disp([paras(nCell).ev paras(nCell).var max(dff)])
% end
% 
% save([TempDatDir 'ParamsFitCells_S2CModel_quadratic_nofix.mat'], 'paras');
                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% S2C model -- all fited
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
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
    % CaTraces                     = func_getCaTraces_linear({spk},para.t_frame,para_final);
    
    %%%%%%%% quadratic model
    % para_start                   = [20  0  0  1  0.2107];
    % para_final                   = gcamp6_quadratic_model({spk}, dff, para.t_frame, para_start);
    % CaTraces                     = func_getCaTraces_quadratic({spk},para.t_frame,para_final);
    
    % sigmoid model
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
%     disp([paras(nCell).ev paras(nCell).var max(dff)])
end

save([TempDatDir 'ParamsFitCells_S2CModel_sigmoid_nofix.mat'], 'paras');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% S2C model -- Fm fixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear paras;

% p_fit_index      = [true, false, false, true, true]; % Fm, Kd, n, tau_d, tau_r
load([TempDatDir 'ParamsFitCells_S2CModel_Fmfix.mat'], 'paras');
parasOld = paras;
clear paras;
paras = repmat(struct('cellName',1, 'nRep', 1, 'expression', 'virus',...
                        'CaIndicator', 'GCaMP6f', 'FmNorm', nan, ...
                        'Fm',1, 'Ca0', 1, 'beta', 1, 'tau_r', 1, 'tau_d', 1),length(totCell), 1); 

for nCell        = 1:length(totCell)
    spk          = totCell(nCell).spk;
    dff          = totCell(nCell).dff;
    max_dff      = max(dff);
    dff          = dff/max(dff);
    if isa(dff, 'single'); dff = double(dff); end
    para_start   = [10   20.4788    1.1856    parasOld(nCell).tau_d    parasOld(nCell).tau_r];
    t_frame      = totCell(nCell).CaTime;
        
    % sigmoid model
    para_final                 = gcamp6_model_sigmoid({spk}, dff, t_frame, para_start);
    fitCaTraces                = func_getCaTraces_sigmoid({spk}, t_frame,para_final);
    
    paras(nCell).cellName      = totCell(nCell).cellName;
    paras(nCell).nRep          = totCell(nCell).nRep;
    paras(nCell).expression    = totCell(nCell).expression;
    paras(nCell).CaIndicator   = totCell(nCell).CaIndicator;
    paras(nCell).FmNorm        = para_final(1);
    paras(nCell).Fm            = para_final(1) * max_dff;
    paras(nCell).Ca0           = para_final(2);
    paras(nCell).beta          = para_final(3);
    paras(nCell).tau_d         = para_final(4);
    paras(nCell).tau_r         = para_final(5);
    paras(nCell).fitCaTraces   = fitCaTraces * max_dff;
    paras(nCell).ev            = 1- sum((fitCaTraces-dff).^2)/length(dff)/var(dff);
    paras(nCell).var           = var(dff);
    paras(nCell).rs            = corr(fitCaTraces, dff, 'type', 'Spearman');
            
end

save([TempDatDir 'ParamsFitCells_S2CModel_sigmoid_Fmfix.mat'], 'paras');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% C2S model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% paras = repmat(struct('cellName',1, 'nRep', 1, 'expression', 'virus',...
%                         'CaIndicator', 'GCaMP6f', 'n_fast', 1, 'n_smc', 1, length(totCell), 1); 
% 
% for nCell   = 1:length(totCell)  
%     tic
%     
%     spk          = totCell(nCell).spk;
%     dff          = totCell(nCell).dff;
%     if isa(dff, 'single'); dff = double(dff); end
%     t_frame      = totCell(nCell).CaTime;
%         
%     V.fast_iter_max    = 1000;
%     V.smc_iter_max     = 1000;
%     V.dt               = t_frame(end)/length(t_frame);
%     V.preprocess       = 1; % high-pass filter (increase fitting speed)
%     V.T                = length(t_frame);
%     [fast, smc]        = runOOPSI(dff', V);
%     n_fast             = fast.n/max(fast.n);
%     paras(nCell).n_fast = n_fast;
%     if ~isempty(smc)
%         n_smc  = smc.E.nbar;
%     else
%         n_smc  = n_fast;
%     end
%     n_smc  = n_smc/max(n_smc);
%     paras(nCell).n_smc  = n_smc;
% 
%             
% end
% 
% save([TempDatDir 'ParamsFitCells_C2SModel.mat'], 'paras');