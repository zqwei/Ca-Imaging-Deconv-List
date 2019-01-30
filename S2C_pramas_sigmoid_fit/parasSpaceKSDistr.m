%
% parameter space for neuronal trace from S2C
%
%

%% all parameters

addpath('../Func');
setDir;
load([TempDatDir 'ParamsFitCells_S2CModel_Sigmoid_Fmfix.mat'], 'paras');
if ~exist([PlotDir 'ModelCellFits'],'dir')
    mkdir([PlotDir 'ModelCellFits'])
end
nKeys    = {'tau_r', 'tau_d', 'Ca0', 'beta', 'Fm', 'ev'};
paraMat  = nan(length(paras), length(nKeys));
for nKey = 1:length(nKeys)
    paraMat(:, nKey) = [paras.(nKeys{nKey})];
end
paraMat(paraMat(:,1)>0.2, 1) = nan;
% paraMat(paraMat(:,5)<0 | paraMat(:,5)>500, 5) = nan;
paraMat(paraMat(:,6)<0.6, 4) = nan;
paraMat(paraMat(:,6)<0.6, 3) = nan;

paraMat(:, 1) = paraMat(:, 1);%*1000;


group    = nan(length(paras), 1);
for nGroup = 1:length(expression)    
    indexExpression = strcmp(expression{nGroup}, {paras.expression});
    indexCaInd      = strcmp(CaIndicator{nGroup}, {paras.CaIndicator});
    group(indexExpression & indexCaInd)     = nGroup;
end
nTitles = {'\tau_{r} (ms)', '\tau_{d} (s)', 'Ca0', 'beta', 'Fm'};
groupColor = [         0    0.4470    0.7410
    0.9290    0.6940    0.1250
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840];

figure;

txlim = [230, 4, 20, 10];

for nTitle = 1:length(nTitles) - 1
    subplot(1, length(nTitles), nTitle);
    hold on;
    for nGroup = 1:4
        [f,xi] = ksdensity(paraMat(group==nGroup, nTitle));
        [nTitles{nTitle} '_' expression{nGroup} '_' CaIndicator{nGroup}]
        [nanstd(paraMat(group==nGroup, nTitle)), nanmedian(paraMat(group==nGroup, nTitle)), nanmean(paraMat(group==nGroup, nTitle))]    
        plot(xi, f, '-', 'color', groupColor(nGroup, :), 'linewid', 1.5);
    end
    xlabel(nTitles{nTitle});
    xlim([0 txlim(nTitle)]);
    ylabel('prob. dens.')
    hold off
    box off
    set(gca, 'TickDir', 'out')
end

% subplot(1, length(nTitles), length(nTitles));
% hold on
% nGroupName = {'6f-AAV', '6s-AAV', 'GP 5.17', 'GP 4.3'};
% for nColor = 1:length(nGroupName)
%     plot(0, nColor, 's', 'color', groupColor(nColor,:), 'MarkerFaceColor',groupColor(nColor,:),'MarkerSize', 8)
%     text(1, nColor, nGroupName{nColor})
% end
% xlim([0 10])
% hold off
% axis off

setPrint(8*5, 6, [PlotDir 'ModelCellFits/ParamsSpaceKSDensity_Groups'])
close all

figure;
hold on
for nGroup = [2 4]
    plot(paraMat(group==nGroup, 4), 1./paraMat(group==nGroup, 3), 'o', 'color', groupColor(nGroup, :));
end
plot([0 4], [0 1], '--k')
% xlabel(nTitles{nTitle});
% ylabel(nTitles{nTitle});
xlim([0 4]);
ylim([0 1]);
ylabel('prob. dens.')
xlabel('prob. dens.')
hold off
box off
set(gca, 'TickDir', 'out')
setPrint(8, 6, [PlotDir 'ModelCellFits/beta_Ca0'])


Percs   = [0.05, 0.95];

nTitles = {'tau_r', 'tau_d', 'n', 'K'};

for nTitle = 1:length(nTitles)
    for nGroup = 1:length(expression)
        [f,xi] = ksdensity(paraMat(group==nGroup, nTitle));
        [~, id] = max(f);
        params(1, nGroup).(nTitles{nTitle}) = xi(id); %#ok<SAGROW>
    end
end


for nTitle = 1:length(nTitles)
    for nGroup = 1:length(expression)
        f = ksdensity(paraMat(group==nGroup, nTitle), Percs, 'function', 'icdf');
        for  nPerc = 1:length(Percs)
            params(nPerc+1, nGroup).(nTitles{nTitle}) = f(nPerc);
        end
    end
end

save([TempDatDir 'ParamsFitCells_S2CModel_Sim.mat'], 'params');