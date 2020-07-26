function b = fn_matlabversion(flag)
% function b = fn_matlabversion(version)
% function b = fn_matlabversion('newgraphics')
%---
% returns true if the current Matlab version is equal to or newer than the
% specified version

% Thomas Deneux
% Copyright 2015-2017

% current version
v = sscanf(cell2mat(regexp(version,'^\d*.\d*','match')),'%i.%i')';

% compare to
switch flag
    case 'newgraphics'
        vcomp = [8 4];
    otherwise
        vcomp = sscanf(cell2mat(regexp(flag,'^\d*.\d*','match')),'%i.%i')';
end

[v idx] = sortrows([vcomp; v]); %#ok<ASGLU>
b = (idx(1)==1); % version is at least vcomp

