function a = fn_readimg(fname,flag)
% function a = fn_readimg(fname[,'permute'])
%---
% read image using imread, and handles additional features:
% - converts to double
% - detects if color or gray-scale images (in the last case, use a 2D array per image)
% - can read a stack of images (returns 3D array)
%
% images are read according to x-y convention, use 'permute' flag to use
% Matlab y-x convention

% Thomas Deneux
% Copyright 2004-2017

% Input
if nargin<1
    fname = fn_getfile;
end
fname = cellstr(fname);
nimages = length(fname);

% first image
a = imread(fname{1}); 
if nargin<2
    a = permute(a,[2 1 3 4]); % Matlab (y,x) convention -> convention (x,y)
else
    if ~strcmp(flag,'permute'), error argument, end
end
if size(a,3)==3 && ~any(any(any(diff(a,1,3))))
    bw = true;
    a = a(:,:,1);
elseif size(a,3)==3
    bw = false;
else
    bw = true;
end

% multi-tiff?
if strfind(lower(fn_fileparts(fname{1},'ext')),'.tif')
    nframes = length(imfinfo(fname{1}));
    if nimages>1 && nframes>1, error 'cannot handle multiple tif that themselves have multiple frames', end
else
    nframes = 1;
end
        
% stack
if nimages*nframes>1
	fn_progress('reading frame',nimages*nframes)
    if bw
        a(1,1,nimages*nframes) = 0;
    else
        a(1,1,1,nimages*nframes) = 0;
    end
    for i=2:nimages*nframes
        fn_progress(i)
        if nframes>1
            b = imread(fname{1},i);
        else
            b = imread(fname{i});
        end
        if bw
            a(:,:,i) = b(:,:,1)';
        else
            a(:,:,:,i) = permute(b,[2 1 3]);
        end
    end
    fn_progress end
end

% make float-encoded color image btw 0 and 1
if ~bw
    switch class(a)
        case {'single' 'double'}
            nbyte = ceil(log2(max(a(:)))/8);
            switch nbyte
                case 1
                    a = a/255;
                case 2
                    a = a/65535;
                otherwise
                    if fn_dodebug, disp 'please help me', keyboard, end
            end
        otherwise
            %if fn_dodebug, disp 'please help me', keyboard, end
    end
end
    