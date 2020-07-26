function lisse = fn_smooth(t,sigma)
% function lisse = fn_smooth(t,sigma)
% lissage isotropique (par une gaussienne) 1D ou 2D
% - sigma   param�tre de la gaussienne

% Thomas Deneux
% Copyright 2005-2017

s = size(t);

if (length(s)>2), error('dimension>2 not handled'); end

n = ceil(4*sigma);
N = 2*n+1;

if (s(1)==1) % vecteur ligne
    g = exp(-(-n:n).^2/(2*sigma^2));
    g = g/sum(g);
    %g = fspecial('gaussian',[1 N],sigma);
    u = ones(s);
    tt = conv(t,g);
    uu = conv(u,g);
    tt = tt ./ uu;
    lisse = tt(1,(1+n):(end-n));
elseif (s(2)==1) %vecteur colonne
    g = exp(-(-n:n)'.^2/(2*sigma^2));
    g = g/sum(g);
    %g = fspecial('gaussian',[N 1],sigma);
    u = ones(s);
    tt = conv(t,g);
    uu = conv(u,g);
    tt = tt ./ uu;
    lisse = tt((1+n):(end-n));
else %matrice
    [xx yy] = ndgrid(-n:n,-n:n);
    g = exp(-(xx.^2+yy.^2)/(2*sigma^2));
    g = g/sum(g(:));
    %g = fspecial('gaussian',[N N],sigma);
    u = ones(s);
    tt = conv2(t,g);
    uu = conv2(u,g);
    tt = tt ./ uu;
    lisse = tt((1+n):(end-n),(1+n):(end-n));
end
 





    
    
    