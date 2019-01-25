# List Of Calcium Imaging Deconvolution Methods

[![](https://img.shields.io/badge/Channel-calcium2spike-blue.svg?style=popout-square&logo=slack)](https://ephys-imaging.slack.com/messages/CFPH4E859)

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

# Imaging to spike models

## Ruble based models
1. Thresholding first derivative
2. Template matching

## Unsupervised models
1. Nonngegative Wiener Filter (NWF)
1. Sequential Monte Carlo method (SMC)
1. Fast OOPSI (FOOPSI)
1. Finite Rate of Innovation (FRI)
1. Peeling
    * [Grewe et al., Nat. Methods, 2010](https://www.nature.com/articles/nmeth.1453)
    * Code (__Matlab__): https://github.com/HelmchenLab/CalciumSim
1. Constrained OOPSI (COOPSI)
1. MCMC
1. MLSpike

## Supervised models
1. PCA + SVM
1. Spike-triggered mixture (STM)

##  SMC OOPSI
* Model:
  * Parent model:
* Main paper:
  *
* Note:
  * change of code:
    1. __P.k = V.spikegen.EFGinv(0.01, P, V);__ to __P.k      = log(-log(1-sum(nnorm)/V.T)/V.dt);__
* Code (__Matlab__, Python): https://github.com/jovo/smc-oopsi
* Original contribution: Josh Vogelstein
* Revision:

##  Fast OOPSI
* Model:
  * Parent model:
* Main paper:
  *
* Note: decaying time constant parameter $\gamma = 1 - \Delta/(1.0)$ is not updated/estimated in the code.

>   1. estimating $\gamma$ is difficult
>   2. Yaski and Friedrich (2006) showed that results are somewhat robust to minor variations in time constant  

* Code (Matlab): https://github.com/jovo/fast-oopsi
* Code (__Python__): https://github.com/liubenyuan/py-oopsi
* Original contribution: Josh Vogelstein, Benyuan Liu
* Revision: https://github.com/zqwei/py-oopsi

##  Constrained Fast OOPSI
* Model: an extension of __Fast OOPSI__
	* Method extension:
			1. strict non-negative constraint of firing rate
			2. extension of  to a general AR(p) process
			3. empirical estimation of noise prior
  * Parent model: Fast OOPSI (using [__conic programming__](http://cvxopt.org/))
* Main paper:
  *
* Code (Matlab): https://github.com/epnev/constrained-foopsi
* Code (Python): https://github.com/epnev/constrained_foopsi_python
* Original contribution: Eftychios Pnevmatikakis, Josh Merel, Losonczy Lab
* Revision:

##  Constrained Fast OOPSI (MCMC spike inference in continuous time)
* Model:
  * Parent model:
* Main paper:
  *
* Code (Matlab, _beta_): https://github.com/epnev/continuous_time_ca_sampler
* Original contribution: Eftychios Pnevmatikakis, John Merel
* Revision:

## Fast rate of innovation algorithm
* Model:
* Main paper: [Jon Oñativia, Simon R. Schultz, and Pier Luigi Dragotti, A Finite Rate of Innovation algorithm for fast and accurate spike detection from two-photon calcium imaging. (J. Neural Eng. 10 (2013) 046017)](http://stacks.iop.org/1741-2552/10/046017)
* Code (Matlab): http://www.commsp.ee.ic.ac.uk/~jo210/src/ca_transient.zip
	* File real_data.m runs the double consistency algorithm on real data and reproduces figure 7 of the journal paper.
	* File surrogate_data.m runs the double consistency algorithm on surrogate data.
	* File fig3.m reproduces figure 3 of the journal paper.
	* File fig9.m reproduces figure 9 of the journal paper.
* Original contribution: Jon Oñativia
* Revision:

## STM fit based model
* Model:
	* STM fit model: model is built to supervise-learning the parameter of the conditional distribution $p(y \mid x, z) = q(y \mid g(f(x, z)))$, where $y$ is a scalar, $x \in R^N$, $z \in R^M$, $q$ is a univariate distribution, $g$ is some nonlinearity, and $f(x, z) = \log \sum_k \exp\left( \lambda \left[ \sum_l \beta_{kl} (u_l^\top x)^2 + w_k x + a_k \right] \right) / \lambda + v^\top z$. (see __Conditional Modeling Toolkit__ for detail)
* Main paper: [L. Theis, P. Berens, E. Froudarakis, J. Reimer, M. Roman-Roson, T. Baden, T. Euler, A. S. Tolias, et al.
Supervised learning sets benchmark for robust spike detection from calcium imaging signals
bioRxiv, 2014](http://bethgelab.org/publications/127/)
* __Important note__ : This paper is also one with extensive comparison of STM, SI08, PP14, OD13, VP10, VP09, YF06 algorithms.
* Code (Python): https://github.com/lucastheis/c2s
* Original contribution: Lucas Theis
* Revision:

## SI08

## YF06

## Equation renders of readme file in this git
Unfortunately, you need to do it on your own side by installing chrome app [Github with Mathjax](https://chrome.google.com/webstore/detail/github-with-mathjax/ioemnmodlmafdkllaclgeombjnmnbima).
