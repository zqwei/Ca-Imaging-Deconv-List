addpath('../Func/plotFuncs')

load('removeList.mat')
load('../KS_dat_fit/DataListCells.mat');
load('../TempDat/ParamsFitCells_S2CModel_linear_nofix.mat')
linearParas  = paras;
linearParas(removeList)  = [];
load('../TempDat/ParamsFitCells_S2CModel_sigmoid_Fmfix.mat')
sigmoidParas = paras;
sigmoidParas(removeList) = [];
load('../TempDat/ParamsFitCells_S2CModel_Fmfix.mat')
hillParas    = paras;
hillParas(removeList)    = [];

clear paras

expression  = {'virus', 'virus', 'transgenic', 'transgenic'};
CaIndicator = {'GCaMP6f', 'GCaMP6s', 'GCaMP6f', 'GCaMP6s'};
group    = nan(length(totCell), 1);
for nGroup = 1:length(expression)    
    indexExpression = strcmp(expression{nGroup}, {totCell.expression});
    indexCaInd      = strcmp(CaIndicator{nGroup}, {totCell.CaIndicator});
    group(indexExpression & indexCaInd)     = nGroup;
end


spk        = zeros(length(totCell), 1);
evMat      = zeros(length(totCell), 3);

for nCell  = 1:length(totCell)
    spk(nCell)      = length(totCell(nCell).spk)/240;
    evMat(nCell, 1) = linearParas(nCell).ev;
    evMat(nCell, 2) = sigmoidParas(nCell).ev;
    evMat(nCell, 3) = hillParas(nCell).ev;
end

figure;
hold on
scatter(evMat(:, 1), evMat(:, 2), [], group)
plot([0 1], [0 1], 'k')
ylabel('Sigmoid fit')
xlabel('Linear fit')
set(gca, 'TickDir', 'out')
setPrint(8, 6, 'Performance_linear', 'pdf')

figure;
hold on
scatter(evMat(:, 3), evMat(:, 2), [], group)
plot([-0.4 1], [-0.4 1], 'k')
ylabel('Sigmoid fit')
xlabel('Hill fit')
set(gca, 'TickDir', 'out')
setPrint(8, 6, 'Performance_hill', 'pdf')

figure;
hold on
scatter(spk, evMat(:, 2), [], group)
ylabel('Sigmoid fit')
xlabel('Spike (/s)')
set(gca, 'TickDir', 'out')
setPrint(8, 6, 'Performance_spk', 'pdf')

figure
subplot(3, 1, 1)
nCell  = 42;
plot(totCell(nCell).CaTime, totCell(nCell).dff)
hold on
plot(totCell(nCell).CaTime, sigmoidParas(nCell).fitCaTraces)
gridxy(totCell(nCell).spk, [])
xlim([50 150])

subplot(3, 1, 2)
nCell   = 29;
plot(totCell(nCell).CaTime, totCell(nCell).dff)
hold on
plot(totCell(nCell).CaTime, sigmoidParas(nCell).fitCaTraces)
gridxy(totCell(nCell).spk, [])
xlim([100 200])

subplot(3, 1, 3)
nCell   = 37;
plot(totCell(nCell).CaTime, totCell(nCell).dff)
hold on
plot(totCell(nCell).CaTime, sigmoidParas(nCell).fitCaTraces)
gridxy(totCell(nCell).spk, [])
xlim([100 200])
setPrint(8, 18, 'ExampleNeuron', 'pdf')

figure
nCell  = 53;
plot(totCell(nCell).CaTime, totCell(nCell).dff)
hold on
plot(totCell(nCell).CaTime, sigmoidParas(nCell).fitCaTraces)
gridxy(totCell(nCell).spk, [])
xlim([50 100])
setPrint(8, 6, 'ExampleNeuron', 'pdf')