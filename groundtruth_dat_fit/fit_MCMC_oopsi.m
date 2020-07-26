function fit_MCMC_oopsi(nCell)

load('DataListCells.mat')
warning('off', 'all');

dat     = totCell(nCell);
dff     = double(dat.dff);

cont   = conttime_oopsi(dff); %#ok<NASGU,*ASGLU>
save(['MCMC_oopsi_fit_Cell_' num2str(nCell)], 'cont')
end
