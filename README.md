# List Of Calcium Imaging Deconvolution Methods

[![Join the chat at https://gitter.im/zqwei/Ca-Imaging-Deconv-List](https://badges.gitter.im/zqwei/Ca-Imaging-Deconv-List.svg)](https://gitter.im/zqwei/Ca-Imaging-Deconv-List?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Here is a collection of published calcium imaging deconvolution methods and link to their codes.

A revision of each code for __basic performance test__ is marked as revision in list.

## Main goal

As a part of my thesis work (unpublished yet), we (Ziqiang Wei and Shaul Druckmann) will try to make a comparison of exisiting calcium imaging deconvolution methods, using the [published dataset](http://crcns.org/data-sets/methods/cai-1) from Karel Svoboda's lab, where both electrical and GCaMP optical responses of a single neuron are simultaneously recorded. We laid out serveral performance indice in comparison and left a note for the performance computation, which is not clear in the original codes. This comparison project is planned to be gradually invovled. In this case, one can leave notes in __Issues tracker__, if any new comparison is missing in list or any performance should be computed towards cross comparison.

> Dataset description: Simultaneous imaging and loose-seal cell-attached electrical recordings from neurons expressing a variety of genetically encoded calcium indicators. The data is described in: Akerboom, et al JNS 2012 and Chen, et al Nature 2013. The data provides ground truth by recording electrical and GCaMP optical responses simultaneously.



## Helmchen Model
* Model:
  * Peeling
  * Parent model: 
* Main paper:
  * http://www.hifo.uzh.ch/research/helmchen/publication/grewe2010.pdf
  * 
* Code (Matlab): https://github.com/HelmchenLab/CalciumSim
* Original contribution: Helmchen Lab
* Revision: 

##  SMC OOPSI
* Model:
  * Parent model: 
* Main paper:
  * 
* Code (Matlab, Python): https://github.com/jovo/smc-oopsi
* Original contribution: Josh Vogelstein
* Revision: 

##  Fast OOPSI
* Model:
  * Parent model: 
* Main paper:
  * 
* Code (Matlab): https://github.com/jovo/fast-oopsi
* Code (Python): https://github.com/liubenyuan/py-oopsi
* Original contribution: Josh Vogelstein, Benyuan Liu
* Revision: https://github.com/zqwei/py-oopsi

##  Constrained Fast OOPSI
* Model:
  * Parent model: 
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

## Group LASSO initialization and spatial CNMF
* Model:
  * "Group Lasso" to detect neuronal centers and activity
  * Coordinate descent gready NMF to find neuronal activity and (non-negtive) shapes, based on group lasso initialization
  * Parent model: 
* Main paper:
  * 
* Code (Matlab, Python): https://github.com/danielso/ROI_detect
* Original contribution: Daniel So
* Revision:

## Deconvolution and demixing of calcium imaging data code
* Model:
* Main paper:
* Code (Matlab): https://github.com/epnev/ca_source_extraction
* Code (Python): https://github.com/agiovann/Constrained_NMF
* Code (source extraction, Python; _alpha_): https://github.com/epnev/SOURCE_EXTRACTION_PYTHON
* Original contribution: Andrea Giovannucci and Eftychios Pnevmatikakis
* Revision:

## Sequential Image Analysis
* Model: Open source package for analysise of time-series imaging data arising from fluorescence microscopy (__Losonczy Lab__)
 * Correction of motion artifacts
 * Segmentation of imaging fields into regions of interest (ROIs)
 * Extraction of dynamic signals from ROIs
 * Parent model:
  * Constrained Fast OOPSI: https://github.com/epnev/constrained_foopsi_python
* Main paper: [Kaifosh P, Zaremba J, Danielson N, and Losonczy A. SIMA: Python software for analysis of dynamic fluorescence imaging data. Frontiers in Neuroinformatics. 2014 Aug 27; 8:77. doi: 10.3389/fninf.2014.00077.](http://journal.frontiersin.org/article/10.3389/fninf.2014.00080/full)
* Code (Python): https://github.com/losonczylab/sima
* Original contribution: Losonczy Lab
* Revision:
