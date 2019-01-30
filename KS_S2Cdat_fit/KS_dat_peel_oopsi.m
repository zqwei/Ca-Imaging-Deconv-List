function KS_dat_peel_oopsi(nCell)
addpath('../fit_code/')
load('ParamsFitCells.mat')
load('DataListCells.mat')
warning('off', 'all');

dat     = paras(nCell);
dat_    = totCell(nCell);
dff     = double(dat.fitCaTraces);
caTime  = double(dat_.CaTime);
dt      = caTime(2) - caTime(1);
fr      = 1/dt;
tau     = 1.0;

[ca_p,peel_p, data]  = peel_oopsi(dff', fr);
peel                 = data;
peel.ca_params       = ca_p;
peel.peel_params     = peel_p;

[ca_p,peel_p, data]  = peel_nl_oopsi(dff', fr);
peelNL                 = data;
peelNL.ca_params       = ca_p;
peelNL.peel_params     = peel_p;

save(['../tempDatS2COOPSI/Peel_oopsi_fit_Cell_' num2str(nCell)], 'peel', 'peelNL')

end
