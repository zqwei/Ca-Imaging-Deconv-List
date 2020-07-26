function [numdata numdataheaders textdata textdataheaders] = fn_readtextdata(filename,separator)
% function [numdata numdataheaders textdata textdataheaders] = fn_readtextdata(filename,separator)
% function datastruct = fn_readtextdata(filename,separator)
%---
% This functions is approximately equivalent to Matlab 'Import data'
% functionality, i.e. it imports formatted data where the first row
% contains headers and the subsequent rows can contain both numerical and
% text data

% Thomas Deneux
% Copyright 2015-2017

if nargin==0, filename = fn_getfile('Please select text file'); end

% Read file
x = fn_readtext(filename);

% Separator
if nargin<2, separator = ';'; end

% Headers
headers = fn_strcut(x{1},separator);
x(1) = [];
ndata = length(headers);

% Data
nrow = length(x);
data = cell(nrow,ndata);
for i=1:nrow, data(i,:) = fn_strcut(x{i},separator,true); end

% Which columns are numerical/text?
numcol = false(1,ndata);
for i=1:ndata
    xi = data{1,i};
    numcol(i) = ~isnan(str2double(strrep(xi,',','.'))) || ~isempty(regexpi(xi,'^ *nan *$'));
end

% Output
numdataheaders = headers(numcol);
textdataheaders = headers(~numcol);
numdata = fn_map(@(s)str2double(strrep(s,',','.')),data(:,numcol),'array');
textdata = data(:,~numcol);
if nargout==1 && ~all(numcol)
    numdata = struct('numdataheaders',{numdataheaders},'numdata',numdata, ...
        'textdataheaders',{textdataheaders},'textdata',{textdata});
end

