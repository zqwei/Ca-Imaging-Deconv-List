function fn_mkdir(D)
% function fn_mkdir(D)
%---
% creates directory D if it does not exist

% Thomas Deneux
% Copyright 2004-2017

if nargin==0, help fn_mkdir, end

if ~exist(D,'dir'), mkdir(D), end
