function hostname = fn_hostname()
% function hostname = fn_hostname()
%---
% returns an identifiant specific to the computer in use

% Thomas Deneux
% Copyright 2015-2017

comp = computer;
switch comp
    case {'PCWIN' 'PCWIN64'}
        comp = 'PCWIN';
        hostname = getenv('COMPUTERNAME');
    otherwise
        hostname = getenv('HOSTNAME');
        if isempty(hostname)
            [dum hostname] = system('echo $HOSTNAME');
            hostname = strrep(hostname,char(10),''); % remove endlines
        end %#ok<*ASGLU>
end
hostname = [comp '-' hostname];

