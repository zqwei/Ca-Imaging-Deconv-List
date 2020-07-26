function fit_mlspike(nCell)
addpath('../fit_code/')
load('DataListCells.mat')
warning('off', 'all');

dat     = totCell(nCell);
dff     = double(dat.dff);
caTime  = double(dat.CaTime);
dt      = caTime(2) - caTime(1);
fr      = 1/dt;

est     = mlspike(dff, fr);

save(['MLSpike_fit_Cell_' num2str(nCell)], 'est')

end