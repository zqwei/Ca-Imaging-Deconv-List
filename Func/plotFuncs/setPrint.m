function setPrint(width, height, fname, printType)

%     h1 = suptitle(fname(9:end));
%     set(h1, 'Interpreter','none','fontsize',4)

    if nargin == 3
        % printType = 'svg';
        printType = 'eps';
    end
    set(gcf, 'renderer', 'painters', 'renderermode', 'manual');
    set(gcf,'PaperUnits','centimeters');
    set(gcf,'PaperSize',[width height]);
    set(gcf,'PaperPosition',[0 0 width height]);
    box off;
    
    switch upper(printType)
        case 'EPS'
            print('-depsc',[fname '.eps'])
        case 'PNG'
            print('-dpng',[fname '.png'])
        case 'PDF'
            print('-dpdf',[fname '.pdf'])
        case {'TIF', 'TIFF'}
            print('-dtiff','-r300',[fname '.tif'])
        case {'SVG'}
            print('-dsvg',[fname '.svg'])            
    end
    
    
    