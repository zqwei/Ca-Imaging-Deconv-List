#!/groups/ahrens/home/weiz/miniconda3/envs/suite2p/bin/python

import numpy as np
from scipy.io import loadmat, savemat
from suite2p import dcnv

totCell = loadmat('DataListCells.mat')
numCell = totCell['totCell'].shape[0]

for nCell in range(numCell):
    dff    = totCell['totCell'][nCell-1]['dff']
    dff    = dff[0].astype('float64')[:,0]
    spk    = totCell['totCell'][nCell-1]['spk']
    spk    = spk[0]
    caTime = totCell['totCell'][nCell-1]['CaTime']
    caTime = caTime[0]
    dt     = caTime[1] - caTime[0]
    tau = 1.0 # timescale of indicator
    fs = 60.0 # sampling rate in Hz
    baseline = 'maximin' # take the running max of the running min after smoothing with gaussian
    sig_baseline = 10.0 # in bins, standard deviation of gaussian with which to smooth
    win_baseline = 60.0 # in seconds, window in which to compute max/min filters
    ops = {'tau': tau, 'fs': fs, 'baseline': baseline, 'sig_baseline': sig_baseline, 'win_baseline': win_baseline}
    # baseline operation
    Fc = dff[np.newaxis, :]
    Fc = dcnv.preprocess(Fc, ops)
    # get spikes
    spks = dcnv.oasis(Fc, ops)
    
    g = -1./(ops['tau'] * ops['fs'])
    nsamples = len(dff)
    ca = np.zeros(nsamples,)
    ca_new = 0.
    for t in range(nsamples):
        ca_new = ca_new * np.exp(g) + spks[0, t]
        ca[t] = ca_new