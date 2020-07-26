classdef memorypool < handle
    % The memorypool class defines a pool of Matlab variables that is
    % limited in memory occupation.
    % If more memory is needed than available, some variable will be
    % automatically set to []. A ranking system between variables depending
    % on which ones are the most often accessed determines which ones
    % should be 'killed'.
    % Hence, the memorypool object should be used only for Matlab variables
    % that can be re-computed if needed, but for which it is valuable to
    % store to avoid multiple re-computations.
    %
    % How to use it:
    % - set the size of the pool
    %       memorypool.setmaxmem('10GB')
    % - store a variable a and get a link to where it is stored
    %       item = memorypool.item(a)
    % - it is also possible to get a link without data
    %       item = memorypool.item()
    % - access the variable
    %       a = item.data;
    %       if isempty(a) % the more a is accessed, the less this will happen
    %           a = functionThatRecomputesA();
    %           recover(item,a)
    %       end
    
    % Thomas Deneux
    % Copyright 2015-2017

    properties (Transient)
        maxmem = 2^30; % 1GB
        items = memorypoolitem.empty(1,0);
    end
    properties (Transient, Dependent)
        curload
    end
    
    % Constructor
    methods
        function pool = memorypool
            persistent poolmem
            if isempty(poolmem)
                poolmem = pool;
            else
                pool = poolmem;
            end
        end
    end
    
    methods (Static)
        function pool=getpool
            %             persistent poolmem
            %             if isempty(poolmem)
            %                 poolmem = memorypool;
            %             end
            %             pool = poolmem;
            disp 'function memorypool.getpool is deprecated, simply use memorypool instead'
            pool = memorypool;
        end
        function item = item(varargin)
            pool = memorypool;
            item = memorypoolitem(pool,varargin{:});
        end
        function setmaxmem(mem)
            pool = memorypool;
            if ischar(mem)
                token = regexpi(mem,'^((\.|\d)+)([KMGT]{0,1})B{0,1}$','tokens');
                if isempty(token), error 'input to setmaxmem must be for example ''4GB''', end
                token = token{1};
                value = str2double(token{1});
                if isnan(value) || value<=0, error 'input to setmaxmem must be for example ''4GB''', end
                unitlog = fn_switch(lower(token{2}),'',0,'k',10,'m',20,'g',30','t',40);
                pool.maxmem = value*2^unitlog;
            elseif isnumeric(mem)
                pool.maxmem = mem;
            else
                error argument
            end
            checkmemory(pool)
        end
        function clear()
            if fn_dodebug, disp('explicit kill all memorypool items'), end
            pool = memorypool;
            kill(pool.items)
            pool.items(:) = [];
        end
        function zero()
            pool = memorypool;
            zero(pool.items)
        end
        function displayitems()
            pool = memorypool;
            displayitems(pool.items)
        end
        function x = getcurload()
            pool = memorypool;
            x = pool.curload;
        end
    end
   
    methods
        function x = get.curload(pool)
            x = sum([pool.items.memsize]);
        end
        function checkmemory(pool,safeitem)
            if nargin<2, safeitem = []; end
            poolitems = [pool.items];
            if ~isempty(safeitem) % do not remove this item
                poolitems(poolitems==safeitem)=[];
                safemem = safeitem.memsize;
            else
                safemem = 0;
            end
            [ranks ord] = sort([poolitems.rank],2,'descend'); %#ok<ASGLU>
            poolitems = poolitems(ord);
            pool.items = [safeitem poolitems];
            memsizes = [poolitems.memsize];
            memcum = safemem + cumsum(memsizes);
            badidx = (memcum>pool.maxmem);
            if any(badidx)
                badidx = length(safeitem) + find(badidx);
                %if fn_dodebug, fprintf('auto kill (%s)\n',pool.items(badidx).description), end
                kill(pool.items(badidx));
                pool.items(badidx) = [];
            end
        end
    end
    
end
