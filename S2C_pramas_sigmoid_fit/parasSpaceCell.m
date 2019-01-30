%
% parameter space for neuronal trace from S2C
%
%

addpath('../Func');
setDir;
load([TempDatDir 'ParamsFitCells_S2CModel_sigmoid_Fmfix.mat'], 'paras');

if ~exist([PlotDir 'ModelCellFits'],'dir')
    mkdir([PlotDir 'ModelCellFits'])
end

nKeys    = {'Fm', 'Ca0', 'beta', 'tau_d', 'tau_r',  'ev'};


paraMat  = nan(length(paras), length(nKeys));

for nKey = 1:length(nKeys)
    paraMat(:, nKey) = [paras.(nKeys{nKey})];
end

paraMat(paraMat(:,5)>0.2, 5) = nan;
paraMat(paraMat(:,1)<0 | paraMat(:,1)>500, 1) = nan;
paraMat(paraMat(:,6)<0.6, 2) = nan;
paraMat(paraMat(:,6)<0.6, 3) = nan;

validPara = sum(isnan(paraMat), 2) == 0;

group    = nan(length(paras), 1);

for nGroup = 1:length(expression)
    
    indexExpression = strcmp(expression{nGroup}, {paras.expression});
    indexCaInd      = strcmp(CaIndicator{nGroup}, {paras.CaIndicator});
    
    group(indexExpression & indexCaInd)     = nGroup;
end

load([TempDatDir 'DataListCells.mat'], 'totCell');

EVmat               = cell(4, 1);

for nGroup           = 1:4
    nGroupCell       = totCell(group == nGroup & validPara);
    nGroupPara       = paraMat(group == nGroup & validPara, :);
    EVmatNGroup      = nan(length(nGroupCell), 101, 5);
    for nCell        = 1:length(nGroupCell)
        spk          = nGroupCell(nCell).spk;
        dff          = nGroupCell(nCell).dff;
        t_frame      = nGroupCell(nCell).CaTime;
        max_dff      = max(dff);
        dff          = dff/max(dff);
        if isa(dff, 'single'); dff = double(dff); end
        para_final   = nGroupPara(nCell, 1:5);
        para_final(1) = para_final(1)/max_dff;
        ev           = nan(101, 5);
        
        % 1000x MCMC to recompute EV
        rand_mcmc    = (0:100)/100 + 0.5;
        
        for n_mcmc   = 1:101
            rand_n_mcmc = rand_mcmc(n_mcmc);
            for n_para  = 1:5
                para_final_r = para_final;
                para_final_r(n_para) = para_final_r(n_para).*rand_n_mcmc;
                fitCaTraces  = func_getCaTraces_sigmoid({spk}, t_frame,para_final_r);
                ev(n_mcmc, n_para) = 1- sum((fitCaTraces-dff).^2)/length(dff)/var(dff);
            end
        end
        
        EVmatNGroup(nCell, :, :) = ev;
        
    end   
    
    EVmat{nGroup} = EVmatNGroup;
end


Sensitivity_index = nan(39, 6);

nCell      = 0;

for nGroup = 1:4
    
    EVmatNGroup = EVmat{nGroup};
    
    for nGroupNCell = 1:size(EVmatNGroup,1)
        nCell = nCell + 1;
        Sensitivity_index(nCell, 1) = nGroup;
        ev    = squeeze(EVmatNGroup(nGroupNCell, :, :));
        for n_para = 1:5
            if min(ev(:,n_para))<max(ev(:,n_para))*0.9
                delta_para = (sum(ev(:,n_para)>=max(ev(:,n_para))*0.9)-1)/100/2;
                Sensitivity_index(nCell, 1+n_para) = 0.1/delta_para;
            else
                Sensitivity_index(nCell, 1+n_para) = (max(ev(:,n_para))-min(ev(:,n_para)))/max(ev(:,n_para))/0.5;
            end
        end
    end
    
end

nGroupName = {'Fm', '[Ca++]0', 'beta', '\tau_d', '\tau_r'};
figure;
for nKey = 1:4
    subplot(1, 4, nKey)
    boxplot(Sensitivity_index(Sensitivity_index(:, 1)==nKey, 2:end), 'label', nGroupName) %, 'colors', 'k','plotStyle','compact'
    box off
    set(gca, 'TickDir', 'out')
    set(gca, 'XTick', 1:5)
    ylim([0 1.1])
end
setPrint(8*4, 6, ['ParamsComparison_Groups_para_sensivity'])