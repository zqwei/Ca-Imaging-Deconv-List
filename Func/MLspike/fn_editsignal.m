function x = fn_editsignal(x)
% function x = fn_editsignal(x)
% function x = fn_editsignal(hl)

% Thomas Deneux
% Copyright 2015-2017


if ishandle(x)
    hl = x;
    hf = [];
    x = get(hl,'ydata');
else
    if isscalar(x), x = zeros(x,1); end
    hf = figure;
    hl = plot(x);
end

set(hl,'marker','.','buttondownfcn',@(u,e)movepoint(hl))

% control
nx = length(x);
s = struct( ...
    'smoothleft',   {true 'logical'}, ...
    'smoothright',  {true 'logical'}, ...
    'smoothing',    {1 ['logslider -1 ' num2str(ceil(log10(nx)))]} ...
    );
X = fn_control(s,'okbutton');
waitfor(X.hp)
x = get(hl,'ydata');
delete(hf)
if nargout==0, clear x, end

    function movepoint(hl)
        
        ha = get(hl,'parent');
        hf = fn_parentfigure(ha);
        p0 = get(ha,'currentpoint');
        x0 = p0(1,1);
        y0 = p0(1,2);
        xdata0 = get(hl,'xdata');
        ydata0 = get(hl,'ydata');
        [dum idx] = min(abs(xdata0-x0)); %#ok<ASGLU>

        ymov = zeros(1,nx);
        ymov(idx) = 1;
        dx1 = fn_filt(ymov,X.smoothing,2);
        dx1 = dx1/dx1(idx);
        if X.smoothleft, ymov(1:idx-1) = dx1(1:idx-1); end
        if X.smoothright, ymov(idx+1:end) = dx1(idx+1:end); end
        
        fn_buttonmotion(@move,hf)
        
        function move
            p = get(ha,'currentpoint');
            dy = p(1,2)-y0;
            ydata = ydata0 + ymov*dy;
            set(hl,'ydata',ydata)
        end
        
        
        
    end

end



    


