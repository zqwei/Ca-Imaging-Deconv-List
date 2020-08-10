# List Of Calcium Imaging Deconvolution Methods

[![](https://img.shields.io/badge/Channel-calcium2spike-blue.svg?style=popout-square&logo=slack)](https://ephys-imaging.slack.com/messages/CFPH4E859)

[![DOI](https://zenodo.org/badge/53284804.svg)](https://zenodo.org/badge/latestdoi/53284804)


Here is a collection of published calcium imaging deconvolution methods and link to their codes.

A revision of each code for __basic performance test__ is marked as revision in list.

## Main goal

As a part of my thesis work (unpublished yet), we will try to make a comparison of exisiting calcium imaging deconvolution methods, using the [published dataset](http://crcns.org/data-sets/methods/cai-1) from Karel Svoboda's lab, where both electrical and GCaMP optical responses of a single neuron are simultaneously recorded. We laid out serveral performance indice in comparison and left a note for the performance computation, which is not clear in the original codes. This comparison project is planned to be gradually invovled. In this case, one can leave notes in __Issues tracker__, if any new comparison is missing in list or any performance should be computed towards cross comparison.

> * Dataset description: Simultaneous imaging and loose-seal cell-attached electrical recordings from neurons expressing a variety of genetically encoded calcium indicators. The data is described in: Akerboom, et al JNS 2012 and Chen, et al Nature 2013. The data provides ground truth by recording electrical and GCaMP optical responses simultaneously.
> * Tested code: all code being test is highlighted in __bold__.

More inquires should be email to: __weiz AT janelia DOT hhmi DOT org__

## Choices of working models
With rapid development of modern statistical techniques in this field, we found us in an exciting whilst, unfortunately, allodoxaphobia position. It seems that the underlying models are more or less the same, but being solved using different approach under a variety of addtional assumptions of noise structures and constraints. Here we list all models in our comparison list, and in the _first_ version of the comparison, we __only__ focus on those with an available code on github (most of them are generative models).

## Code redistributions
We made significant improvements and changes to some of the codes.

# Datasets
Please download data file from 

It contains 90 precompiled recording sessions with field names, which can be directly used in the codes:
* cellName: id of the cells.
* nRep: id of the recording sessions; one cell could have >1 recording sessions.
* expression: expression methods; AAV-virus or transgenic animals.
* CaIndicator: type of calcium indicator.
* spk: spike timing data.
* dff: dF/F fluorescent data.
* CaTime: recording time series of the fluorescent data.

# Spike to imaging models
1. Linear model
2. Quadratic model
3. Hill function model
4. Sigmoid model

# Imaging to spike models

## Ruble based models
1. Thresholding first derivative
2. Template matching

## Unsupervised models
1. Nonngegative Wiener Filter (NWF)
1. Sequential Monte Carlo method (SMC)
    * [Vogelstein et al., Biophys. J., 2009](https://www.sciencedirect.com/science/article/pii/S0006349509003117)
    * Note: change of code -- __P.k = V.spikegen.EFGinv(0.01, P, V);__ to __P.k      = log(-log(1-sum(nnorm)/V.T)/V.dt);__
    * Code (__Matlab__, Python): https://github.com/jovo/smc-oopsi
1. Fast OOPSI (FOOPSI)
    * [Vogelstein et al., J. Neurophysiol., 2010](https://www.physiology.org/doi/full/10.1152/jn.01073.2009?url_ver=Z39.88-2003&rfr_id=ori:rid:crossref.org&rfr_dat=cr_pub%3dpubmed)
    * Note#1: decaying time constant parameter $\gamma = 1 - \Delta/(1.0)$ is not updated/estimated in the code.
    * Note#2: estimating $\gamma$ is difficult
    * Note#3: Yaski and Friedrich (2006) showed that results are somewhat robust to minor variations in time constant  
    * Code (Matlab): https://github.com/jovo/fast-oopsi
    * Code (__Python__): https://github.com/liubenyuan/py-oopsi
    * Revision code: https://github.com/zqwei/Ca-Imaging-Deconv-List/blob/master/fit_code/fast_oopsi.py
1. Finite Rate of Innovation (FRI)
    * [Oñativia et al., J. Neural Eng., 2013](http://stacks.iop.org/1741-2552/10/046017)
    * Code (Matlab): http://www.commsp.ee.ic.ac.uk/~jo210/src/ca_transient.zip
1. Peeling
    * [Grewe et al., Nat. Methods, 2010](https://www.nature.com/articles/nmeth.1453)
    * Code (__Matlab__): https://github.com/HelmchenLab/CalciumSim
1. Constrained OOPSI (COOPSI)
    * [Pnevmatikakis, et al., Neuron, 2016](https://www.sciencedirect.com/science/article/pii/S0896627315010843?via%3Dihub)
    * Code (Matlab): https://github.com/epnev/constrained-foopsi
    * Code (Python): https://github.com/epnev/constrained_foopsi_python
1. MCMC
    * [Pnevmatikakis et al., 2014](http://arxiv.org/abs/1311.6864)
    * Code (Matlab, _beta_): https://github.com/epnev/continuous_time_ca_sampler
1. MLSpike
    * [Deneux et al., Nat. Commun.,2016](https://www.nature.com/articles/ncomms12190)
    * Code (Matlab): https://github.com/MLspike

## Supervised models
1. PCA + SVM
1. Spike-triggered mixture (STM)
    * [Theis et al. Neuron, 2016](https://www.cell.com/neuron/pdf/S0896-6273(16)30073-3.pdf)
    * Code (Python): https://github.com/lucastheis/c2s
