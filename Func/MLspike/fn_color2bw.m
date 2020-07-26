function b = fn_color2bw(a)
% function b = fn_color2bw(a)

% Thomas Deneux
% Copyright 2005-2017

% input
[nx ny ncol] = size(a);
if ncol==1, b=a; return, end
if ncol~=3, error('3rd dimension should have size 3 for RGB image'), end
m = max(a(:));
if m>65535 || min(a(:))<0, error('image should have values between 0 and 65535'), end
a = double(a);
if m>255
    a=a/65535; 
elseif m>1
    a = a/255;
end
    
% global variables
icol=1;
X = [];
b1 = [];

% figure
hf = figure;
W = 700;
HA = 450;
HB = 50;
set(hf,'pos',[300 100 W+30 HA+HB+30], ...
    'keypressfcn',@(u,e)keypress(e))

% buttons
wb = 30;
db = 5;
hb = 20;
colstr  = {'*' 'R' 'G' 'B' 'RG' 'RB' 'GB' 'RGB'};
coldata = [.8 .4 0; 1 0 0; 0 1 0; 0 0 1; .5 .5 0; .5 0 .5; 0 .5 .5; 1/3 1/3 1/3];
nbut = length(colstr);
u = zeros(1,nbut);
for i=1:nbut
    u(i) = uicontrol('style','togglebutton','string',colstr{i}, ...
        'position',[10+(i-1)*(wb+db) 5 wb hb], ...
        'callback',@(u,e)setcol(i));
end
uzoom = uicontrol('style','togglebutton','string','zoom','value',1, ...
    'position',[10+(nbut+1)*(wb+db) 5 wb+db+wb hb], ...
        'callback',@(u,e)setzoom());

% croped image
W = min(W,nx);
HA = min(HA,ny);
a2 = a(1:W,1:HA,:);

% image display
ha = axes('units','pixel','pos',[25 HB+25 W HA]);
im = imagesc(a2(:,:,1)');
set(ha,'clim',[0 1])
colormap gray

% initial display
setcol(1)

% terminate
ok = uicontrol('parent',hf,'style','togglebutton','string','ok', ...
    'position',[10+(nbut+4)*(wb+db) 5 wb hb]);
waitfor(ok,'value',1)
if ishandle(hf), close(hf), end
if ~isempty(X) && isvalid(X), close(X.hp), end
col = coldata(icol,:);
b = a(:,:,1)*col(1) + a(:,:,2)*col(2) + a(:,:,3)*col(3);



%--------------
% sub-functions
%--------------
    function setcol(i)
        set(u(icol),'value',0)
        if icol==1 && ~isempty(X) && isvalid(X), close(X.hp), end
        icol = i;
        set(u(icol),'value',1)
        if get(uzoom,'value')
            b1=a2; 
        else
            b1=a; 
        end
        if icol==1
            % special!!
            s = struct('r',coldata(1,1)*10,'g',coldata(1,2)*10);
            spec = struct('r','stepper 1 0 10 1','g','stepper 1 0 10 1');
            X = fn_control(s,@setspec,spec);
            pos0 = get(hf,'pos');
            pos  = get(X.hp,'pos');
            set(X.hp,'pos',[pos0(1)-pos(3)-5 pos0(2) pos(3:4)])
            figure(hf)
            setspec(s)
        else
            col = coldata(icol,:);
            b2 = b1(:,:,1)*col(1) + b1(:,:,2)*col(2) + b1(:,:,3)*col(3);
            set(im,'cdata',b2')
        end
    end

    function setzoom()
        if get(uzoom,'value')
            b1=a2; 
        else
            b1=a; 
        end
        [nx2 ny2 dum] = size(b1);
        set(ha,'xlim',[.5 nx2+.5],'ylim',[.5 ny2+.5])
        if icol==1
            setspec(X.s);
        else
            col = coldata(icol,:);
            b2 = b1(:,:,1)*col(1) + b1(:,:,2)*col(2) + b1(:,:,3)*col(3);
            set(im,'cdata',b2')
        end
    end

    function setspec(s)
        r = s.r/10;
        g = s.g/10;
        b = 1-r-g;
        col = [r g b];
        b2 = b1(:,:,1)*col(1) + b1(:,:,2)*col(2) + b1(:,:,3)*col(3);
        set(im,'cdata',b2')
    end

    function keypress(e)
        switch(e.Key)
            case 'leftarrow'
                setcol(1+mod(icol-2,nbut))
            case 'rightarrow'
                setcol(1+mod(icol,nbut))
            case 'space'
                set(ok,'value',1)
        end
    end
end







