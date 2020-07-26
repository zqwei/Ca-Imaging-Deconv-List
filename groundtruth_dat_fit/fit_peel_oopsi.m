function fit_peel_oopsi(nCell)

load('DataListCells.mat')
warning('off', 'all');

dat     = totCell(nCell);
dff     = double(dat.dff);
caTime  = double(dat.CaTime);
dt      = caTime(2) - caTime(1);
fr      = 1/dt;

[ca_p,peel_p, data]  = peel_oopsi(dff', fr);
peel                 = data;
peel.ca_params       = ca_p;
peel.peel_params     = peel_p;

[ca_p,peel_p, data]  = peel_nl_oopsi(dff', fr);
peelNL                 = data;
peelNL.ca_params       = ca_p;
peelNL.peel_params     = peel_p;

save(['Peel_oopsi_fit_Cell_' num2str(nCell)], 'peel', 'peelNL')

end
