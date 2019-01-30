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
nKeys    = {'tau_r', 'tau_d', 'Ca0', 'beta', 'FmNorm', 'ev', 'Fm'};
paraMat  = nan(length(paras), length(nKeys));
for nKey = 1:length(nKeys)
    paraMat(:, nKey) = [paras.(nKeys{nKey})];
end
paraMat(paraMat(:,1)>0.2, 1) = nan;
paraMat(paraMat(:,5)<0 | paraMat(:,5)>500, 5) = nan;
paraMat(paraMat(:,6)<0.6, 4) = nan;
paraMat(paraMat(:,6)<0.6, 3) = nan;
paraMat(:, 1) = paraMat(:, 1)*1000;

validIndex = sum(isnan(paraMat), 2)==0;

% paraMat(paraMat(:,5)>2, 5) = nan;
% paraMat(paraMat(:,4)>5, 4) = nan;
% paraMat(paraMat(:,3)>10, 3) = nan;
% paraMat(paraMat(:,2)>4, 2) = nan;

% paraMat(paraMat(:,3)>5, 3) = nan;
group    = nan(length(paras), 1);
for nGroup = 1:length(expression)
    
    indexExpression = strcmp(expression{nGroup}, {paras.expression});
    indexCaInd      = strcmp(CaIndicator{nGroup}, {paras.CaIndicator});
    
    group(indexExpression & indexCaInd)     = nGroup;
end
nTitles = {'\tau_{r}', '\tau_{d}', 'Ca0', 'beta', 'Fm'};
groupColor = [0.3 0.3 0.3
    0.9290    0.6940    0.1250
    0.5    0    0.5
    18/255    125/255    9/255];
figure;

paramLimit = [0 150; 0 4; 0 10; 0 10; 0 2];
histLimit  = [0 0.12; 0 1.3; 0 0.23; 0 0.82; 0 3.6];

for nParam = 1:5
    for mParam = nParam:5
        subplot(5, 5, (nParam-1)*5+mParam)
        if nParam == mParam
            hold on
            for nGroup = 1:length(expression)
                [f,xi] = ksdensity(paraMat(group==nGroup, nParam));
                %[f, xi] = histcounts(paraMat(group==nGroup, nParam),50);
                % bar(xi(1:end-1), f/sum(f), 'edgecolor', groupColor(nGroup, :), 'facecolor', 'none')
                plot(xi, f/sum(f), '-', 'color', groupColor(nGroup, :), 'linewid', 1.5);
                xlim(paramLimit(nParam, :))
                % ylim(histLimit(nParam, :))
                set(gca, 'xTick', paramLimit(nParam, :))
                % set(gca, 'yTick', histLimit(nParam, :))
            end
            box off
        else
            scatter(paraMat(:, mParam), paraMat(:, nParam), [], group);
            ylim(paramLimit(nParam, :))
            xlim(paramLimit(mParam, :))
            colormap(groupColor)
            [coef, pval] = corr(paraMat(validIndex, mParam), paraMat(validIndex, nParam), 'type', 'Spearman');
            disp([coef, pval])
            set(gca, 'xTick', paramLimit(mParam, :))
            set(gca, 'yTick', paramLimit(nParam, :))
        end
    end
end
% gplotmatrix(paraMat(:, 1:5), [], group, groupColor, 'oooo', [], 'off', [], nTitles, nTitles);
setPrint(8*5, 8*5, [PlotDir 'ModelCellFits/ParamsFitCells_S2CModel_Fmfix'])


groupColors = zeros(length(group), 3);
for nCell  = 1:length(group)
    groupColors(nCell, :) = groupColor(group(nCell), :);
end

parasFmFix = paras;
figure;
subplot(1, 4, 1)
hold on
scatter([parasNoFix.ev],[parasFmFix.ev], [], groupColors,'o', 'filled')
plot([-0.3 1], [-0.3 1], '--k', 'linewid', 1)
xlabel('EV without fixed parameters')
ylabel('EV with parameters Fm fixed')
box off
axis([-0.3 1 -0.3 1])

subplot(1, 4, 2)
hold on
scatter([parasFmFix.var],[parasFmFix.ev], [], groupColors,'o', 'filled')
ylabel('EV with parameters Fm fixed')
xlabel('var. DF/F')
box off


load([TempDatDir 'DataListCells.mat'], 'totCell');
numSpk = arrayfun(@(x) length(x.spk)/x.CaTime(end), totCell, 'uniformoutput', false);
numSpk = cell2mat(numSpk);

subplot(1, 4, 3)
hold on
scatter(numSpk, [parasFmFix.ev], [], groupColors,'o', 'filled')
xlabel('Spike rate (Hz)')
ylabel('EV with parameters Fm fixed')
box off

subplot(1, 4, 4)
hold on
scatter(numSpk, [parasFmFix.var], [], groupColors,'o', 'filled')
xlabel('Spike rate (Hz)')
ylabel('var. DF/F')
box off
setPrint(8*4, 6*1, [PlotDir 'ModelCellFits/ParamsFitEV_FiringRate'])

nGroupName = {'6f-AAV', '6s-AAV', '5.17', '4.3'};
nTitles = {'\tau_{r} (s)', '\tau_{d} (s)', 'n', 'K', 'Fm'};
figure('visible', 'on');
for nKey = 1:length(nKeys)
    subplot(1, length(nKeys), nKey)
    boxplot(paraMat(:, nKey), group, 'label', nGroupName) %, 'colors', 'k','plotStyle','compact'
    box off
    ylabel(nTitles{nKey})
    xlabel('Ca++ indicator type')
    set(gca, 'TickDir', 'out')
end
setPrint(8*5, 6, [PlotDir 'ModelCellFits/ParamsComparison_Groups'])

close all

