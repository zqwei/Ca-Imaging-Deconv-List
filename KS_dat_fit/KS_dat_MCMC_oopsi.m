
function KS_dat_MCMC_oopsi(nCell)

load('DataListCells.mat')
warning('off', 'all');

dat     = totCell(nCell);
dff     = double(dat.dff);
% caTime  = double(dat.CaTime);
% dt      = caTime(2) - caTime(1);
% fr      = 1/dt;

cont   = conttime_oopsi(dff); %#ok<NASGU,*ASGLU>
save(['MCMC_oopsi_fit_Cell_' num2str(nCell)], 'cont')
end
