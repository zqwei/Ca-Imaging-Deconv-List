%
% Comparison between data and TWC model
% Noise in time
% Noise of single AP
% -------------------------------------------------------------------------
% Ziqiang Wei
% weiz@janelia.hhmi.org
% 

addpath('../Func/')
setDir;
load([TempDatDir 'DataListCells.mat'], 'totCell');
load([TempDatDir 'ParamsFitCells_S2CModel_Fmfix.mat'], 'paras');

% Search AP and nonAP pattern
preAPLength       = 10;
postAPLength      = 50;
apPattern         = [zeros(preAPLength, 1); 1];
singleAPLength    = preAPLength + 1 + postAPLength;
noAPPattern       = zeros(preAPLength + 1 + postAPLength, 1);

group    = nan(length(paras), 1);
for nGroup = 1:length(expression)    
    indexExpression = strcmp(expression{nGroup}, {paras.expression});
    indexCaInd      = strcmp(CaIndicator{nGroup}, {paras.CaIndicator});
    group(indexExpression & indexCaInd)     = nGroup;
end
nTitles = {'\tau_{r} (ms)', '\tau_{d} (s)', 'n', 'K', 'Fm'};

FPattern = nan(1000, length(noAPPattern));
numSpk   = nan(1000, 1);

nDat     = 0;
for nCell        = find(group'==2)
    CaTime       = totCell(nCell).CaTime;
    peak         = totCell(nCell).peak;
    spk          = totCell(nCell).spk;
    dff          = totCell(nCell).dff;
    if isa(dff, 'single'); dff = double(dff); end
    normalized_dff = (dff - min(dff))/(max(dff)-min(dff));
    
    caPeak                       = zeros(size(dff));
    spikeTimes                   = find(peak);
    for nSpike                   = 1:length(spikeTimes);
        nSpikeTime               = spk(nSpike);
        nCaTime                  = sum(nSpikeTime >= CaTime);
        caPeak(nCaTime)          = caPeak(nCaTime) + 1;
    end
    
    % AP events
    singleAPIndex = strfind(caPeak', apPattern');
    for nAP                  = 1:length(singleAPIndex)
        APindex              = singleAPIndex(nAP);
        if APindex+singleAPLength-1 < length(dff)
            nDat                 = nDat+1;
            FPattern(nDat,:)     = dff(APindex:APindex+singleAPLength-1);
            numSpk(nDat)         = sum(caPeak(APindex:APindex+singleAPLength-1));
        end
    end
    
    noAPIndex                = strfind(caPeak', noAPPattern');
    for nAP                  = 1:length(singleAPIndex)
        nDat                 = nDat+1;
        APindex              = noAPIndex(nAP);
        FPattern(nDat,:)     = dff(APindex:APindex+singleAPLength-1);
        numSpk(nDat)         = sum(caPeak(APindex:APindex+singleAPLength-1));
    end
end

[coeff, score, latent]        = pca(FPattern);
figure;
plot(0:1/60:1, coeff(:,1:4), '-', 'linewid', 1)
gridxy([11/60],[], 'Color','k','Linestyle','--')
xlabel('Time (sec)')
ylabel('PC coeff.')
legend('PC1', 'PC2', 'PC3', 'PC4')
box off
setPrint(8, 6, [PlotDir 'ModelCellFits/AP_Stats_PCAv1'])
setPrint(8, 6, [PlotDir 'ModelCellFits/AP_Stats_PCAv1'],'png')

figure;
nTitles = {'PC1', 'PC2', 'PC3', 'PC4'};
groupColor = [ 0    0.4470    0.7410
    0.8500    0.3250    0.0980
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840];
gplotmatrix(score(numSpk<5,1:4), [], numSpk(numSpk<5), groupColor, 'oooo', [], 'off', [], nTitles, nTitles);
setPrint(16, 12, [PlotDir 'ModelCellFits/AP_Stats_PCAv2'])

