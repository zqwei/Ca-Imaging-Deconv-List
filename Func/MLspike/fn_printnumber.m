function im = fn_printnumber(im,elems,varargin)
% function im = fn_printnumber(im,num|str|scale,options...)
%---
% Print a number or a text as pixels inside an image or movie
%
% Input:
% - im      ND array where to print text
% - num     vector of double - numbers to print in frames
% - str     character array or cell array of character arrays - text to
%           print in frames
% - scale   a cell array with parameters for printing a scale bar: first
%           the size of the scale, second its string (e.g. {[123 3] '1mm'})
% - options see below
%
% Ouput:
% - im      frames with elements printed
%
% If num or str has N elements, the program finds which dimension of im is
% of size N and print a different text for different coordinates in this
% dimension.
% 
% Available options:
% - '3x5', '8x12' [default] or '8x16'   font size
% - 'pos(ition)', posstr
%           posstr is any of 'topleft', 'topright', 'bottomleft',
%           'bottomright', 'center'
% - 'col(or)', col
%           col is a scalar, N-element vector, 1x3 vector or Nx3 array
%           default is black ([0 0 0]) if im has color frames, 0 otherwise

% Thomas Deneux
% Copyright 2015-2017

if nargin==0, help fn_printnumber, return, end

% input
pos = [];
color = 0;
k = 0;
fontsize = '8x12';
while k<length(varargin)
    k = k+1;
    a = lower(varargin{k});
    switch(a)
        case {'pos' 'position'}
            k = k+1;
            pos = varargin{k};
        case {'col' 'color'}
            k = k+1;
            color = varargin{k};
        case {'3x5' '8x12' '8x16'}
            fontsize = a;
        case {'topleft' 'topright' 'bottomleft' 'bottomright'}
            pos = a;
        otherwise
            error('unknown option ''%s''',a)
    end
end
doscale = iscell(elems) && length(elems)==2 && isnumeric(elems{1}) && ischar(elems{2});
if doscale
    [scalesize elems] = deal(elems{:});
end
if isempty(pos)
    pos = fn_switch('doscale','bottomleft','topleft');
end

% patterns
switch fontsize
    case '3x5'
        dolookup = true;
        characters = '0123456789.+- ';
        patterns = [
            111 010 111 111 101 111 111 111 111 111 000 010 000 000
            101 010 001 001 101 100 100 001 101 101 000 010 000 000
            101 010 111 111 111 111 111 010 111 111 000 111 111 000
            101 010 100 001 001 001 101 010 101 001 000 010 000 000
            111 010 111 111 001 111 111 010 111 111 010 010 000 000
            ];
        characters = [characters 'ABCDEFGHIJKLM'];
        patterns = [patterns [
            010 110 011 110 111 111 011 101 010 001 101 100 101
            101 101 100 101 100 100 100 101 010 001 110 100 111
            111 110 100 101 111 111 101 111 010 001 100 100 101
            101 101 100 101 100 100 101 101 010 101 110 100 101
            101 110 011 110 111 100 011 101 010 010 101 111 101
            ]];
        characters = [characters 'NOPQRSTUVWXYZ'];
        patterns = [patterns [
            101 010 110 010 110 011 111 101 101 101 101 101 111
            111 101 101 101 101 100 010 101 101 101 101 101 001
            111 101 110 101 110 010 010 101 101 101 010 010 010
            111 101 100 110 101 001 010 101 101 111 101 010 100
            101 010 100 011 101 110 010 111 010 101 101 010 111
            ]];
        characters = [characters 'abcdefghijklm'];
        patterns = [patterns [
            000 000 000 001 000 011 000 100 010 000 100 010 000 
            110 100 011 011 110 100 011 100 000 001 100 010 111 
            011 110 100 101 101 111 101 110 010 001 101 010 111 
            101 101 100 101 110 100 011 101 010 001 110 010 101 
            111 110 011 010 011 100 110 101 010 010 101 001 101 
            ]];
        characters = [characters 'nopqrstuvwxyz'];
        patterns = [patterns [
            000 000 000 000 000 000 010 000 000 000 000 000 000
            111 010 110 011 011 110 010 101 101 101 101 101 111
            101 101 101 101 100 100 011 101 101 101 010 111 010
            101 101 110 011 100 010 010 101 101 111 010 001 100
            101 010 100 001 100 110 001 111 010 101 101 001 111
            ]];

        patterns = fn_num2str(permute(patterns,[1 3 2]),'%.3i0'); % nrow x ncol x npattern
        [nrow ncol npattern] = size(patterns);  %#ok<ASGLU>
        patterns = permute(patterns,[2 1 3]); % ncol x nrow x npattern
        patterns = (patterns=='1'); % converted to logical
        patterns = squeeze(num2cell(patterns,1:2)); % convert to cell of length npattern
    case {'8x12' '8x16'}
        dolookup = false;
        a = fn_readimg(fullfile(fn_fileparts(which('fn_printnumbers'),'path'),['ascii' fontsize '.png']));
        a = logical(a);
        switch fontsize
            case '8x12'
                a = ~a;
                a = a(2:257,1:192); % remove left and bottom borders
                a = fn_reshapepermute(a,[8+8 16 12 16],[1 3 2 4],[8+8 12 256]);
                a = a(1:8,:,:); % remove extra spaces on the right
            case '8x16'
                a = a(2:289,:); % remove left border
                a = fn_reshapepermute(a,[8+1 32 16 8],[1 3 2 4],[8+1 16 256]);
        end
        [ncol nrow npattern] = size(a);  %#ok<ASGLU>
        patterns = squeeze(num2cell(a,1:2)); % convert to cell of length npattern
