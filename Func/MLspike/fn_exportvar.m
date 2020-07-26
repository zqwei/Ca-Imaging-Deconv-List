function fn_exportvar(x)
% function fn_exportvar(x)
%---
% Export data to a Matlab variable in base workspace

% Thomas Deneux
% Copyright 2015-2017

% Variable name
ivar = 1;
while evalin('base',['exist(''var' num2str(ivar) ''',''var'')']), ivar = ivar+1; end
ok = false;
while ~ok
    varname = inputdlg('Name of variable','Import data',1,{['var' num2str(ivar)]});
    if isempty(varname), return, end
    varname = varname{1};
    ok = ~evalin('base',['exist(''' varname ''',''var'')']);
    if ~ok
        switch questdlg(['Variable ''' varname ''' already exists. Overwrite?'],'Confirmation','Yes','No','Cancel','Yes')
            case {'' 'Cancel'}
                return
            case 'Yes'
                ok = true;
            case 'No'
                ok = false;
        end
    end
end

% Import
assignin('base',varname,x)
