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


%% all parameters -- Figure S3A diagonal -- KSDensity plots
figure;

txlim = [230/1000, 4, 3.1, 160];

for nTitle = 1:length(nTitles) - 1
    subplot(1, length(nTitles), nTitle);
    hold on;
    for nGroup = 1:length(expression)
        [f,xi] = ksdensity(paraMat(group==nGroup, nTitle));
        plot(xi, f, '-', 'color', groupColor(nGroup, :), 'linewid', 1.5);
    end
    xlabel(nTitles{nTitle});
    xlim([0 txlim(nTitle)]);
    ylabel('prob. dens.')
    hold off
    box off
    set(gca, 'TickDir', 'out')
end

subplot(1, length(nTitles), length(nTitles));
hold on
nGroupName = {'6f-AAV', '6s-AAV', 'GP 5.17', 'GP 4.3'};
for nColor = 1:length(nGroupName)
    plot(0, nColor, 's', 'color', groupColor(nColor,:), 'MarkerFaceColor',groupColor(nColor,:),'MarkerSize', 8)
    text(1, nColor, nGroupName{nColor})
end
xlim([0 10])
hold off
axis off

setPrint(8*5, 6, [PlotDir 'ModelCellFits/ParamsSpaceKSDensity_Groups'])


%% all parameters -- Figure S3A diagonal -- KSDensity plots












































