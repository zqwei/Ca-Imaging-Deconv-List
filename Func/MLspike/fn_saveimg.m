function fn_saveimg(a,fname,varargin)
% function fn_saveimg(a,fname|'auto',[clip[,zoom[,cmap]]][,'delaytime',dt])
%---
% a should be y-x-t 
% clip can be a 2-values vector, or 'fit' [default], or '?SD', or 'none'

% Thomas Deneux
% Copyright 2004-2017

if nargin<1, help fn_saveimg, return, end
if nargin<2 || isempty(fname), fname=fn_savefile; end
if isequal(fname,0), return, end

clip = 'auto'; zoom = 1; cmap = []; delaytime = .1;
k=0;
while k<length(varargin)
    k = k+1;
    x = varargin{k};
    if ischar(x) && strcmp(x,'delaytime')
        k = k+1;
        delaytime = varargin{k};
    else
        switch k
            case 1
                clip = x;
            case 2
                zoom = x;
            case 3
                cmap = x;
            otherwise
                argument error
        end
    end
end

% image(s) size and number color/bw
[ni nj nt nt2] = size(a);
if nt2==3
    a = permute(a,[1 2 4 3]);
    ncol = 3;
elseif nt==3
    nt = nt2;
    ncol = 3;
elseif nt==1 && nt2>1
    a = permute(a,[1 2 4 3]);
    nt = nt2;
    ncol = 1;
else
    ncol = 1;
end

% file name
[fpath fbase fext] = fileparts(fname);
if isempty(fext)
    ext = 'png';
else
    ext = fext(2:end);
end
if nt>1 && ~fn_ismemberstr(ext,{'gif' 'tif' 'tiff'})
    if ~isempty(fpath), fpath = [fpath '/']; end
    fname = [fpath fbase '_'];
    lg = floor(log10(nt))+1;
    icode = ['%.' num2str(lg) 'i'];
end

% color image(s)
if ncol==3
    if zoom~=1
        error('no zoom allowed for color images')
    end
    a = permute(a,[2 1 3 4]); % (x,y) convention -> Matlab (y,x) convention
    if nt==1
        imwrite(a,fname,ext);
    elseif strcmp(ext,'gif')
        error 'true color multi-frame gif are not supported'
        imwrite(a,fname,ext,'delaytime',delaytime)
    elseif fn_ismemberstr(ext,{'tif' 'tiff'})
        fn_progress('saving image',nt)
        for i=1:nt
            fn_progress(i)
            if i==1, writemode = 'overwrite'; else writemode = 'append'; end
            try
                imwrite(a(:,:,:,i),fname,'WriteMode',writemode)
            catch
                pause(.5)
                imwrite(a(:,:,:,i),fname,'WriteMode',writemode)
            end
        end
    else
        fn_progress('saving image',nt)
        for i=1:nt
            fn_progress(i)
            name = [fname num2str(i,icode) '.' ext];
            imwrite(a(:,:,:,i),name)
        end
    end
    return
end

% otherwise

% clipping
if isequal(clip,'auto')
    switch class(a)
        case {'single' 'double'}
            clip = 'fit';
        case 'uint8'
            clip = 'none';
        otherwise
            % what would be the most intuitive choice here? i am not sure
            clip = 'fit';
    end
end
if ~isequal(clip,'none')
    a = double(a);
    a = fn_clip(a,clip);
end

% zoom parameters
if zoom~=1
    if zoom<1, disp('zoom<1 does not bin but only interpolates'), end
    if zoom>1 && mod(zoom,1)==0
        disp('integer zoom enlarges without interpolating')
        zf = true;
        ii = kron(1:ni,ones(1,zoom));
        jj = kron(1:nj,ones(1,zoom));
    else
        zf = false;
        [jj ii] = meshgrid(.5:nj-.5,.5:ni-.5);
        [jj2 ii2] = meshgrid((.5:nj*zoom-.5)/zoom,(.5:ni*zoom-.5)/zoom);
    end
end

% saving
if nt>1 && strcmp(ext,'gif')
    a = permute(a,[2 1 4 3]);
    % better convert to uint8 now, otherwise shit happens
    switch class(a)
        case {'double' 'single'}
            a = uint8(255*a);
        case 'uint8'
            % nothing to do
        case 'uint16'
            a = uint8(a/256);
        otherwise
            error('number type ''%s'' not handled for gif saving',class(a))
    end
    if zoom~=1
        if ~zf, error 'interpolated zooming not implemented for gif saving', end
        a = a(jj,ii,:,:);
    end
    if ~isempty(cmap)
        if ischar(cmap), cmap = feval(cmap,256); end
        imwrite(a,cmap,fname,ext,'delaytime',delaytime,'loopcount',inf)
    else
        imwrite(a,fname,ext,'delaytime',delaytime,'loopcount',inf)
    end
    return
end
if nt>1
    fn_progress('saving image',nt)
end
for i=1:nt
    if nt>1
        fn_progress(i)
        name = [fname num2str(i,icode) '.' ext];
    else
        name = fname;
    end
    fr = a(:,:,i)'; % (x,y) convention -> Matlab (y,x) convention
    if zoom~=1
        if zf
            fr = fr(jj,ii);
        else
            fr = interp2(jj,ii,fr,jj2,ii2,'*spline');
            fr = min(max(fr,0),.999);
        end
    end
    if ~isempty(cmap)
        if ischar(cmap), cmap = feval(cmap,256); end
        fr = floor(size(cmap,1)*fr)+1;
        fr = reshape(cat(3,cmap(fr,1),cmap(fr,2),cmap(fr,3)),nj*zoom,ni*zoom,3);
    else % gray image
        %fr = floor(length(map)*fr)+1;
    end
    imwrite(fr,name,fn_switch(ext,'eps','psc2',ext))
end

