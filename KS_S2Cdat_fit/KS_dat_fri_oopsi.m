function KS_dat_fri_oopsi(nCell)
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

fri     = fri_oopsi(dff,tau, fr); %#ok<NASGU>

save(['../tempDatS2COOPSI/FRI_oopsi_fit_Cell_' num2str(nCell)], 'fri')

end
