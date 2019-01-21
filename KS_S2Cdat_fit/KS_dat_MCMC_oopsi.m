function KS_dat_MCMC_oopsi(nCell)

addpath('../fit_code/')
load('ParamsFitCells.mat')
warning('off', 'all');

dat     = paras(nCell);
dff     = double(dat.fitCaTraces);

cont   = conttime_oopsi(dff); %#ok<NASGU,*ASGLU>
save(['../tempDatS2COOPSI/MCMC_oopsi_fit_Cell_' num2str(nCell)], 'cont')
end
