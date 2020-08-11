%
% Parameter space for S2F fitting in different imaging conditions
% 
% Figure S3, Wei et al., 2020
%
% Please create Plots folder if necessary for PlotDir
%
% author: Ziqiang Wei
% email: weiz@janelia.hhmi.org
%
% 

%% all parameters -- Figure S3A

addpath('../Func');
setDir;
load([TempDatDir 'ParamsFitCells_S2CModel_nofix.mat'], 'paras');

if ~exist([PlotDir 'ModelCellFits'],'dir')
    mkdir([PlotDir 'ModelCellFits'])
end

nKeys    = {'tau_r', 'tau_d', 'n', 'K', 'Fm'};

paraMat  = nan(length(paras), length(nKeys));

for nKey = 1:length(nKeys)
    paraMat(:, nKey) = [paras.(nKeys{nKey})];
end

group    = nan(length(paras), 1);

for nGroup = 1:length(expression)
    
    indexExpression = strcmp(expression{nGroup}, {paras.expression});
    indexCaInd      = strcmp(CaIndicator{nGroup}, {paras.CaIndicator});
    
    group(indexExpression & indexCaInd)     = nGroup;
end


nTitles = {'\tau_{r}', '\tau_{d}', 'n', 'K', 'Fm'};

groupColor = [         0    0.4470    0.7410
    0.9290    0.6940    0.1250
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840];

figure;
gplotmatrix(paraMat, [], group, groupColor, 'oooo', [], 'off', [], nTitles, nTitles);

setPrint(8*2, 8*2, [PlotDir 'ParamsFitCells_S2CModel_nofix'])

%% Fm fixed

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
    boxplot(paraMat(:, nKey), group, 'label', nGroupName, 'colors', 'k','plotStyle','compact')
    box off
    ylabel(nTitles{nKey})
    xlabel('Ca++ indicator type')
    set(gca, 'TickDir', 'out')
end
setPrint(8*5, 6, [PlotDir 'ModelCellFits/ParamsComparison_Groups'])

% close all

