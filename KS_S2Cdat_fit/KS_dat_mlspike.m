function KS_dat_mlspike(nCell)
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

est     = mlspike(dff, fr);

save(['../tempDatS2COOPSI/MLSpike_fit_Cell_' num2str(nCell)], 'est')

end
