classdef memorypoolitem < handle
    % See memorypool
    
    % Thomas Deneux
    % Copyright 2015-2017

    properties (Transient)
        data
    end
    properties
        memsize
        description
        weight
        rank
    end
    properties (Access='private', Transient)
        pool
    end
    
    % Single item manipulations
    methods 
        function item = memorypoolitem(pool,data,description,weight)
            % empty item
            if nargin==1
                item.pool = pool;
                item.data = [];
                item.memsize = [];
                item.description = '';
                item.weight = 1;
                rankpolicy(pool,'newempty',item)
                return
            end
            
            % input
            if nargin<3, description = [fn_strcat(size(data),'x') ' ' class(data)]; end
            if nargin<4, weight = 1; end
            
            % basic properties
            item.pool = pool;
            item.data = data;
            s = whos('data');
            item.memsize = s.bytes;
            item.description = description;
            item.weight = weight;
            
            % add to the pool
            pool.items(end+1) = item;
            
            % rank
            rankpolicy(pool,'new',item)
        end
        function data = get.data(item)
            data = item.data;
            rankpolicy(item.pool,'access',item)
        end
        function recover(item,data,description,weight)
            % update basic properties
            item.data = data;
            s = whos('data');
            item.memsize = s.bytes;
            if nargin>=3
                item.description = description;
            elseif isempty(item.description)
                item.description = [fn_strcat(size(data),'x') ' ' class(data)]; 
            end
            if nargin>=4, item.weight = weight; end
            
            % add to the pool
            item.pool.items(end+1) = item;
            
            % rank
            rankpolicy(item.pool,'recover',item)
        end
    end
    
    % Multiple items manipulation
    methods
        function kill(items)
            if ~isempty(items), [items.data] = deal([]); end
        end
        function zero(items)
            rankpolicy(items(1).pool,'zero')
        end
        function displayitems(items)
            n = length(items); 
            [ranks ord] = sort([items.rank]); 
            items = items(ord);
            for i=1:n
                fprintf('%.1f/%.1f - %4iMB - %s\n',ranks(i),items(i).weight,round(items(i).memsize/(2^20)),items(i).description)
            end            

        end
    end
end

function rankpolicy(pool,flag,item)

% special flags
switch flag
    case 'newempty'
        item.rank = 0;
        return
    case 'zero'
        items = pool.items;
        for i=1:length(items), items(i).rank = items(i).rank/100; end
        return
end

% adjust rank of selected item
switch flag
    case {'new' 'recover'}
        item.rank = item.weight;
    case 'access'
        item.rank = max(item.weight,item.rank+1);
        return
    otherwise
        error programming
end

% rescale ranks according to the excess in memory occupation
items = pool.items;
n = length(items);
memsizes = [items.memsize];
fact = pool.maxmem/sum(memsizes);
if fact>=1, return, end
for i=1:n
    items(i).rank = items(i).rank*fact;
end

% free memory
checkmemory(pool,item)

end

