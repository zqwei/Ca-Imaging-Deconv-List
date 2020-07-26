% Get information about how many Matlab floating licenses are used on the network 

% Thomas Deneux
% Copyright 2013-2017

swd = cd;
cd(matlabroot)

switch lower(computer)
    case 'pcwin'
        attempts = {'bin/win32' 'etc/win32'};
        for k=1:length(attempts)
            lmdir = attempts{k};
            ok = exist(fullfile(lmdir,'lmutil.exe'),'file');
            if ok, break, end
        end
        if ~ok, error 'cannot locate file lmutil.exe', end
    case 'pcwin64'
        attempts = {'bin/win64' 'etc/win64'};
        for k=1:length(attempts)
            lmdir = attempts{k};
            ok = exist(fullfile(lmdir,'lmutil.exe'),'file');
            if ok, break, end
        end
        if ~ok, error 'cannot locate file lmutil.exe', end
    otherwise
        lmdir= ['./etc/' lower(computer)];
        cmd = ['./' cmd];
end

cd(lmdir)
system('lmutil lmstat -a -c ../../licenses/network.lic');
cd(swd)