function fit_fri_oopsi(nCell)
addpath('../fit_code')
load('DataListCells.mat')
warning('off', 'all');

dat     = totCell(nCell);
dff     = double(dat.dff);
caTime  = double(dat.CaTime);
dt      = caTime(2) - caTime(1);
fr      = 1/dt;
tau     = 1.0;

fri     = fri_oopsi(dff,tau, fr); %#ok<NASGU>

save(['FRI_oopsi_fit_Cell_' num2str(nCell)], 'fri');

end