end

% elements to print
% (make a cell array, check size)
if iscell(elems)
    str = elems;
elseif ischar(elems)
    str = {elems};
elseif isnumeric(elems)
    nummax = max(elems);
    ndigit = floor(log10(nummax))+1;
    str = fn_num2str(elems,['%.' num2str(ndigit) 'i'],'cell');
end
N = length(str);
if isempty(im)
    s = [ncol*max(fn_itemlengths(str))+1 nrow+1 N];
    if all(color==1), im = zeros(s); else im = ones(s); end
else
    s = size(im);
    if s(1)<ncol+1 || s(2)<nrow+1, error 'image size is too small to print a single character into it', end
end
ncharavail = floor(s(1)/ncol);
% (prepare masks and handle scale bar)
mask0 = false(s(1:2));
if doscale
    % be careful, here we are considering 'bottom-left origin' positions
    w = scalesize(2);
    if ischar(pos)
        switch pos
            case 'topleft'
                pos = [1+2*w s(2)-2*w-nrow-w-scalesize(2)];
            case 'bottomleft'
                pos = [1+2*w 1+2*w];
            otherwise
                error 'position flag is not appropriate for scale bar'
        end
    end  
    mask0(pos(1)+(0:scalesize(1)-1),pos(2)+(0:scalesize(2)-1))=true; % pos considered here as 'top-left origin'
    mask0 = fliplr(mask0); % now pos is correctly interpreted as 'bottom-left' origin
    nchar = length(elems);
    pos = pos + [ceil((scalesize(1)-ncol*nchar)/2) scalesize(2)+w];
end
masks = repmat({mask0},N,1);
% (convert to mask patterns)
for k=1:N
    strk = str{k};
    strk = strrep(strk,'\mu',char(230));
    strk(ncharavail+1:end) = [];
    nchar = length(strk);
    if dolookup
        if ~all(ismember(strk,characters)), error 'i don''t know how to print some characters', end
        idx = zeros(1,nchar);
        for i=1:nchar, idx(i) = find(strk(i)==characters); end
    else
        idx = double(strk)+1;
    end
    maskk = cat(1,patterns{idx});
    if isnumeric(pos)
        % user-defined position has origin in the bottom-left corner, while
        % mask positionning has origin in the top-left corner!
        posk = [pos(1) s(2)-(pos(2)-1)-(nrow-1)];
    else
        switch pos
            case 'topleft'
                posk = [2 2];
            case 'bottomleft'
                posk = [2 s(2)-nrow];
            case 'topright'
                posk = [s(1)-ncol*nchar+1 2]; % note that the '+1' takes into account that the last column is empty (separation btw 2 characters)
            case 'bottomright'
                posk = [s(1)-ncol*nchar+1 s(2)-nrow];
            case 'center'
                % todo: to be really precise vertically, it would be
                % necessary for each character set to know at which
                % vertical position is the midline
                posk = [ceil((s(1)-ncol*nchar)/2)+1 ceil((s(2)-nrow)/2)];
            otherwise
                error 'unknown position specification'
        end
    end
    masks{k}(posk(1)+(0:ncol*nchar-1),posk(2)+(0:nrow-1)) = maskk;
end
% (make it the appropriate size)
if isscalar(str)
    masks = repmat(masks,[s(3:end) 1 1]);
elseif isvector(str)
    kdim = find(s(3:end)==N,1,'first');
    if isempty(kdim), error 'number of elements to print does not correspond to a size in any dimension', end
    rep = [s(3:end) 1];
    rep(kdim) = 1;
    masks = repmat(shiftdim(masks,1-kdim),rep);
end

% color
if all(im(:)>=0 & im(:)<=1)
    kdimcol = find(s(3:end)==3,1,'first');
else
    kdimcol = [];
end
if isempty(kdimcol) || isscalar(color)
    col = ones([s(3:end) 1 1])*color;
else
    rep = [s(3:end) 1];
    rep(kdimcol) = 1;
    col = repmat(shiftdim(color(:),1-kdimcol),rep);
end

% print!
for kframe = 1:prod(s(3:end))
    imk = im(:,:,kframe);
    imk(masks{kframe}) = col(kframe);
    im(:,:,kframe) = imk;
end


