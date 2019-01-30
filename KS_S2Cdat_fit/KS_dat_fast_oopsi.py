import fast_oopsi
import constrained_oopsi
from scipy.io import loadmat, savemat
import sys


def main(argv):
	nCell = int(float(argv))
	fast, wiener, discr, cf1, cf2, cf3 = KS_dat_fast_oopsi(nCell)
	save_vars = {'fast': fast, 'wiener': wiener, 'discr': discr, 'cf1': cf1, 'cf2': cf2, 'cf3': cf3}
	savemat('Fast_oopsi_fit_Cell_' + str(nCell), save_vars)


def KS_dat_fast_oopsi(nCell):
    totCell = loadmat('DataListCells.mat')
    dff = totCell['totCell'][nCell - 1]['dff']
    dff = dff[0].astype('float64')[:, 0]
    spk = totCell['totCell'][nCell - 1]['spk']
    spk = spk[0]
    caTime = totCell['totCell'][nCell - 1]['CaTime']
    caTime = caTime[0]
    dt = caTime[1] - caTime[0]
    d, C, P, F_est = fast_oopsi.fast(dff, dt=dt, iter_max=100)
    fast = {'d': d, 'C': C, 'P': P, 'F_est': F_est}
    # wiener filter,
    d, C, F_est, F_est_nonneg = fast_oopsi.wiener(dff, dt=dt, iter_max=100)
    wiener = {'d': d, 'C': C, 'F_est_nonneg': F_est_nonneg, 'F_est': F_est}
    # descritize,
    d, v = fast_oopsi.discretize(dff, bins=[0.75])
    discr = {'d': d, 'v': v}
    # constrained-foopsi
    methods = ['cvxpy', 'spgl1', 'debug', 'cvx']
    c, bl, c1, g, sn, spikes = constrained_oopsi.constrained_foopsi(dff, p=1, noise_range=[.25, .5], methods=methods[0])
    cf1 = {'c': c, 'bl': bl, 'c1': c1, 'g': g, 'sn': sn, 'spikes': spikes}
    c, bl, c1, g, sn, spikes = constrained_oopsi.constrained_foopsi(dff, p=2, noise_range=[.25, .5], methods=methods[0])
    cf2 = {'c': c, 'bl': bl, 'c1': c1, 'g': g, 'sn': sn, 'spikes': spikes}
    c, bl, c1, g, sn, spikes = constrained_oopsi.constrained_foopsi(dff, p=3, noise_range=[.25, .5], methods=methods[0])
    cf3 = {'c': c, 'bl': bl, 'c1': c1, 'g': g, 'sn': sn, 'spikes': spikes}
    return fast, wiener, discr, cf1, cf2, cf3


if __name__ == "__main__":
	main(sys.argv[1])
