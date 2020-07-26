function pg(varargin)
% function pg(prompt,i,max)
% function pg(i,max)
% function pg(i)
% function pg('i')
%---
% this is a shortcut for using fn_progress: instead of initializing before
% a loop with fn_progress(prompt,max), and then updating at each loop with
% fn_progress(i), only write pg(promt,i,max) inside the loop (the proper
% initialization will be called at the appropriate time)

% Thomas Deneux
% Copyright 2015-2017


persistent ilast curprompt curmax ndigit format tlast

switch nargin
    case 0
        help pg
        return
    case 1
        i = varargin{1};
        [prompt max] = deal('loop',0);
    case 2
        [i max] = deal(varargin{:});
        prompt = 'loop';
    case 3
        [prompt i max] = deal(varargin{:});
    otherwise
        error 'too many arguments'
end
if ischar(i), i = evalin('caller',i); end
if ischar(max), max = evalin('caller',max); end


if isempty(ilast) || i<=ilast || ~strcmp(prompt,curprompt) || curmax~=max
    [curprompt curmax] = deal(prompt,max);
    if max
        ndigit = floor(log10(max)+1);
    else
        ndigit = floor(log10(i)+1);
    end
    format = ['%' num2str(ndigit) 'i'];
    if max
        format = [format '/' num2str(max,format)];
    end
    fprintf([prompt ' ' num2str(i,format) '\n'])
else
    if now-tlast<1e-6, return, end
    nerase = ndigit + (max>0)*(1+ndigit) + 1;
    if max
        if i>max, error 'i>max', end
    else
        ndigitnew = floor(log10(i)+1);
        if ndigitnew>ndigit
            ndigit = ndigitnew;
            format = ['%' num2str(ndigit) 'i'];
        end
    end
    fprintf([repmat('\b',1,nerase) num2str(i,format) '\n'])
end
ilast = i;
tlast = now;
drawnow
