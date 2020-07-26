classdef fn_movie < hgsetget
    % function fn_movie(data,option1,value1,...)
    % function fn_movie(data,optstruct)
    %---
    % available options are
    % - temporal manipulations:
    %       tnorm       normalize by average M.fr (overlays with normal M.fr)
    %       tspec       normalize by a local average (using frames t-tspec:t+tspec)
    %       tbin        binning
    % - spatial manipulations:
    %       xhigh       sigma for high-pass
    %       xlow        sigma for low-pass
    %       xbin        binning
    % - colors (M.fr denotes the M.fr at the instant an option is cM.hanged)
    %       brightness  bias in the center of clipping range ((max(M.fr)-min(M.fr))*brightness)
    %       contrast    amplitude of clipping range ((max(M.fr)-min(M.fr))/contrast)
    %       clip        directly define the clipping range
    %       cmap        choose colormap
    %       overlay     overlay computed frames on top of the average M.fr in
    %                   grayscale
    % - movie playing
    %       start       M.fr from which to start playing
    %       end         M.fr until which to play
    %       speed       number of frames per second
    % 
    % See also fn_playmovie

% Thomas Deneux
% Copyright 2008-2017

    properties
        opt
        pars
        Y
        nx
        ny
        nt
        k
        fr
        frame
        htext
        hu
    end
    properties (Access='private')
        hf 
        ha
        hp
        im
    end
    
    % Constructor
    methods
        function M = fn_movie(Y,varargin)
            if nargin==0, help fn_movie, return, end
            if ischar(Y) && strcmp(Y,'demo')
                % load an example dataset
                load(fullfile(fileparts(which('fn_movie')),'data','fn_movie_demo'))
            end
            
            M.Y = Y;
            [M.nx M.ny M.nt] = size(M.Y);
            
            % basic characteristics of the data
            avgfr = mean(M.Y,3);
            overlay = repmat((avgfr'-min(avgfr(:)))/(max(avgfr(:))-min(avgfr(:))),[1 1 3]);
            minmax = [min(avgfr(:)) max(avgfr(:))];

            % display parameters
            startopt = struct( ...
                'tnorm',    false, ...
                'tspec',    [], ...
                'tbin',     [], ...
                'xhigh',    [], ...
                'xlow',     [], ...
                'xbin',     [], ...
                'clip',     minmax, ...
                'cmap',     'gray', ...
                'overlay',  [], ...
                'speed',    [] ...
                );
            if ~isempty(varargin)
                startopt = fn_structmerge(startopt,struct(varargin{:}),'strict');
            end
            
            spec = struct( ...
                'tnorm',    'logical', ...
                'tspec',    'xslider 1 8 1', ...
                'tbin',     'xslider 1 10 1', ...
                'xhigh',    'xlogslider 0 3', ...
                'xlow',     'xlogslider -1 3', ...
                'xbin',     'xslider 1 10 1', ...
                'clip',     'clip', ...
                'cmap',     {{'gray','jet','mapgeog','hot','mapclip','mapcliphigh','signcheck','green','user'}}, ...
                'overlay',  'xslider 0 1', ...
                'speed',    'xlogslider 0 2 %.0f [1]' ...
                );

            % additional parameters (precomputations)
            M.pars = struct( ...
                'step',         1, ...
                'avgfr',        avgfr, ...
                'overlay',      overlay, ...
                'globavg',      mean(avgfr(:)), ...
                'minmax',       minmax, ...
                'clipmode',     startopt.tnorm, ...  0 = data mode, 1 = normalized mode
                'clipalt',      [-.05 .05], ...  storing of values for the non-current mode
                'clipmin',      startopt.clip(1), ...
                'cliprange',    diff(startopt.clip), ...
                'cmap',         gray(256), ...
                'fps',          15 ...
                );
            
            % graphic objects - note that the image display is seen by
            % fn_imvalue
            M.hf = figure(795);
            set(M.hf,'tag','fn_movie') % prevent access to fn_imvalue
            figure(M.hf), clf
            set(795,'numbertitle','off','name','MOVIE', ...
                'position',[340 340 580 400], ...
                'menubar','none') 
            M.hp = uipanel('parent',M.hf,'position',[.02 .015 .36 .96], ...
                'defaultuicontrolfontsize',8);
            set(M.hp,'units','pixel') % size will not cM.hange if figure is resized
            M.hu = fn_slider('parent',M.hf,'mode','area+point', ...
                'units','normalized','position',[.42 .015 .56 .05], ...
                'min',1,'max',M.nt,'value',[1 M.nt],'point',1,'inc',1/(M.nt-1), ...
                'callback',@(u,evnt)slidercallback(M));
            M.htext = uicontrol('parent',M.hf,'style','text','fontsize',8, ...
                'units','normalized','position',[.42 .065 .1 .03]);
            M.ha = axes('parent',M.hf,'position',[.42 .096 .56 .884]);
            
            % menus
            uimenu(M.hf,'label','save','callback',@(u,evnt)savemovie(M))

            % parameters control
            M.opt = fn_control(startopt,@(s)chgoptions(M,s),spec,M.hp);

            % image (variable M.fr and M.frame are set in fuctions getframe and color
            M.k = 1;
            M.fr = []; M.frame = [];
            getframe(M);
            color(M);
            M.im = image(M.frame,'parent',M.ha);
            chgoptions(M,M.opt)
            set(M.ha,'xtick',[],'ytick',[])
            axis(M.ha,'image')

            % play movie
            playmovie(M)
        end
    end
    
    % Routines
    methods
        function playmovie(M)
            while ishandle(M.hf) && M.pars.step
                tic
                % display current frame
                set(M.im,'cdata',M.frame)
                set(M.hu,'point',M.k)
                set(M.htext,'string',num2str(M.k))
                drawnow
                if ~ishandle(M.hf), return, end
                % prepare next frame
                M.k = M.k+M.pars.step;
                getframe(M);
                color(M);
                % wait according to speed
                pause(1/M.pars.fps-toc)
            end
        end
            
        % get a movie frame + process it
        function getframe(M)
            M.k = round(M.k); % who knows...
            % temporal operations
            loop = round(M.hu.value);
            if ~isempty(M.opt.tbin) && M.opt.tbin>1
                M.k = loop(1)+mod(M.k-loop(1),loop(2)-loop(1)+1-(M.opt.tbin-1));
                M.fr = mean(M.Y(:,:,M.k:M.k+M.opt.tbin-1),3);
            else
                M.k = loop(1)+mod(M.k-loop(1),loop(2)-loop(1)+1);
                M.fr = M.Y(:,:,M.k);
            end
            M.fr = double(M.fr);
            if ~isempty(M.opt.tspec)
                idx = max(1,M.k-M.opt.tspec):min(M.nt,M.k+M.opt.tspec);
                block = M.Y(:,:,idx);
                M.fr = M.fr ./ mean(block,3) - 1;
            elseif M.opt.tnorm
                M.fr = M.fr./M.pars.avgfr - 1;
            end
            % spatial operations
            if ~isempty(M.opt.xhigh) && ~isempty(M.opt.xlow)
                M.fr = fn_filt(M.fr,[M.opt.xlow M.opt.xhigh],'bzm',[1 2]); % keep mean
            elseif ~isempty(M.opt.xhigh)
                M.fr = fn_filt(M.fr,M.opt.xhigh,'hzm',[1 2]); % keep mean
            elseif ~isempty(M.opt.xlow)
                M.fr = fn_filt(M.fr,M.opt.xlow,'lm',[1 2]);
            end
            if ~isempty(M.opt.xbin) && M.opt.xbin>1
                M.fr = fn_bin(M.fr,M.opt.xbin,'same');
            end
            % clipping
            M.fr = (M.fr-M.pars.clipmin)/M.pars.cliprange;
        end
        
        % transpose and apply color map
        function color(M)
            if strcmp(M.opt.cmap,'gray')
                % no need to interpolate a color map -> direct calculation
                tmp = max(0,min(1,M.fr'));
                M.frame = repmat(tmp,[1 1 3]);
            else
                tmp = max(1e-3,min(1,M.fr'));
                tmp = ceil(tmp*256);
                M.frame = reshape(M.pars.cmap(tmp(:),:),[M.ny M.nx 3]);
            end
            if ~isempty(M.opt.overlay)
                %M.frame = M.opt.overlay*M.frame + (1-M.opt.overlay)*M.pars.overlay;
                if ~isempty(M.opt.tbin) && M.opt.tbin>1
                    y = mean(M.Y(:,:,M.k+(0:M.opt.tbin-1)),3);
                else
                    y = double(M.Y(:,:,M.k));
                end
                y = (y'-min(M.pars.avgfr(:))) / (max(M.pars.avgfr(:))-min(M.pars.avgfr(:)));
                y = repmat(max(0,min(1,y)),[1 1 3]);
                M.frame = M.opt.overlay*M.frame + (1-M.opt.overlay)*y;
            end
        end

        % update clipping parameters upon change in options
        function chgoptions(M,s) %#ok<INUSD>
            p = M.pars;
            F = M.opt.changedfields;
            if ~isempty(M.opt.tspec) && M.opt.tnorm
                % tnorm and tstep are exclusive
                if any(fn_ismemberstr(F,{'tspec'}))
                    M.opt.tnorm = false;
                else
                    M.opt.tspec = [];
                end
            end
            moviestopped = ~p.step;
            % switch between data / normalized
            b = M.opt.tnorm || ~isempty(M.opt.tspec);
            if b~=p.clipmode
                p.clipmode = b;
                tmp = [M.opt.clip];
                M.opt.clip = p.clipalt;
                p.clipalt = tmp;
            end
            % clipping 
            p.clipmin   = M.opt.clip(1);
            p.cliprange = diff(M.opt.clip);
            % colormap
            if isempty(F) || any(fn_ismemberstr(F,{'cmap'}))
                if strcmp(M.opt.cmap,'user')
                    ok = false; 
                    while ~ok
                        answer = inputdlg({'color map:'},'',1,{'jet(256)'});
                        try %#ok<TRYNC>
                            p.cmap = eval(answer{1});
                            ok = true;
                        end
                    end
                else
                    p.cmap = feval(M.opt.cmap,256);
                end
            end
            % speed
            if isempty(M.opt.speed)
                p.step = 0;
            elseif ~isempty(M.opt.tbin)
                p.step = M.opt.tbin;
                p.fps = M.opt.speed;
            else
                p.step = 1;
                p.fps = M.opt.speed;
            end
            % update display
            M.pars = p;
            getframe(M);
            color(M);
            set(M.im,'cdata',M.frame), drawnow
            % re-start movie 
            if moviestopped
                playmovie(M)
            end
        end
        
        % slider callback
        function slidercallback(M)
            M.k = M.hu.point;
            getframe(M);
            color(M);
            set(M.im,'cdata',M.frame)
            set(M.hu,'point',M.k)
            set(M.htext,'string',num2str(M.k))
            drawnow
        end

        % save movie
        function savemovie(M)
            fname = fn_savefile('*.avi','Select avi file to save movie');
            if ~fname, return, end
            pixelsize = fn_input('pixelsize',1,1,10);
            if isempty(pixelsize), return, end
            pixelsize = pixelsize*[1 1];
            set(M.hf,'pointer','watch')
            disp('compute frames')
            if isempty(M.opt.tbin)
                step = 1;
            else
                step = M.opt.tbin;
            end
            loop = M.hu.value;
            nt2 = length(loop(1):step:loop(2));
            if isempty(M.opt.xbin)
                nx2 = M.nx;
                ny2 = M.ny;
            else
                nx2 = M.nx/M.opt.xbin;
                ny2 = M.ny/M.opt.xbin;
            end
            mov = struct('cdata',cell(1,nt2),'colormap',cell(1,nt2));
            for i=1:nt2
                M.k = loop(1)+step*(i-1);
                getframe(M)
                color(M)
                if pixelsize>1
                    tmp = reshape(M.frame,[1 ny2 1 nx2 3]);
                    tmp = repmat(tmp,[pixelsize(1) 1 pixelsize(2) 1 1]);
                    tmp = reshape(tmp,[ny2*pixelsize(1) nx2*pixelsize(2) 3]);
                else
                    tmp = M.frame;
                end
                mov(i).cdata = uint8(tmp*256);
            end
            disp('save avi')
            movie2avi(mov,fname,'fps',M.pars.fps); %,'compression','i420');
            set(M.hf,'pointer','arrow')
        end
    end

end
