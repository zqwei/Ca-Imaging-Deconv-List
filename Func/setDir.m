%
% setDirV1Cells.m
%
% This file sets up the basic direction information of the Ca++ imaging
% data and the spiking data
%
% version 1.0
%
% -------------------------------------------------------------------------
% Ziqiang Wei
% weiz@janelia.hhmi.org
% 

warning('off', 'all')
addpath('../Func/plotFuncs')
addpath('../Func/utilFuncs')
addpath('../Func/S2CfitFuncs')
% set(0, 'defaultfigureVisible','off')
set(0, 'defaultaxesTickDir', 'out')
set(0, 'defaultaxesLineWidth', 1.0)


dataDir     = '../../../Data_In_Use/Forward_Model/';
dataFolders = {'GCaMP6f_11cells (Chen 2013)/', 'GCaMP6s_9cells (Chen 2013)/', 'GP517/', 'GP43/'};
expression  = {'virus', 'virus', 'transgenic', 'transgenic'};
CaIndicator = {'GCaMP6f', 'GCaMP6s', 'GCaMP6f', 'GCaMP6s'};


% Load filenames

TempDatDir                   = '../TempDat/';
if ~exist(TempDatDir, 'dir')
    mkdir(TempDatDir)
end


PlotDir                      = '../Plot/';
if ~exist(PlotDir, 'dir')
    mkdir(PlotDir)
end